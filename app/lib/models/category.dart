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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'imageUrl': imageUrl};
  }
}
