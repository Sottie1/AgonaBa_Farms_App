import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/cart_item.dart';
import 'package:farming_management/models/order_model.dart';
import 'package:farming_management/models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farming_management/auth/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  double get _subtotal => widget.cartItems
      .fold(0, (sum, item) => sum + item.product.pricePerUnit * item.quantity);
  double get _discount => widget.cartItems.fold(0, (sum, item) {
        if (item.product.discount != null && item.product.discount! > 0) {
          return sum +
              (item.product.pricePerUnit *
                  item.product.discount! *
                  item.quantity);
        }
        return sum;
      });
  double get _total => _subtotal - _discount;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.cartItems.map((item) => ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(
                      '₵${item.product.pricePerUnit.toStringAsFixed(2)} x ${item.quantity}'),
                  trailing: Text(
                      '₵${(item.product.pricePerUnit * item.quantity).toStringAsFixed(2)}'),
                )),
            const Divider(),
            _summaryRow('Subtotal', '₵${_subtotal.toStringAsFixed(2)}'),
            _summaryRow('Discount', '-₵${_discount.toStringAsFixed(2)}'),
            _summaryRow('Total', '₵${_total.toStringAsFixed(2)}',
                isTotal: true),
            const SizedBox(height: 24),
            const Text('Shipping Address',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your shipping address',
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              items: const [
                DropdownMenuItem(
                    value: 'Cash on Delivery', child: Text('Cash on Delivery')),
                DropdownMenuItem(
                    value: 'Mobile Money', child: Text('Mobile Money')),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Place Order',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? Colors.green : null)),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a shipping address')));
      return;
    }
    setState(() => _isPlacingOrder = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Fetch customer phone number from Firestore
      final appUser = await AuthService().getCurrentUser();
      final customerPhone = appUser?.phone ?? '';

      // Group cart items by farmerId
      final itemsByFarmer = <String, List<CartItem>>{};
      for (final item in widget.cartItems) {
        itemsByFarmer.putIfAbsent(item.product.farmerId, () => []).add(item);
      }

      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerName = entry.value.first.product.farmerName;
        final items = entry.value;

        // Generate a unique order number for each farmer's order
        final now = DateTime.now();
        final orderNumber =
            'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}${farmerId.substring(0, 4)}';

        final orderData = {
          'orderNumber': orderNumber,
          'customerId': user.uid,
          'customerName': user.displayName ?? '',
          'customerEmail': user.email ?? '',
          'customerPhone': customerPhone,
          'status': 'pending',
          'items': items
              .map((item) => {
                    'productId': item.product.id,
                    'name': item.product.name,
                    'price': item.product.pricePerUnit,
                    'quantity': item.quantity,
                    'imageUrl': item.product.imageUrl,
                    'unit': item.product.unit,
                  })
              .toList(),
          'totalAmount': items.fold(0.0,
              (sum, item) => sum + item.product.pricePerUnit * item.quantity),
          'shippingAddress': _addressController.text.trim(),
          'paymentMethod': _paymentMethod,
          'createdAt': FieldValue.serverTimestamp(),
          'farmerId': farmerId,
          'farmerName': farmerName,
        };

        final orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .add(orderData);

        // Create notification for the farmer
        await _createFarmerNotification(
          farmerId: farmerId,
          orderNumber: orderNumber,
          customerName: user.displayName ?? 'Customer',
          totalAmount: items.fold(0.0,
              (sum, item) => sum + item.product.pricePerUnit * item.quantity),
          orderId: orderDoc.id,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order(s) placed successfully!')));
      Navigator.pop(context, true); // Indicate success to clear cart
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error placing order: $e')));
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _createFarmerNotification({
    required String farmerId,
    required String orderNumber,
    required String customerName,
    required double totalAmount,
    required String orderId,
  }) async {
    try {
      final notificationData = {
        'userId': farmerId,
        'title': 'New Order Received!',
        'body':
            'Order #$orderNumber from $customerName for ₵${totalAmount.toStringAsFixed(2)}',
        'type': 'new_order',
        'data': {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerName': customerName,
          'totalAmount': totalAmount,
        },
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);
    } catch (e) {
      // Don't fail the order if notification creation fails
      debugPrint('Error creating notification: $e');
    }
  }
}
