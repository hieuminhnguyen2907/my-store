import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

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
    };
  }
}

class OrderService {
  static const String _ordersKey = 'orders_history';

  static Future<List<OrderRecord>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => OrderRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
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
  }) async {
    final orders = await getOrders();

    final order = OrderRecord(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      items: items,
      subtotal: subtotal,
      shipping: shipping,
      total: total,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      shippingAddress: shippingAddress,
    );

    orders.insert(0, order);
    await _saveOrders(orders);
    return order;
  }

  static Future<void> clearOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ordersKey);
  }
}
