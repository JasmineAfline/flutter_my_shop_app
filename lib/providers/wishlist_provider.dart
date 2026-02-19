import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/models/product_model.dart';

class WishlistProvider with ChangeNotifier {
  static const _prefsKey = 'wishlist_items';
  Map<String, Product> _items = {};

  WishlistProvider() {
    _loadFromPrefs();
  }

  List<Product> get items => _items.values.toList();
  int get count => _items.length;

  bool contains(String productId) => _items.containsKey(productId);

  Future<void> add(Product product) async {
    _items[product.id] = product;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> remove(String productId) async {
    _items.remove(productId);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _items.map((key, value) => MapEntry(key, value.toMap()));
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (e) {
      debugPrint('Failed to save wishlist: $e');
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      decoded.forEach((key, value) {
        try {
          final p = Product.fromFirestore(Map<String, dynamic>.from(value), key);
          _items[key] = p;
        } catch (e) {
          debugPrint('Skipping wishlist item $key: $e');
        }
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load wishlist: $e');
    }
  }
}
