import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<FarmProduct>> getProducts({
    String? farmerId, // Added farmer filter
    String? category,
    String? subCategory,
    String? searchQuery,
    String sortBy = 'name',
    bool ascending = true,
  }) {
    Query query = _firestore.collection('products');

    // Filter by farmer if provided
    if (farmerId != null) {
      query = query.where('farmerId', isEqualTo: farmerId);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (subCategory != null && subCategory != 'All') {
      query = query.where('subCategory', isEqualTo: subCategory);
    }

    // Note: We'll handle search filtering on the client side for better results
    query = query.orderBy(sortBy, descending: !ascending);

    return query.snapshots().map((snapshot) {
      List<FarmProduct> products =
          snapshot.docs.map((doc) => FarmProduct.fromFirestore(doc)).toList();

      // Apply search filter on client side for better results
      if (searchQuery != null && searchQuery.isNotEmpty) {
        print(
            'Filtering products with search query: $searchQuery'); // Debug print
        products = products.where((product) {
          final query = searchQuery.toLowerCase();
          final matches = product.name.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query) ||
              product.subCategory.toLowerCase().contains(query);
          if (matches) {
            print(
                'Product "${product.name}" matches search query'); // Debug print
          }
          return matches;
        }).toList();
        print(
            'Found ${products.length} products matching search query'); // Debug print
      }

      return products;
    });
  }

  Future<void> addProduct(FarmProduct product) async {
    // First get farmer details
    final farmerDoc =
        await _firestore.collection('farmers').doc(product.farmerId).get();
    final farmerData = farmerDoc.data() as Map<String, dynamic>;

    // Add product with farmer info
    await _firestore.collection('products').add({
      ...product.toFirestore(),
      'farmerName': farmerData['farmName'] ?? 'Unknown Farm',
    });
  }

  Future<void> updateProduct(String id, FarmProduct product) async {
    await _firestore
        .collection('products')
        .doc(id)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  // Get products by farmer ID
  Stream<List<FarmProduct>> getProductsByFarmer(String farmerId) {
    return _firestore
        .collection('products')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FarmProduct.fromFirestore(doc))
          .toList();
    });
  }

  // Get single product by ID
  Future<FarmProduct?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    return doc.exists ? FarmProduct.fromFirestore(doc) : null;
  }
}
