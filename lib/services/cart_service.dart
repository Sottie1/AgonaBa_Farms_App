import 'package:flutter/foundation.dart';
import 'package:farming_management/models/cart_item.dart';
import 'package:farming_management/models/product_model.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount => _cartItems.length;

  int get totalQuantity =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item.product.discount != null && item.product.discount! > 0
          ? item.product.pricePerUnit * (1 - item.product.discount!)
          : item.product.pricePerUnit;
      return sum + (price * item.quantity);
    });
  }

  double get subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      return sum + (item.product.pricePerUnit * item.quantity);
    });
  }

  double get discount {
    return _cartItems.fold(0.0, (sum, item) {
      if (item.product.discount != null && item.product.discount! > 0) {
        return sum +
            (item.product.pricePerUnit *
                item.product.discount! *
                item.quantity);
      }
      return sum;
    });
  }

  void addToCart(FarmProduct product, {int quantity = 1}) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Product already exists in cart, increase quantity
      _cartItems[existingIndex].quantity += quantity;
    } else {
      // Add new product to cart
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }

    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        product: FarmProduct(
          id: '',
          name: '',
          description: '',
          category: '',
          subCategory: '',
          pricePerUnit: 0.0,
          unit: '',
          imageUrl: '',
          imageUrls: [],
          growthStage: '',
          daysToMaturity: 0,
          season: '',
          rating: 0.0,
          reviewCount: 0,
          compatibleCrops: [],
          commonPests: [],
          diseases: [],
          careRequirements: {},
          isOrganic: false,
          harvestDate: null,
          stock: 0,
          supplier: '',
          farmerId: '',
          farmerName: '',
          createdAt: DateTime.now(),
          discount: null,
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  void incrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }
}
