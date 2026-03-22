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
    String status = 'placed',
    String paymentMethod = 'cod',
    String paymentStatus = 'unpaid',
    String? paymentGatewayOrderId,
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
      status: status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      paymentGatewayOrderId: paymentGatewayOrderId,
    );

    orders.insert(0, order);
    await _saveOrders(orders);
    return order;
  }

  static Future<OrderRecord?> updateOrderPayment({
    required String orderId,
    required String paymentStatus,
    String? paymentGatewayOrderId,
    String? orderStatus,
  }) async {
    final orders = await getOrders();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      return null;
    }

    final current = orders[index];
    final updated = OrderRecord(
      id: current.id,
      createdAt: current.createdAt,
      items: current.items,
      subtotal: current.subtotal,
      shipping: current.shipping,
      total: current.total,
      receiverName: current.receiverName,
      receiverPhone: current.receiverPhone,
      shippingAddress: current.shippingAddress,
      status: orderStatus ?? current.status,
      paymentMethod: current.paymentMethod,
      paymentStatus: paymentStatus,
      paymentGatewayOrderId:
          paymentGatewayOrderId ?? current.paymentGatewayOrderId,
    );

    orders[index] = updated;
    await _saveOrders(orders);
    return updated;
  }

  static Future<void> clearOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ordersKey);
  }
}
