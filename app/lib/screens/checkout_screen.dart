import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/storage_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _addresses = [];
  int _selectedAddressIndex = -1;

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
    _loadCheckoutData();
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

      await OrderService.createOrder(
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
      );

      await CartService.clearCart();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công')));
      Navigator.pushReplacementNamed(context, '/orders');
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
                                  'Đặt hàng',
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
