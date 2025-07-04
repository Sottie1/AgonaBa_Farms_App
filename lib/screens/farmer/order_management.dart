import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/auth/auth_service.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  _OrdersManagementScreenState createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedStatus = 'All';
  final currencyFormat = NumberFormat.currency(symbol: '₵', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          const SizedBox(height: 8),
          _buildOrderStats(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      {'name': 'All', 'color': Colors.grey},
      {'name': 'Pending', 'color': Colors.orange},
      {'name': 'Processing', 'color': Colors.blue},
      {'name': 'Shipped', 'color': Colors.purple},
      {'name': 'Delivered', 'color': Colors.green},
      {'name': 'Cancelled', 'color': Colors.red},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status['name'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                status['name'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status['name'] as String;
                });
              },
              selectedColor: status['color'] as Color,
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color:
                      isSelected ? status['color'] as Color : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderStats() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('farmerId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final orders = snapshot.data!.docs
            .map((doc) => FarmOrder.fromFirestore(doc))
            .toList();

        final pendingCount = orders.where((o) => o.status == 'pending').length;
        final processingCount =
            orders.where((o) => o.status == 'processing').length;
        final totalRevenue = orders
            .where((o) => o.status == 'delivered')
            .fold(0.0, (sum, order) => sum + order.totalAmount);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '$pendingCount',
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Processing',
                  '$processingCount',
                  Colors.blue,
                  Icons.settings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  currencyFormat.format(totalRevenue),
                  Colors.green,
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildOrdersQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedStatus.toLowerCase()} orders found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Orders will appear here when customers place them',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var order = FarmOrder.fromFirestore(doc);
            return _buildOrderCard(order, doc.id);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(FarmOrder order, String docId) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final itemCount =
        order.items.fold(0, (sum, item) => sum + (item['quantity'] as int));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order, docId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Order #${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.customerName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '$itemCount items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (order.status == 'pending' || order.status == 'processing')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _updateOrderStatus(docId, 'processing'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Process'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(docId, 'shipped'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Ship'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String docId, String newStatus) async {
    try {
      // Get the order data first
      final orderDoc = await _firestore.collection('orders').doc(docId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final customerId = orderData['customerId'] as String;
      final orderNumber = orderData['orderNumber'] as String;
      final customerName = orderData['customerName'] as String;

      // Update order status
      await _firestore.collection('orders').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for customer
      await _createCustomerNotification(
        customerId: customerId,
        orderNumber: orderNumber,
        customerName: customerName,
        newStatus: newStatus,
        orderId: docId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showOrderDetails(FarmOrder order, String docId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(order, docId),
    );
  }

  Widget _buildOrderDetailsSheet(FarmOrder order, String docId) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(order.status),
                                size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Order Info
                  _buildDetailSection(
                    'Order Information',
                    [
                      _buildDetailRow('Order Number', '#${order.orderNumber}'),
                      _buildDetailRow(
                          'Date',
                          DateFormat('MMM dd, yyyy HH:mm')
                              .format(order.createdAt)),
                      _buildDetailRow('Payment Method', order.paymentMethod),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Customer Info
                  _buildDetailSection(
                    'Customer Information',
                    [
                      _buildDetailRow('Name', order.customerName),
                      _buildDetailRow('Email', order.customerEmail),
                      if (order.customerPhone != null)
                        _buildDetailRow('Phone', order.customerPhone!),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Shipping Address
                  _buildDetailSection(
                    'Shipping Address',
                    [
                      _buildDetailRow('Address', order.shippingAddress),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Order Items
                  _buildDetailSection(
                    'Order Items',
                    order.items
                        .map((item) => _buildDetailRow(
                              '${item['quantity']}x ${item['name']}',
                              currencyFormat
                                  .format((item['price'] as num).toDouble()),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  if (order.status == 'pending' || order.status == 'processing')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateOrderStatus(docId, 'processing');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Mark as Processing'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateOrderStatus(docId, 'shipped');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Mark as Shipped'),
                          ),
                        ),
                      ],
                    ),

                  if (order.status == 'shipped')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(docId, 'delivered');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Mark as Delivered'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Query _buildOrdersQuery() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    Query query = _firestore
        .collection('orders')
        .where('farmerId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true);

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus.toLowerCase());
    }

    return query;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  Future<void> _createCustomerNotification({
    required String customerId,
    required String orderNumber,
    required String customerName,
    required String newStatus,
    required String orderId,
  }) async {
    try {
      String title;
      String body;
      String type;

      switch (newStatus.toLowerCase()) {
        case 'processing':
          title = 'Order Processing Started!';
          body =
              'Your order #$orderNumber is now being processed. We\'ll keep you updated on the progress.';
          type = 'order_status';
          break;
        case 'shipped':
          title = 'Order Shipped!';
          body =
              'Great news! Your order #$orderNumber has been shipped and is on its way to you.';
          type = 'order_status';
          break;
        case 'delivered':
          title = 'Order Delivered!';
          body =
              'Your order #$orderNumber has been successfully delivered. Enjoy your fresh farm products!';
          type = 'order_status';
          break;
        case 'cancelled':
          title = 'Order Cancelled';
          body =
              'Your order #$orderNumber has been cancelled. Please contact us if you have any questions.';
          type = 'order_status';
          break;
        default:
          title = 'Order Status Updated';
          body =
              'Your order #$orderNumber status has been updated to ${newStatus.toUpperCase()}.';
          type = 'order_status';
      }

      final notificationData = {
        'userId': customerId,
        'title': title,
        'body': body,
        'type': type,
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'status': newStatus,
          'customerName': customerName,
        },
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notificationData);
      debugPrint('Customer notification created for order: $orderNumber');
    } catch (e) {
      debugPrint('Error creating customer notification: $e');
    }
  }
}
