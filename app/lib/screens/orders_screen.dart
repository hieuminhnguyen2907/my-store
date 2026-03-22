import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../utils/currency_formatter.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<OrderRecord> _orders = [];

  String _paymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'failed':
        return 'Thanh toán thất bại';
      case 'pending':
        return 'Đang chờ thanh toán';
      case 'unpaid':
      default:
        return 'Chưa thanh toán';
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'unpaid':
      default:
        return Colors.grey;
    }
  }

  String _paymentMethodLabel(String method) {
    if (method.toLowerCase() == 'momo') {
      return 'MoMo';
    }
    return 'COD';
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders = await OrderService.getOrders();
    if (!mounted) return;

    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _goToAccount() {
    Navigator.pushNamedAndRemoveUntil(context, '/account', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(order.createdAt),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Sản phẩm: ${order.totalQuantity}'),
                        const SizedBox(height: 4),
                        Text('Tổng: ${formatVnd(order.total)}'),
                        const SizedBox(height: 4),
                        Text(
                          'Phương thức: ${_paymentMethodLabel(order.paymentMethod)}',
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Thanh toán: '),
                            Text(
                              _paymentStatusLabel(order.paymentStatus),
                              style: TextStyle(
                                color: _paymentStatusColor(order.paymentStatus),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if ((order.shippingAddress ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Giao đến: ${order.shippingAddress}'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomActions(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu mua sắm để tạo đơn hàng đầu tiên.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goToHome,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text(
                'Tiếp tục mua sắm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goToAccount,
                child: const Text('Quay lại tài khoản'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _goToHome,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text(
                  'Tiếp tục mua sắm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
