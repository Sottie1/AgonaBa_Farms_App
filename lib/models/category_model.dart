import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.imageUrl,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };
  }
}
