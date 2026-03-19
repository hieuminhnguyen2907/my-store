import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../utils/api_constants.dart';
import '../utils/storage_service.dart';
import '../utils/exceptions.dart';

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
  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static bool _isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  // Register user
  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (name.trim().isEmpty) {
        throw ValidationException('Name is required');
      }
      if (!_isValidEmail(email.trim())) {
        throw ValidationException('Please enter a valid email address');
      }
      if (password.length < 6) {
        throw ValidationException('Password must be at least 6 characters');
      }
      if (password != confirmPassword) {
        throw ValidationException('Passwords do not match');
      }

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
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        // Save token and user data
        await StorageService.saveToken(authResponse.token);
        await StorageService.saveUserData(authResponse.user.toJson());
        return authResponse;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Registration failed');
      } else {
        throw AppException(
          message: 'Server error occurred during registration',
          code: response.statusCode.toString(),
        );
      }
    } on ValidationException {
      rethrow;
    } on AppException {
      rethrow;
    } on SocketException {
      throw NetworkException(
        'Unable to connect to server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw NetworkException('Request timeout. Please try again.');
    } catch (e) {
      throw AppException(message: 'Unexpected error: $e');
    }
  }

  // Login user
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isValidEmail(email.trim())) {
        throw ValidationException('Please enter a valid email address');
      }
      if (password.isEmpty) {
        throw ValidationException('Password is required');
      }

      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/users/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        // Save token and user data
        await StorageService.saveToken(authResponse.token);
        await StorageService.saveUserData(authResponse.user.toJson());
        return authResponse;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw AuthException(error['message'] ?? 'Invalid email or password');
      } else {
        throw AppException(
          message: 'Server error occurred during login',
          code: response.statusCode.toString(),
        );
      }
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on AppException {
      rethrow;
    } on SocketException {
      throw NetworkException(
        'Unable to connect to server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw NetworkException('Request timeout. Please try again.');
    } catch (e) {
      throw AppException(message: 'Unexpected error: $e');
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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw AppException(message: 'User not found');
      } else {
        throw AppException(message: 'Failed to get user profile');
      }
    } on AuthException {
      rethrow;
    } on AppException {
      rethrow;
    } on SocketException {
      throw NetworkException(
        'Unable to connect to server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw NetworkException('Request timeout. Please try again.');
    } catch (e) {
      throw AppException(message: 'Unexpected error: $e');
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
        final user = User.fromJson(jsonDecode(response.body));
        await StorageService.saveUserData(user.toJson());
        return user;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw AppException(message: 'User not found');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Invalid data provided');
      } else {
        throw AppException(message: 'Failed to update profile');
      }
    } on AuthException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on AppException {
      rethrow;
    } on SocketException {
      throw NetworkException(
        'Unable to connect to server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw NetworkException('Request timeout. Please try again.');
    } catch (e) {
      throw AppException(message: 'Unexpected error: $e');
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      await StorageService.clearAuthData();
    } catch (e) {
      rethrow;
    }
  }
}
