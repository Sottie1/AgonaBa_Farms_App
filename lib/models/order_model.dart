import 'package:cloud_firestore/cloud_firestore.dart';

class FarmOrder {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String status;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
  });

  factory FarmOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FarmOrder(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'],
      status: data['status'] ?? 'pending',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      shippingAddress: data['shippingAddress'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'status': status,
      'items': items,
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}