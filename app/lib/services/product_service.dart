import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../utils/api_constants.dart';

class ProductService {
  // Fetch all featured products
  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await http
          .get(Uri.parse('$productsEndpoint?featured=true'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((p) => Product.fromJson(p)).toList();
      } else {
        throw Exception('Failed to load featured products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Fetch all products with optional filtering
  static Future<List<Product>> getProducts({
    String? category,
    String? search,
    bool? featured,
  }) async {
    try {
      String url = productsEndpoint;
      final params = <String, String>{};

      if (category != null && category != 'all') {
        params['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (featured != null && featured) {
        params['featured'] = 'true';
      }

      final response = await http
          .get(Uri.parse(url).replace(queryParameters: params))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((p) => Product.fromJson(p)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Fetch products by category
  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$productsEndpoint/category/$categoryId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((p) => Product.fromJson(p)).toList();
      } else {
        throw Exception('Failed to load category products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get product by ID
  static Future<Product?> getProductById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$productsEndpoint/$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Search products
  static Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              productsEndpoint,
            ).replace(queryParameters: {'search': query}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((p) => Product.fromJson(p)).toList();
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Create product (admin only)
  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http
          .post(
            Uri.parse(productsEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(productData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update product
  static Future<Product> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$productsEndpoint/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(productData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete product
  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$productsEndpoint/$id'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
