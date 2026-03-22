import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SupportCard(
            title: 'Customer Care',
            content: 'Email: support@bigcart.local\nPhone: +84 1900 0000',
          ),
          SizedBox(height: 12),
          _SupportCard(
            title: 'Business Hours',
            content: 'Monday - Saturday\n08:00 - 21:00',
          ),
          SizedBox(height: 12),
          _SupportCard(
            title: 'FAQ',
            content:
                '- Where is my order? Check My Orders in Account.\n- How to change address? Go to Account > Addresses.\n- Refund policy: 7 days for unused items.',
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
