class Category {
  final String id;
  final String name;
  final String icon;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      icon: json['icon']?.toString() ?? 'category',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'imageUrl': imageUrl};
  }
}
