import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  // Fetch all orders
  final ordersSnapshot = await firestore.collection('orders').get();

  for (final orderDoc in ordersSnapshot.docs) {
    final order = orderDoc.data();
    // Skip if already has farmerId or no items
    if (order.containsKey('farmerId') || order['items'] == null || (order['items'] as List).isEmpty) {
      continue;
    }

    // Get the first productId from the order's items
    final firstItem = (order['items'] as List).first as Map<String, dynamic>;
    final productId = firstItem['productId'];
    if (productId == null) continue;

    // Fetch the product to get farmerId and farmerName
    final productDoc = await firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) continue;
    final product = productDoc.data()!;
    final farmerId = product['farmerId'];
    final farmerName = product['farmerName'] ?? '';

    if (farmerId != null) {
      await orderDoc.reference.update({
        'farmerId': farmerId,
        'farmerName': farmerName,
      });
      print('Updated order ${orderDoc.id} with farmerId $farmerId');
    }
  }

  print('Backfill complete!');
}