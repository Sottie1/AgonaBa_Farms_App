import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/product_model.dart';
import 'package:farming_management/models/category_model.dart';
import 'package:farming_management/screens/customer/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farming_management/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/screens/customer/cart_screen.dart';
import 'package:farming_management/screens/customer/category_products.dart';

class AllProductsScreen extends StatelessWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 1,
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.green),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (cartService.totalQuantity > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${cartService.totalQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Category>>(
        future: _fetchCategories(),
        builder: (context, catSnapshot) {
          if (catSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!catSnapshot.hasData || catSnapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found'));
          }
          final categories = catSnapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('approved', isEqualTo: true)
                .snapshots(),
            builder: (context, prodSnapshot) {
              if (prodSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!prodSnapshot.hasData || prodSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No products found'));
              }
              final allProducts = prodSnapshot.data!.docs
                  .map((doc) => FarmProduct.fromFirestore(doc))
                  .toList();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final products = allProducts
                      .where((p) => p.category == category.name)
                      .toList();
                  if (products.isEmpty) return const SizedBox.shrink();
                  return _buildCategorySection(context, category, products);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Category>> _fetchCategories() async {
    final query = await FirebaseFirestore.instance
        .collection('categories')
        .orderBy('name')
        .get();
    return query.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Widget _buildCategorySection(
      BuildContext context, Category category, List<FarmProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    width: 40,
                    height: 40,
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.category, size: 32, color: Colors.green),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('See All'),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, FarmProduct product) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        final inCart = cartService.isInCart(product.id);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Container(
            width: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      height: 110,
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 48),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.discount != null && product.discount! > 0
                            ? ''
                            : '₵${product.pricePerUnit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (product.discount != null &&
                          product.discount! > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₵${product.pricePerUnit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₵${(product.pricePerUnit * (1 - product.discount!)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (product.isOrganic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Organic',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (product.discount != null && product.discount! > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${(product.discount! * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                inCart ? Colors.grey[400] : Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                              inCart ? Icons.check : Icons.add_shopping_cart,
                              size: 18,
                              color: Colors.white),
                          label: Text(inCart ? 'Added' : 'Add to Cart',
                              style: const TextStyle(fontSize: 13)),
                          onPressed: inCart
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Product is already in the cart'),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : () {
                                  cartService.addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Added ${product.name} to cart'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
