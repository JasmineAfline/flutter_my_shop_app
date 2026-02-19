import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/models/cart_model.dart';
import 'package:my_shop/models/product_model.dart';

// RECOMMENDED UPGRADE
class CartProvider with ChangeNotifier {
  // Use a Map of the Model for faster lookups by ID
  Map<String, CartItem> _cartItems = {};

  static const _prefsKey = 'cart_items';

  CartProvider() {
    _loadFromPrefs();
  }

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
    _saveToPrefs();
  }

  void removeItem(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
    _saveToPrefs();
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
      _saveToPrefs();
    }
  }

  void removeFromCart(String productId) {
    removeItem(productId);
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, Map<String, dynamic>> map = {};
      _cartItems.forEach((key, item) {
        map[key] = item.toMap();
      });
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving cart to prefs: $e');
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final Map<String, CartItem> loaded = {};
      decoded.forEach((key, value) {
        try {
          loaded[key] = CartItem.fromMap(Map<String, dynamic>.from(value));
        } catch (e) {
          debugPrint('Skipping invalid cart item $key: $e');
        }
      });
      _cartItems = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart from prefs: $e');
    }
  }
}