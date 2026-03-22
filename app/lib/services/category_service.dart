import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/category.dart';
import '../utils/api_constants.dart';

class CategoryService {
  // Fetch all categories
  static Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse(categoriesEndpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((c) => Category.fromJson(c)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get category by ID
  static Future<Category?> getCategoryById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$categoriesEndpoint/$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Category.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load category');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Create category (admin only)
  static Future<Category> createCategory(
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(categoriesEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(categoryData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return Category.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update category
  static Future<Category> updateCategory(
    String id,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$categoriesEndpoint/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(categoryData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Category.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete category
  static Future<bool> deleteCategory(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$categoriesEndpoint/$id'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
