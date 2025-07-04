import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/product_model.dart';
import 'package:farming_management/screens/customer/product_detail_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:farming_management/screens/customer/cart_screen.dart';
import 'package:farming_management/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/screens/customer/all_products.dart';
import './customer_notifications.dart';
import 'package:farming_management/auth/auth_service.dart';

class CustomerProductsScreen extends StatefulWidget {
  const CustomerProductsScreen({super.key});

  @override
  _CustomerProductsScreenState createState() => _CustomerProductsScreenState();
}

class _CustomerProductsScreenState extends State<CustomerProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  String _selectedCategory = 'View all';
  bool _isSearching = false;
  List<String> _categories = ['View all'];
  int _currentBannerIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  // Promo banners with asset images
  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Fresh Harvest',
      'subtitle': '50% off on selected items',
      'imageAsset': 'assets/promo_banners/promo1.jpg',
      'color': Colors.orange,
    },
    {
      'title': 'Free Delivery',
      'subtitle': 'On orders over ₵5000',
      'imageAsset': 'assets/promo_banners/promo2.jpg',
      'color': Colors.green,
    },
    {
      'title': 'New Arrivals',
      'subtitle': 'Fresh from the farm',
      'imageAsset': 'assets/promo_banners/promo3.jpg',
      'color': Colors.blue,
    },
    {
      'title': 'Organic Special',
      'subtitle': 'Premium organic products',
      'imageAsset': 'assets/promo_banners/promo4.jpg',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      setState(() {
        _categories = ['View all'];
        _categories
            .addAll(querySnapshot.docs.map((doc) => doc['name'] as String));
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = Colors.green[700];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green[50]!,
                      Colors.white,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fresh Farm',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    'Discover quality products',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search Button
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: green?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isSearching = true);
                                  showSearch(
                                    context: context,
                                    delegate: ProductSearchDelegate(),
                                  ).then((_) =>
                                      setState(() => _isSearching = false));
                                },
                                child: Icon(
                                  Icons.search,
                                  color: green,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Notification Button
                            Consumer<AuthService>(
                              builder: (context, authService, child) {
                                final user = authService.currentUser;
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('notifications')
                                      .where('userId', isEqualTo: user?.uid)
                                      .where('read', isEqualTo: false)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.hasData
                                        ? snapshot.data!.docs.length
                                        : 0;
                                    return Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: green?.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CustomerNotificationsScreen(),
                                                ),
                                              );
                                            },
                                            child: Icon(
                                              Icons.notifications_outlined,
                                              color: green,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[500],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                unreadCount > 99
                                                    ? '99+'
                                                    : unreadCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            // Cart Button
                            Consumer<CartService>(
                              builder: (context, cartService, child) {
                                return Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: green?.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CartScreen(),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.shopping_bag_outlined,
                                          color: green,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    if (cartService.totalQuantity > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red[500],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${cartService.totalQuantity}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Promo Carousel
          SliverToBoxAdapter(
            child: _buildPromoCarousel(),
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),

          // Products Section Header
          SliverToBoxAdapter(
            child: _buildSectionHeader(theme, green),
          ),

          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCarousel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          CarouselSlider(
            items: _promoBanners.map((banner) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.asset(
                        banner['imageAsset'],
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['title'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['subtitle'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: 140,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.9,
              onPageChanged: (index, reason) {
                _currentBannerIndex = index;
              },
            ),
            carouselController: _carouselController,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _promoBanners.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentBannerIndex == entry.key ? 24 : 8,
                height: 8,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                  color: _currentBannerIndex == entry.key
                      ? Colors.green[700]
                      : Colors.grey.withOpacity(0.4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[700] : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          isSelected ? Colors.green[700]! : Colors.grey[200]!,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, Color? green) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Featured Products',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_selectedCategory == 'View all') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllProductsScreen(),
                  ),
                );
              }
            },
            child: Text(
              '${_selectedCategory == 'View all' ? 'All' : _selectedCategory} Products',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _selectedCategory == 'View all'
                    ? Colors.green[700]
                    : Colors.grey[600],
                fontWeight: _selectedCategory == 'View all'
                    ? FontWeight.bold
                    : FontWeight.normal,
                decoration: _selectedCategory == 'View all'
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildProductsQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: _buildErrorState(snapshot.error.toString()));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _buildLoadingState());
        }

        if (snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              var product =
                  FarmProduct.fromFirestore(snapshot.data!.docs[index]);
              return _buildProductCard(product);
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  Widget _buildProductCard(FarmProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (50% of card height)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl.isNotEmpty
                          ? product.imageUrl
                          : 'https://blocks.astratic.com/img/general-img-landscape.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[50],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[50],
                        child: const Center(
                          child:
                              Icon(Icons.image, color: Colors.grey, size: 32),
                        ),
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (product.discount != null && product.discount! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[500],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${(product.discount! * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  // Organic Badge
                  if (product.isOrganic)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Organic',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Section (50% of card height)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating and Price Row
                    Row(
                      children: [
                        // Rating
                        Icon(Icons.star, size: 12, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Price
                        if (product.discount != null &&
                            product.discount! > 0) ...[
                          Text(
                            '₵${(product.pricePerUnit * (1 - product.discount!)).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '₵${product.pricePerUnit.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () {
                          debugPrint(
                              'Add to cart button pressed for product: ${product.name}');
                          final cartService =
                              Provider.of<CartService>(context, listen: false);
                          debugPrint(
                              'CartService found: ${cartService != null}');
                          cartService.addToCart(product);
                          debugPrint(
                              'Product added to cart. Cart count: ${cartService.itemCount}, Total quantity: ${cartService.totalQuantity}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Added ${product.name} to cart',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green[700],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 1,
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Query _buildProductsQuery() {
    Query query = FirebaseFirestore.instance.collection('products');

    if (_selectedCategory != 'View all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThan: '${_searchQuery}z');
    }

    return query;
  }
}

class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(query);
  }

  Widget _buildSearchResults(String searchQuery) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allProducts = snapshot.data!.docs
            .map((doc) => FarmProduct.fromFirestore(doc))
            .toList();
        final filtered = allProducts
            .where((product) =>
                product.name
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                product.description
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No products found for "$searchQuery"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try different keywords or browse categories',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            var product = filtered[index];
            return _buildSearchResultCard(product, context);
          },
        );
      },
    );
  }

  Widget _buildSearchResultCard(FarmProduct product, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[50],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[50],
                    child: const Center(child: Icon(Icons.error)),
                  ),
                ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₵${product.pricePerUnit}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> deleteProductImage(String imageUrl) async {
  try {
    if (imageUrl.isEmpty) {
      debugPrint('No image URL provided for deletion.');
      return;
    }
    final ref = FirebaseStorage.instance.refFromURL(imageUrl);
    await ref.delete();
    debugPrint('Image deleted successfully: $imageUrl');
  } on FirebaseException catch (e) {
    if (e.code != 'object-not-found') {
      debugPrint('Error deleting image: ${e.code} - ${e.message}');
      rethrow;
    }
    debugPrint('Image already deleted, ignoring error');
  } catch (e) {
    debugPrint('Unexpected error deleting image: $e');
    rethrow;
  }
}
