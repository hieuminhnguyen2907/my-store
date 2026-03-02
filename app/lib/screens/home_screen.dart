import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/home_header.dart';
import '../widgets/category_section.dart';
import '../widgets/feature_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  Future<List<Product>>? _featuredProductsFuture;
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture ??= ProductService.getFeaturedProducts();
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });

    // Navigate based on selected tab
    switch (index) {
      case 0:
        // Home - stay here
        break;
      case 1:
        // Search
        Navigator.pushNamed(context, '/search');
        break;
      case 2:
        // Cart
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        // Account
        Navigator.pushNamed(context, '/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const HomeHeader(),

            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Section
                    CategorySection(onCategorySelected: _onCategorySelected),

                    // Feature Banner
                    const FeatureBanner(
                      title: 'Autumn Collection',
                      subtitle: 'New fashion trends',
                      year: '2022',
                      imageUrl: 'assets/images/carousel_1.jpg',
                    ),

                    // Feature Products Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Feature Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to all products
                              Navigator.pushNamed(context, '/products');
                            },
                            child: Text(
                              'Show all',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Products Grid
                    if (_featuredProductsFuture != null)
                      FutureBuilder<List<Product>>(
                        future: _featuredProductsFuture!,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 400,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final products = snapshot.data ?? [];

                          if (products.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No featured products available'),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: products[index],
                                  onTap: () {
                                    // Navigate to product detail
                                    Navigator.pushNamed(
                                      context,
                                      '/product-detail',
                                      arguments: products[index],
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTabChanged: _onBottomNavTapped,
      ),
    );
  }
}
