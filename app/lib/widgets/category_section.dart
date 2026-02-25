import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategorySection extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategorySection({super.key, required this.onCategorySelected});

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  late Future<List<Category>> _categoriesFuture;
  String selectedCategoryId = '';
  final Map<String, IconData> categoryIcons = {
    'Women': Icons.female,
    'Men': Icons.male,
    'Accessories': Icons.shopping_bag,
    'Beauty': Icons.spa,
  };

  final Map<String, Color> categoryColors = {
    'Women': const Color(0xFFFFCDD2),
    'Men': const Color(0xFFBBDEFB),
    'Accessories': const Color(0xFFE1BEE7),
    'Beauty': const Color(0xFFFFE0B2),
  };

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No categories found'),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (index) {
                final category = categories[index];
                final isSelected = selectedCategoryId == category.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategoryId = category.id;
                    });
                    widget.onCategorySelected(category.id);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == categories.length - 1 ? 16 : 8,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.black
                                : categoryColors[category.name] ??
                                    Colors.grey.shade200,
                          ),
                          child: Icon(
                            categoryIcons[category.name] ?? Icons.category,
                            color: isSelected ? Colors.white : Colors.black54,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

