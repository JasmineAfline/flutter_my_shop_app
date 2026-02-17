import 'package:flutter/material.dart';
import 'package:my_shop/models/cart_model.dart';
import 'package:my_shop/models/product_model.dart';

// RECOMMENDED UPGRADE
class CartProvider with ChangeNotifier {
  // Use a Map of the Model for faster lookups by ID
  Map<String, CartItem> _cartItems = {};

  Map<String, CartItem> get cartItems => _cartItems;

  int get itemCount => _cartItems.length;

  double get total => _cartItems.values.fold(0, (sum, item) => sum + (item.price * item.quantity));

  // Alias for total to match code expectations
  double get totalAmount => total;

  // Get cart items as a list of maps for checkout
  List<Map<String, dynamic>> get cartItemsList => _cartItems.values.map((item) => item.toMap()).toList();

  void addToCart(Product product) {
    if (_cartItems.containsKey(product.id)) {
      _cartItems.update(product.id, (old) => CartItem(
        productId: old.productId, 
        title: old.title, 
        quantity: old.quantity + 1, 
        price: old.price, 
        imageUrl: old.imageUrl
      ));
    } else {
      _cartItems.putIfAbsent(product.id, () => CartItem(
        productId: product.id, 
        title: product.title, 
        quantity: 1, 
        price: product.price, 
        imageUrl: product.imageUrl
      ));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_cartItems.containsKey(productId)) {
      if (quantity <= 0) {
        _cartItems.remove(productId);
      } else {
        _cartItems.update(productId, (old) => CartItem(
          productId: old.productId,
          title: old.title,
          quantity: quantity,
          price: old.price,
          imageUrl: old.imageUrl,
        ));
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    removeItem(productId);
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}