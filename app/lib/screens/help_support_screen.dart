import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp & Hỗ trợ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SupportCard(
            title: 'Chăm sóc khách hàng',
            content: 'Email: support@bigcart.local\nĐiện thoại: +84 1900 0000',
          ),
          SizedBox(height: 12),
          _SupportCard(
            title: 'Giờ làm việc',
            content: 'Thứ Hai - Thứ Bảy\n08:00 - 21:00',
          ),
          SizedBox(height: 12),
          _SupportCard(
            title: 'Câu hỏi thường gặp',
            content:
                '- Đơn hàng của tôi đang ở đâu? Vào Đơn hàng của tôi trong Tài khoản.\n- Thay đổi địa chỉ như thế nào? Vào Tài khoản > Địa chỉ.\n- Chính sách hoàn tiền: 7 ngày cho sản phẩm chưa sử dụng.',
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final String title;
  final String content;

  const _SupportCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
