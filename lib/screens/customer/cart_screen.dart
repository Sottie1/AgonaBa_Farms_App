import 'package:flutter/material.dart';
import 'package:farming_management/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farming_management/models/cart_item.dart';
import 'package:farming_management/screens/customer/checkout_screen.dart';
import 'package:farming_management/services/cart_service.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _appliedCoupon;

  void _increaseQuantity(String productId) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.incrementQuantity(productId);
  }

  void _decreaseQuantity(String productId) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.decrementQuantity(productId);
  }

  void _removeFromCart(String productId) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.removeFromCart(productId);
  }

  double _getSubtotal(List<CartItem> cartItems) {
    return cartItems.fold(
        0, (sum, item) => sum + item.product.pricePerUnit * item.quantity);
  }

  double _getDiscount(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) {
      if (item.product.discount != null && item.product.discount! > 0) {
        return sum +
            (item.product.pricePerUnit *
                item.product.discount! *
                item.quantity);
      }
      return sum;
    });
  }

  double get _couponDiscount => _appliedCoupon != null
      ? 10.0
      : 0.0; // Placeholder: flat 10 off if coupon applied

  double _getTotal(List<CartItem> cartItems) {
    final subtotal = _getSubtotal(cartItems);
    final discount = _getDiscount(cartItems);
    return subtotal - discount - _couponDiscount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = Colors.green[700];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shopping Cart',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Review your items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              if (cartService.cartItems.isNotEmpty) {
                return TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text(
                            'Are you sure you want to clear all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              cartService.clearCart();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label:
                      const Text('Clear', style: TextStyle(color: Colors.red)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          final cartItems = cartService.cartItems;

          if (cartItems.isEmpty) {
            return _buildEmptyState(theme, green);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final product = item.product;
                    final price =
                        (product.discount != null && product.discount! > 0)
                            ? product.pricePerUnit * (1 - product.discount!)
                            : product.pricePerUnit;

                    return _buildCartItemCard(item, price, theme, green);
                  },
                ),
              ),
              _buildSummaryCard(cartItems, theme, green, cartService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color? green) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: green?.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some fresh farm products to get started!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.storefront),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
      CartItem item, double price, ThemeData theme, Color? green) {
    final product = item.product;

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.red[600], size: 32),
            const SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _removeFromCart(product.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl.isNotEmpty
                          ? product.imageUrl
                          : 'https://blocks.astratic.com/img/general-img-landscape.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.error)),
                      ),
                    ),
                  ),
                  if (product.discount != null && product.discount! > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${(product.discount! * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  if (product.isOrganic)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Organic',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating} (${product.reviewCount})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (product.discount != null &&
                            product.discount! > 0) ...[
                          Text(
                            '₵${product.pricePerUnit}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₵${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '₵${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quantity Controls
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () => _decreaseQuantity(product.id),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => _increaseQuantity(product.id),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₵${(price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<CartItem> cartItems, ThemeData theme,
      Color? green, CartService cartService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary Header
          Row(
            children: [
              Icon(Icons.receipt_long, color: green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Order Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Summary Items
          _buildSummaryRow('Subtotal',
              '₵${_getSubtotal(cartItems).toStringAsFixed(2)}', theme),
          _buildSummaryRow('Discount',
              '-₵${_getDiscount(cartItems).toStringAsFixed(2)}', theme,
              isDiscount: true),
          // Coupon Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coupon', style: theme.textTheme.bodyLarge),
              _appliedCoupon == null
                  ? TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _appliedCoupon = 'SAMPLE10';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                const Text('Coupon applied: SAMPLE10'),
                              ],
                            ),
                            backgroundColor: Colors.green[700],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_offer, size: 16),
                      label: const Text('Apply Coupon'),
                      style: TextButton.styleFrom(
                        foregroundColor: green,
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SAMPLE10',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _appliedCoupon = null;
                                  });
                                },
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.green[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-₵${_couponDiscount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
          const Divider(height: 32),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '₵${_getTotal(cartItems) < 0 ? 0 : _getTotal(cartItems).toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(cartItems: cartItems),
                  ),
                );
                if (result == true) {
                  cartService.clearCart();
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.payment),
              label: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme,
      {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.red[600] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
