class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? categoryId;
  final String? categoryName;
  final double rating;
  final int reviewCount;
  final bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    String? parsedCategoryId;
    String? parsedCategoryName;

    if (rawCategory is Map<String, dynamic>) {
      parsedCategoryId = rawCategory['_id']?.toString();
      parsedCategoryName = rawCategory['name']?.toString();
    } else if (rawCategory != null) {
      parsedCategoryId = rawCategory.toString();
    }

    return Product(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: ((json['price'] as num?) ?? 0).toDouble(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString(),
      categoryId: parsedCategoryId,
      categoryName: parsedCategoryName,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': categoryId,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFavorite': isFavorite,
    };
  }
}
