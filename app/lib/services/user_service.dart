import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'role': role,
    };
  }
}

class AuthResponse {
  final String token;
  final User user;
  final String message;

  AuthResponse({
    required this.token,
    required this.user,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user']),
      message: json['message'] ?? '',
    );
  }
}

class UserService {
  // Register user
  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/users/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Login user
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/users/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get current user
  static Future<User> getCurrentUser(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$API_BASE_URL/users/current'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update user profile
  static Future<User> updateProfile({
    required String userId,
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$API_BASE_URL/users/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
