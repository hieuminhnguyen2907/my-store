import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/storage_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  bool _isVerifyingPayment = false;
  List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _addresses = [];
  int _selectedAddressIndex = -1;
  String _selectedPaymentMethod = 'cod';
  String? _pendingAppOrderId;
  String? _pendingMomoOrderId;

  double get _subtotal {
    double total = 0;
    for (final item in _cartItems) {
      total += item.subtotal;
    }
    return total;
  }

  double get _shipping => _cartItems.isEmpty ? 0 : 30000;

  double get _total => _subtotal + _shipping;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCheckoutData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPendingPaymentIfAny();
    }
  }

  Future<void> _loadCheckoutData() async {
    final cartItems = await CartService.getCartItems();
    final userData = await StorageService.getUserData() ?? {};

    final addresses = <Map<String, dynamic>>[];
    final rawAddresses = userData['addresses'];
    if (rawAddresses is List) {
      for (final address in rawAddresses) {
        if (address is Map) {
          addresses.add(Map<String, dynamic>.from(address));
        }
      }
    }

    int selectedIndex = -1;
    for (int i = 0; i < addresses.length; i++) {
      if (addresses[i]['isDefault'] == true) {
        selectedIndex = i;
        break;
      }
    }

    if (selectedIndex < 0 && addresses.isNotEmpty) {
      selectedIndex = 0;
    }

    if (!mounted) return;
    setState(() {
      _cartItems = cartItems;
      _addresses = addresses;
      _selectedAddressIndex = selectedIndex;
      _isLoading = false;
    });
  }

  Future<void> _placeOrder() async {
    if (_pendingMomoOrderId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang chờ xác nhận thanh toán trước đó. Vui lòng đợi.'),
        ),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng của bạn đang trống')),
      );
      return;
    }

    if (_selectedAddressIndex < 0 ||
        _selectedAddressIndex >= _addresses.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final selectedAddress = _addresses[_selectedAddressIndex];
      final shippingAddress =
          '${selectedAddress['address'] ?? ''}, ${selectedAddress['city'] ?? ''}, ${selectedAddress['country'] ?? ''}';

      final pendingOrder = await OrderService.createOrder(
        items: _cartItems
            .map(
              (item) => OrderItem(
                product: item.product,
                quantity: item.quantity,
                unitPrice: item.product.price,
              ),
            )
            .toList(),
        subtotal: _subtotal,
        shipping: _shipping,
        total: _total,
        receiverName: selectedAddress['fullname']?.toString(),
        receiverPhone: selectedAddress['phoneNumber']?.toString(),
        shippingAddress: shippingAddress,
        status: _selectedPaymentMethod == 'momo' ? 'pending_payment' : 'placed',
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _selectedPaymentMethod == 'momo' ? 'pending' : 'unpaid',
      );

      if (_selectedPaymentMethod == 'cod') {
        await CartService.clearCart();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công')));
        Navigator.pushReplacementNamed(context, '/orders');
        return;
      }

      final momoPayment = await PaymentService.createMomoPayment(
        amount: _total.round(),
        clientOrderId: pendingOrder.id,
      );

      await OrderService.updateOrderPayment(
        orderId: pendingOrder.id,
        paymentStatus: 'pending',
        paymentGatewayOrderId: momoPayment.momoOrderId,
      );

      final launched = await _openExternalPaymentPage(momoPayment);
      if (!launched) {
        throw Exception(
          'Không thể mở MoMo. Hãy kiểm tra đã cài app MoMo (Sandbox), hoặc thử lại bằng trình duyệt.',
        );
      }

      _pendingAppOrderId = pendingOrder.id;
      _pendingMomoOrderId = momoPayment.momoOrderId;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng hoàn tất thanh toán trên MoMo. App sẽ tự kiểm tra khi bạn quay lại.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  Future<bool> _openExternalPaymentPage(MomoCreatePaymentResult payment) async {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final candidates = isMobile
        ? payment.launchCandidates
        : <String>[payment.payUrl];

    for (final candidate in candidates) {
      final uri = Uri.tryParse(candidate);
      if (uri == null) {
        continue;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return true;
      }
    }

    return false;
  }

  Future<void> _verifyPendingPaymentIfAny() async {
    final appOrderId = _pendingAppOrderId;
    final momoOrderId = _pendingMomoOrderId;
    if (appOrderId == null || momoOrderId == null || _isVerifyingPayment) {
      return;
    }

    await _verifyMomoPayment(appOrderId: appOrderId, momoOrderId: momoOrderId);
  }

  Future<void> _verifyMomoPayment({
    required String appOrderId,
    required String momoOrderId,
  }) async {
    if (_isVerifyingPayment) {
      return;
    }

    setState(() => _isVerifyingPayment = true);
    try {
      MomoPaymentStatusResult status =
          await PaymentService.getMomoPaymentStatus(momoOrderId);

      // Give MoMo/IPN some time to settle before concluding final state.
      const maxAttempts = 5;
      int attempt = 1;
      while (status.isPending && attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
        status = await PaymentService.getMomoPaymentStatus(momoOrderId);
        attempt++;
      }

      if (status.isPaid) {
        await OrderService.updateOrderPayment(
          orderId: appOrderId,
          paymentStatus: 'paid',
          paymentGatewayOrderId: momoOrderId,
          orderStatus: 'placed',
        );
        await CartService.clearCart();
        if (!mounted) return;
        _pendingAppOrderId = null;
        _pendingMomoOrderId = null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thanh toán thành công')));
        Navigator.pushReplacementNamed(context, '/orders');
        return;
      }

      if (status.isFailed) {
        await OrderService.updateOrderPayment(
          orderId: appOrderId,
          paymentStatus: 'failed',
          paymentGatewayOrderId: momoOrderId,
          orderStatus: 'payment_failed',
        );
        if (!mounted) return;
        _pendingAppOrderId = null;
        _pendingMomoOrderId = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.error?.isNotEmpty == true
                  ? status.error!
                  : 'Thanh toán thất bại. Vui lòng thử lại.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/orders');
        return;
      }

      if (!mounted) return;
      _pendingAppOrderId = null;
      _pendingMomoOrderId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Giao dịch đang chờ xác nhận từ MoMo. Vui lòng kiểm tra lại sau.',
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, '/orders');
    } finally {
      if (mounted) {
        setState(() => _isVerifyingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? const Center(child: Text('Giỏ hàng của bạn đang trống'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Địa chỉ giao hàng',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (_addresses.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Không tìm thấy địa chỉ. Vui lòng thêm địa chỉ giao hàng để tiếp tục.',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/addresses',
                                );
                                await _loadCheckoutData();
                              },
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Thêm địa chỉ'),
                            ),
                          ],
                        )
                      else
                        ..._addresses.asMap().entries.map((entry) {
                          final index = entry.key;
                          final address = entry.value;
                          final isSelected = _selectedAddressIndex == index;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.04)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() => _selectedAddressIndex = index);
                              },
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected ? Colors.black : Colors.grey,
                              ),
                              title: Text(
                                address['fullname']?.toString() ?? '-',
                              ),
                              subtitle: Text(
                                '${address['address'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}\n${address['phoneNumber'] ?? ''}',
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      Text(
                        'Phương thức thanh toán',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: RadioGroup<String>(
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedPaymentMethod = value);
                          },
                          child: Column(
                            children: [
                              const RadioListTile<String>(
                                value: 'cod',
                                title: Text('Thanh toán khi nhận hàng (COD)'),
                              ),
                              const Divider(height: 1),
                              const RadioListTile<String>(
                                value: 'momo',
                                title: Text('Ví MoMo (thanh toán online)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tóm tắt đơn hàng',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ..._cartItems.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.product.name),
                          subtitle: Text('Số lượng: ${item.quantity}'),
                          trailing: Text(
                            formatVnd(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Tạm tính', _subtotal),
                      const SizedBox(height: 6),
                      _summaryRow('Phí vận chuyển', _shipping),
                      const SizedBox(height: 8),
                      _summaryRow('Tổng cộng', _total, emphasize: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Tiếp tục',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryRow(String label, double value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
        Text(
          formatVnd(value),
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
