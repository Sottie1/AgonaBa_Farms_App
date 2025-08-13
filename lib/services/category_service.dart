import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categories';

  // Get all categories
  static Stream<List<Category>> getCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  // Get category by ID
  static Future<Category?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Create new category
  static Future<String> createCategory(Category category) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(category.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update existing category
  static Future<void> updateCategory(
      String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  static Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Check if category name already exists
  static Future<bool> categoryNameExists(String name,
      {String? excludeId}) async {
    try {
      Query query =
          _firestore.collection(_collection).where('name', isEqualTo: name);

      if (excludeId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check category name: $e');
    }
  }

  // Get categories count
  static Stream<int> getCategoriesCount() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Search categories by name
  static Stream<List<Category>> searchCategories(String searchTerm) {
    if (searchTerm.isEmpty) {
      return getCategories();
    }

    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThan: searchTerm + '\uf8ff')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }
}
