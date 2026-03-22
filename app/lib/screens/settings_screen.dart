import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/wishlist_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _orderNotifications = true;
  bool _marketingNotifications = false;

  Future<void> _clearCart() async {
    await CartService.clearCart();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
  }

  Future<void> _clearWishlist() async {
    await WishlistService.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wishlist cleared')));
  }

  Future<void> _clearOrders() async {
    await OrderService.clearOrders();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order history cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Order notifications'),
            value: _orderNotifications,
            onChanged: (value) {
              setState(() => _orderNotifications = value);
            },
          ),
          SwitchListTile(
            title: const Text('Marketing notifications'),
            value: _marketingNotifications,
            onChanged: (value) {
              setState(() => _marketingNotifications = value);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.remove_shopping_cart_outlined),
            title: const Text('Clear cart'),
            onTap: _clearCart,
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Clear wishlist'),
            onTap: _clearWishlist,
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Clear order history'),
            onTap: _clearOrders,
          ),
        ],
      ),
    );
  }
}
