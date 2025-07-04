import 'product_model.dart';

class CartItem {
  final FarmProduct product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}
