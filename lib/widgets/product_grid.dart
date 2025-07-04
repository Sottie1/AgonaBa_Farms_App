// // widgets/products_grid.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:farming_management/models/category_model.dart';
// import 'package:farming_management/models/product_model.dart';

// class ProductsGrid extends StatefulWidget {
//   final String? categoryId;
//   final bool showCategoryHeader;
//   final bool showAppBar;

//   const ProductsGrid({
//     this.categoryId,
//     this.showCategoryHeader = true,
//     this.showAppBar = false,
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<ProductsGrid> createState() => _ProductsGridState();
// }

// class _ProductsGridState extends State<ProductsGrid> {
//   final ScrollController _scrollController = ScrollController();
//   String _searchQuery = '';
//   bool _isLoadingMore = false;

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         if (widget.showAppBar) _buildAppBar(),
//         if (widget.showCategoryHeader && widget.categoryId != null)
//           _buildCategoryHeader(),
//         _buildSearchField(),
//         Expanded(
//           child: _buildProductsList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildAppBar() {
//     return AppBar(
//       title: Text(_searchQuery.isEmpty ? 'Products' : 'Search: $_searchQuery'),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.filter_alt),
//           onPressed: _showFilterDialog,
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryHeader() {
//     return FutureBuilder<DocumentSnapshot>(
//       future: FirebaseFirestore.instance
//           .collection('categories')
//           .doc(widget.categoryId)
//           .get(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) return const SizedBox();
        
//         final category = Category.fromFirestore(snapshot.data!);
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 24,
//                 backgroundImage: CachedNetworkImageProvider(category.imageUrl),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 category.name,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSearchField() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: TextField(
//         decoration: InputDecoration(
//           hintText: 'Search products...',
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
//       ),
//     );
//   }

//   Widget _buildProductsList() {
//     Query productsQuery = FirebaseFirestore.instance
//         .collection('products')
//         .where('available', isEqualTo: true)
//         .orderBy('name');

//     if (widget.categoryId != null) {
//       productsQuery = productsQuery.where('category', isEqualTo: widget.categoryId);
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: productsQuery.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return _buildErrorWidget('Failed to load products');
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingWidget();
//         }

//         if (snapshot.data!.docs.isEmpty) {
//           return _buildEmptyWidget();
//         }

//         // Filter products by search query
//         final products = snapshot.data!.docs
//             .map((doc) => Product.fromFirestore(doc))
//             .where((product) =>
//                 product.name.toLowerCase().contains(_searchQuery) ||
//                 product.description.toLowerCase().contains(_searchQuery))
//             .toList();

//         if (products.isEmpty) {
//           return _buildEmptySearchWidget();
//         }

//         return NotificationListener<ScrollNotification>(
//           onNotification: (scrollNotification) {
//             if (scrollNotification.metrics.pixels ==
//                 scrollNotification.metrics.maxScrollExtent) {
//               _loadMoreProducts();
//             }
//             return false;
//           },
//           child: GridView.builder(
//             controller: _scrollController,
//             padding: const EdgeInsets.all(8),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.8,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: products.length + (_isLoadingMore ? 1 : 0),
//             itemBuilder: (context, index) {
//               if (index >= products.length) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               return ProductCard(product: products[index]);
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 48, color: Colors.red),
//           const SizedBox(height: 16),
//           Text(message),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () => setState(() {}),
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingWidget() {
//     return GridView.builder(
//       padding: const EdgeInsets.all(8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: 6, // Number of shimmer items
//       itemBuilder: (context, index) {
//         return const ShimmerProductCard();
//       },
//     );
//   }

//   Widget _buildEmptyWidget() {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
//           SizedBox(height: 16),
//           Text('No products available'),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptySearchWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.search_off, size: 48, color: Colors.grey),
//           const SizedBox(height: 16),
//           Text('No results for "$_searchQuery"'),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () => setState(() => _searchQuery = ''),
//             child: const Text('Clear search'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _loadMoreProducts() async {
//     if (_isLoadingMore) return;
    
//     setState(() => _isLoadingMore = true);
//     // Implement pagination logic here
//     await Future.delayed(const Duration(seconds: 1)); // Simulate network call
//     setState(() => _isLoadingMore = false);
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Filter Products'),
//           content: const Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Add filter options here (price range, sort by, etc.)
//               Text('Filter options coming soon!'),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('CLOSE'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class ProductCard extends StatelessWidget {
//   final Product product;

//   const ProductCard({required this.product, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () => _navigateToProductDetail(context),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Product Image
//             _buildProductImage(),
            
//             // Product Details
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Name
//                   Text(
//                     product.name,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
                  
//                   // Product Price
//                   Text(
//                     '\$${product.price.toStringAsFixed(2)}',
//                     style: TextStyle(
//                       color: Colors.green[700],
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
                  
//                   // Product Category (if available)
//                   if (product.categoryName != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: Text(
//                         product.categoryName!,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
                  
//                   // Add to Cart Button
//                   const SizedBox(height: 8),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => _addToCart(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                       ),
//                       child: const Text(
//                         'Add to Cart',
//                         style: TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProductImage() {
//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//       child: SizedBox(
//         height: 120,
//         width: double.infinity,
//         child: Stack(
//           children: [
//             CachedNetworkImage(
//               imageUrl: product.imageUrl,
//               fit: BoxFit.cover,
//               width: double.infinity,
//               placeholder: (context, url) => Container(color: Colors.grey[200]),
//               errorWidget: (context, url, error) => Container(
//                 color: Colors.grey[200],
//                 child: const Icon(Icons.image_not_supported),
//               ),
//             ),
            
//             // Sale badge (if on sale)
//             if (product.isOnSale)
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Text(
//                     'SALE',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _navigateToProductDetail(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ProductDetailScreen(product: product),
//       ),
//     );
//   }

//   void _addToCart(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Added ${product.name} to cart'),
//         duration: const Duration(seconds: 1),
//       ),
//     );
//     // Implement actual cart logic here
//   }
// }

// class ShimmerProductCard extends StatelessWidget {
//   const ShimmerProductCard({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             height: 120,
//             width: double.infinity,
//             color: Colors.grey[200],
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   height: 16,
//                   width: 100,
//                   color: Colors.grey[200],
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   height: 14,
//                   width: 60,
//                   color: Colors.grey[200],
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   height: 32,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }