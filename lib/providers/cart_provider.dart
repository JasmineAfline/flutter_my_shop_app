import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  double get total => _cartItems.fold<double>(
    0,
    (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as int)),
  );

  void addToCart({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
  }) {
    // Check if item already exists in cart
    final existingIndex = _cartItems.indexWhere((item) => item['productId'] == productId);

    if (existingIndex >= 0) {
      // Item exists, increase quantity
      _cartItems[existingIndex]['quantity']++;
    } else {
      // New item, add to cart
      _cartItems.add({
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': 1,
      });
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _cartItems.length) {
      if (quantity <= 0) {
        removeFromCart(index);
      } else {
        _cartItems[index]['quantity'] = quantity;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int get itemCount => _cartItems.length;

  bool isEmpty() => _cartItems.isEmpty;

  bool isNotEmpty() => _cartItems.isNotEmpty;
}
