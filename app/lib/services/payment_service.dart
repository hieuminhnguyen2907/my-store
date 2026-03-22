import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';

class MomoCreatePaymentResult {
  final String momoOrderId;
  final String? clientOrderId;
  final String payUrl;
  final String? deeplink;
  final String? applink;
  final String? qrCodeUrl;

  MomoCreatePaymentResult({
    required this.momoOrderId,
    required this.payUrl,
    this.clientOrderId,
    this.deeplink,
    this.applink,
    this.qrCodeUrl,
  });

  List<String> get launchCandidates {
    final values = <String?>[deeplink, applink, payUrl];
    final sanitized = <String>[];
    for (final value in values) {
      final raw = value?.trim() ?? '';
      if (raw.isNotEmpty && !sanitized.contains(raw)) {
        sanitized.add(raw);
      }
    }
    return sanitized;
  }
}

class MomoPaymentStatusResult {
  final String status;
  final String? error;
  final String? transId;

  MomoPaymentStatusResult({required this.status, this.error, this.transId});

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isPending => status.toUpperCase() == 'PENDING';
}

class PaymentService {
  static Future<MomoCreatePaymentResult> createMomoPayment({
    required int amount,
    required String clientOrderId,
  }) async {
    final response = await http
        .post(
          Uri.parse(momoCreatePaymentEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount,
            'orderInfo': 'Thanh toan don hang $clientOrderId',
            'clientOrderId': clientOrderId,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = _safeDecode(response.body);

    if (response.statusCode != 200 || decoded['ok'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Không thể tạo phiên thanh toán MoMo',
      );
    }

    final payUrl = decoded['payUrl']?.toString() ?? '';
    final momoOrderId = decoded['orderId']?.toString() ?? '';
    final momoPayload = decoded['momo'];
    final momoData = momoPayload is Map<String, dynamic>
        ? momoPayload
        : <String, dynamic>{};

    if (payUrl.isEmpty || momoOrderId.isEmpty) {
      throw Exception('Dữ liệu thanh toán MoMo không hợp lệ');
    }

    return MomoCreatePaymentResult(
      momoOrderId: momoOrderId,
      clientOrderId: decoded['clientOrderId']?.toString(),
      payUrl: payUrl,
      deeplink:
          decoded['deeplink']?.toString() ?? momoData['deeplink']?.toString(),
      applink:
          decoded['applink']?.toString() ?? momoData['applink']?.toString(),
      qrCodeUrl:
          decoded['qrCodeUrl']?.toString() ?? momoData['qrCodeUrl']?.toString(),
    );
  }

  static Future<MomoPaymentStatusResult> getMomoPaymentStatus(
    String momoOrderId,
  ) async {
    final response = await http
        .get(Uri.parse('$momoStatusEndpoint/$momoOrderId'))
        .timeout(const Duration(seconds: 20));

    final decoded = _safeDecode(response.body);

    if (response.statusCode != 200 || decoded['ok'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Không thể kiểm tra trạng thái thanh toán',
      );
    }

    return MomoPaymentStatusResult(
      status: decoded['status']?.toString() ?? 'PENDING',
      error: decoded['error']?.toString(),
      transId: decoded['transId']?.toString(),
    );
  }

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {
      // Ignore parse errors and return fallback map.
    }
    return <String, dynamic>{};
  }
}
