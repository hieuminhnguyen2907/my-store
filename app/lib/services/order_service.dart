import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../utils/api_constants.dart';
import '../utils/storage_service.dart';

class OrderItem {
  final Product product;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class OrderRecord {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final String? receiverName;
  final String? receiverPhone;
  final String? shippingAddress;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentGatewayOrderId;

  OrderRecord({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    this.receiverName,
    this.receiverPhone,
    this.shippingAddress,
    this.status = 'placed',
    this.paymentMethod = 'cod',
    this.paymentStatus = 'unpaid',
    this.paymentGatewayOrderId,
  });

  int get totalQuantity {
    int quantity = 0;
    for (final item in items) {
      quantity += item.quantity;
    }
    return quantity;
  }

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? []);
    return OrderRecord(
      id: (json['id'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      items: rawItems
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),
      shippingAddress: json['shippingAddress']?.toString(),
      status: (json['status'] ?? 'placed').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'cod').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'unpaid').toString(),
      paymentGatewayOrderId: json['paymentGatewayOrderId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'total': total,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentGatewayOrderId': paymentGatewayOrderId,
    };
  }
}

class OrderService {
  static const String _ordersKey = 'orders_history';

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore parse errors and use fallback message.
    }
    return 'Yeu cau that bai (${response.statusCode})';
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để thao tác đơn hàng');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static OrderRecord _fromServerJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? []);
    final mappedItems = rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      final productMap = <String, dynamic>{
        'id': map['productId']?.toString() ?? '',
        'name': map['productName']?.toString() ?? 'Sản phẩm',
        'description': '',
        'price': (map['unitPrice'] as num?)?.toDouble() ?? 0,
        'imageUrl': map['productImage']?.toString() ?? '',
        'category': null,
      };

      return OrderItem(
        product: Product.fromJson(productMap),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return OrderRecord(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      items: mappedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),
      shippingAddress: json['shippingAddress']?.toString(),
      status: (json['status'] ?? 'placed').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'cod').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'unpaid').toString(),
      paymentGatewayOrderId: json['paymentGatewayOrderId']?.toString(),
    );
  }

  static Future<List<OrderRecord>> getOrders() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$ordersEndpoint/my'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      final orders = decoded
          .map((item) => _fromServerJson(item as Map<String, dynamic>))
          .toList();
      await _saveOrders(orders);
      return orders;
    }

    // Return empty list on error instead of stale data
    // This ensures orders are always sourced from backend, not cached
    throw Exception(_extractErrorMessage(response));
  }

  static Future<void> _saveOrders(List<OrderRecord> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((order) => order.toJson()).toList()),
    );
  }

  static Future<OrderRecord> createOrder({
    required List<OrderItem> items,
    required double subtotal,
    required double shipping,
    required double total,
    String? receiverName,
    String? receiverPhone,
    String? shippingAddress,
    String status = 'placed',
    String paymentMethod = 'cod',
    String paymentStatus = 'unpaid',
    String? paymentGatewayOrderId,
  }) async {
    final headers = await _authHeaders();
    final payload = {
      'items': items
          .map(
            (item) => {
              'productId': item.product.id,
              'productName': item.product.name,
              'productImage': item.product.imageUrl,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'subtotal': item.subtotal,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'total': total,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentGatewayOrderId': paymentGatewayOrderId,
    };

    final response = await http
        .post(
          Uri.parse(ordersEndpoint),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response));
    }

    final order = _fromServerJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    // Try to update local cache, but don't fail if we can't load orders
    try {
      final orders = await getOrders();
      final existingIndex = orders.indexWhere((item) => item.id == order.id);
      if (existingIndex >= 0) {
        orders[existingIndex] = order;
      } else {
        orders.insert(0, order);
      }
      await _saveOrders(orders);
    } catch (e) {
      // If we can't load orders from backend, still consider the order created
      // but don't cache stale data
    }

    return order;
  }

  static Future<OrderRecord?> updateOrderPayment({
    required String orderId,
    required String paymentStatus,
    String? paymentGatewayOrderId,
    String? orderStatus,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .patch(
          Uri.parse('$ordersEndpoint/$orderId/payment'),
          headers: headers,
          body: jsonEncode({
            'paymentStatus': paymentStatus,
            'paymentGatewayOrderId': paymentGatewayOrderId,
            'status': orderStatus,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }

    final updated = _fromServerJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    final orders = await getOrders();
    final idx = orders.indexWhere((item) => item.id == updated.id);
    if (idx >= 0) {
      orders[idx] = updated;
    } else {
      orders.insert(0, updated);
    }
    await _saveOrders(orders);
    return updated;
  }

  static Future<void> clearOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ordersKey);
  }
}
