import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/wishlist_service.dart';
import '../utils/image_resolver.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<Product> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await WishlistService.getWishlistItems();
    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _removeItem(Product product) async {
    await WishlistService.remove(product.id);
    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách yêu thích')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('Danh sách yêu thích đang trống'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildAdaptiveImage(item.imageUrl),
                  ),
                  title: Text(item.name),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/product-detail',
                      arguments: item,
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeItem(item),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAdaptiveImage(String source) {
    final resolvedNetworkUrl = resolveNetworkImageUrl(source);
    final fallbackAssetPath = resolveBundledFallbackAssetPath(source);

    if (resolvedNetworkUrl != null) {
      return Image.network(
        resolvedNetworkUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (fallbackAssetPath != null) {
            return Image.asset(
              fallbackAssetPath,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            );
          }
          return Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined, size: 18),
          );
        },
      );
    }

    final assetPath = fallbackAssetPath ?? source.trim();
    return Image.asset(
      assetPath,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 56,
          height: 56,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, size: 18),
        );
      },
    );
  }
}
