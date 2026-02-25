import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Container
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                  image: DecorationImage(
                    image: NetworkImage(widget.product.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback for broken images
                    },
                  ),
                ),
              ),
              // Favorite button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Product Name
          Text(
            widget.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 4),

          // Rating and Review Count
          if (widget.product.rating > 0)
            Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.product.rating}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${widget.product.reviewCount})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

          const SizedBox(height: 6),

          // Price
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
