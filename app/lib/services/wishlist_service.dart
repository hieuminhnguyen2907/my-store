import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class WishlistService {
  static const String _wishlistItemsKey = 'wishlist_items';

  static Future<List<Product>> getWishlistItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_wishlistItemsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveWishlistItems(List<Product> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _wishlistItemsKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  static Future<bool> isFavorite(String productId) async {
    final items = await getWishlistItems();
    return items.any((item) => item.id == productId);
  }

  static Future<void> add(Product product) async {
    final items = await getWishlistItems();
    final exists = items.any((item) => item.id == product.id);

    if (!exists) {
      items.add(product);
      await _saveWishlistItems(items);
    }
  }

  static Future<void> remove(String productId) async {
    final items = await getWishlistItems();
    items.removeWhere((item) => item.id == productId);
    await _saveWishlistItems(items);
  }

  static Future<bool> toggle(Product product) async {
    final items = await getWishlistItems();
    final existingIndex = items.indexWhere((item) => item.id == product.id);

    if (existingIndex >= 0) {
      items.removeAt(existingIndex);
      await _saveWishlistItems(items);
      return false;
    }

    items.add(product);
    await _saveWishlistItems(items);
    return true;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wishlistItemsKey);
  }
}
