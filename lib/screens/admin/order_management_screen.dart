import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _search = '';
  String _statusFilter = 'All';
  final List<String> _statuses = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by order number or customer',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (val) =>
                        setState(() => _search = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _statusFilter = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }
                final orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final orderNumber =
                      (data['orderNumber'] ?? '').toString().toLowerCase();
                  final customer =
                      (data['customerName'] ?? '').toString().toLowerCase();
                  final status =
                      (data['status'] ?? 'Pending').toString().toLowerCase();
                  final matchesSearch = _search.isEmpty ||
                      orderNumber.contains(_search) ||
                      customer.contains(_search);
                  final matchesStatus = _statusFilter == 'All' ||
                      status == _statusFilter.toLowerCase();
                  return matchesSearch && matchesStatus;
                }).toList();
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child:
                            Icon(Icons.receipt_long, color: Colors.green[900]),
                      ),
                      title: Text('Order #${data['orderNumber'] ?? ''}'),
                      subtitle: Text(
                          'Customer: ${data['customerName'] ?? ''}\nTotal: ₵${(data['totalAmount'] ?? 0).toStringAsFixed(2)}\nStatus: ${data['status'] ?? 'Pending'}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => _showStatusDialog(doc, data),
                        tooltip: 'Update Status',
                      ),
                      onTap: () => _showOrderDetails(context, data),
                      dense: false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(
      QueryDocumentSnapshot doc, Map<String, dynamic> data) async {
    String newStatus = _capitalize(data['status'] ?? 'Pending');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: DropdownButton<String>(
          value: newStatus,
          items: _statuses
              .where((s) => s != 'All')
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => setState(() => newStatus = val!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(doc.id)
                  .update({'status': newStatus});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order status updated')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${data['orderNumber'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${data['customerName'] ?? ''}'),
              Text('Email: ${data['customerEmail'] ?? ''}'),
              Text('Phone: ${data['customerPhone'] ?? ''}'),
              Text('Status: ${data['status'] ?? 'Pending'}'),
              Text('Total: ₵${(data['totalAmount'] ?? 0).toStringAsFixed(2)}'),
              Text('Payment: ${data['paymentMethod'] ?? ''}'),
              Text('Shipping: ${data['shippingAddress'] ?? ''}'),
              if (data['createdAt'] != null)
                Text(
                    'Date: ${DateFormat('yyyy-MM-dd – kk:mm').format((data['createdAt'] as Timestamp).toDate())}'),
              const SizedBox(height: 12),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...((data['items'] ?? []) as List).map(
                  (item) => Text('- ${item['name']} x${item['quantity']}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
