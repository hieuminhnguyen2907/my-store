import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/image_resolver.dart';
import '../widgets/home_header.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  String _selectedCategoryId = 'all';
  Future<List<Product>>? _featuredProductsFuture;
  Future<List<Product>>? _allProductsFuture;

  final List<_HomeCategory> _categories = const [
    _HomeCategory(
      id: 'all',
      title: 'All',
      icon: Icons.apps_outlined,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'women',
      title: 'Women',
      icon: Icons.female,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'men',
      title: 'Men',
      icon: Icons.male,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'accessories',
      title: 'Accessories',
      icon: Icons.shopping_bag_outlined,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'beauty',
      title: 'Beauty',
      icon: Icons.spa_outlined,
      backgroundColor: Color(0xFFF2EEE8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = _loadFeaturedProducts();
    _allProductsFuture = _loadAllProducts();
  }

  Future<List<Product>> _loadFeaturedProducts() async {
    try {
      final products = await ProductService.getFeaturedProducts();
      if (products.isNotEmpty) {
        return products;
      }
    } catch (_) {}
    return _fallbackFeaturedProducts;
  }

  Future<List<Product>> _loadAllProducts() async {
    try {
      final products = await ProductService.getProducts();
      if (products.isNotEmpty) {
        return products;
      }
    } catch (_) {}
    return _fallbackAllProducts;
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

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/search');
        break;
      case 2:
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        Navigator.pushNamed(context, '/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategories(),

                    const SizedBox(height: 10),

                    _buildAutumnBanner(),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Feature Products', 'Show all', () {
                      Navigator.pushNamed(context, '/products');
                    }),
                    const SizedBox(height: 12),
                    _buildFeatureProducts(),

                    const SizedBox(height: 24),

                    _buildNewCollectionBanner(),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Recommended', 'Show all', () {
                      Navigator.pushNamed(context, '/products');
                    }),
                    const SizedBox(height: 12),
                    _buildRecommendedProducts(),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Top Collection', 'Show all', () {
                      Navigator.pushNamed(context, '/products');
                    }),
                    const SizedBox(height: 12),
                    _buildTopCollection(),

                    const SizedBox(height: 30),
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

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((category) {
          final bool isSelected = _selectedCategoryId == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category.id),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.black
                          : category.backgroundColor,
                    ),
                    child: Icon(
                      category.icon,
                      color: isSelected ? Colors.white : Colors.black54,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.black : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutumnBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 188,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: const DecorationImage(
          image: AssetImage('assets/images/carousel_1.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Autumn\nCollection\n2021',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureProducts() {
    return FutureBuilder<List<Product>>(
      future: _featuredProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 230,
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        final allProducts = snapshot.data ?? _fallbackFeaturedProducts;
        final products = _ensureMinItems(
          _filterByCategory(allProducts),
          6,
          fallbackPool: allProducts,
        );

        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildFeatureProductCard(products[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildFeatureProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildAdaptiveImage(
                product.imageUrl,
                width: 112,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$ ${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCollectionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: const DecorationImage(
          image: AssetImage('assets/images/carousel_2.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEW COLLECTION',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'HANG OUT\n& PARTY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    return FutureBuilder<List<Product>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 124,
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        final allProducts = snapshot.data ?? _fallbackAllProducts;
        final products = _ensureMinItems(
          _filterByCategory(allProducts),
          5,
          fallbackPool: allProducts,
        );

        return SizedBox(
          height: 124,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildRecommendedCard(products[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecommendedCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: Container(
        width: 98,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildAdaptiveImage(
                product.imageUrl,
                width: 98,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$ ${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCollection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCollectionCard(
                  title: 'FOR SLIM\n& BEAUTY',
                  imageUrl: 'assets/images/carousel_1.jpg',
                  height: 200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildCollectionCard(
                      subtitle: 'Summer Collection 2021',
                      imageUrl: 'assets/images/carousel_2.jpg',
                      height: 94,
                    ),
                    const SizedBox(height: 12),
                    _buildCollectionCard(
                      imageUrl: 'assets/images/carousel_3.jpg',
                      height: 94,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildCollectionCard(
            title: 'Most sexy &\nfabulous\ndesign',
            imageUrl: 'assets/images/carousel_2.jpg',
            height: 180,
            fullWidth: true,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCollectionCard(
                  subtitle: 'The Office\nLife',
                  imageUrl: 'assets/images/carousel_1.jpg',
                  height: 160,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollectionCard(
                  subtitle: 'Elegant\nDesign',
                  imageUrl: 'assets/images/carousel_3.jpg',
                  height: 160,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard({
    String? title,
    String? subtitle,
    required String imageUrl,
    required double height,
    bool fullWidth = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: fullWidth ? double.infinity : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildAdaptiveImage(imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _filterByCategory(List<Product> products) {
    if (products.isEmpty) {
      return _fallbackAllProducts;
    }

    if (_selectedCategoryId == 'all') {
      return products;
    }

    final filtered = <Product>[];
    for (int i = 0; i < products.length; i++) {
      final categoryId = _virtualCategoryFromProduct(products[i], i);
      if (categoryId == _selectedCategoryId) {
        filtered.add(products[i]);
      }
    }

    return filtered.isEmpty ? products : filtered;
  }

  List<Product> _ensureMinItems(
    List<Product> source,
    int minItems, {
    List<Product>? fallbackPool,
  }) {
    if (source.isEmpty || minItems <= 0) {
      return source;
    }

    if (source.length >= minItems) {
      return source.take(minItems).toList();
    }

    final output = List<Product>.from(source);
    final existingIds = output.map((p) => p.id).toSet();
    final pool = fallbackPool ?? source;

    for (final product in pool) {
      if (output.length >= minItems) {
        break;
      }
      if (existingIds.add(product.id)) {
        output.add(product);
      }
    }

    return output;
  }

  String _virtualCategoryFromProduct(Product product, int index) {
    final categoryRaw =
        '${product.categoryId ?? ''} ${product.categoryName ?? ''}'
            .toLowerCase();
    if (categoryRaw.contains('women') ||
        categoryRaw.contains('female') ||
        categoryRaw.contains('lady')) {
      return 'women';
    }
    if (categoryRaw.contains('men') ||
        categoryRaw.contains('male') ||
        categoryRaw.contains('man')) {
      return 'men';
    }
    if (categoryRaw.contains('beauty') ||
        categoryRaw.contains('skin') ||
        categoryRaw.contains('care') ||
        categoryRaw.contains('cosmetic')) {
      return 'beauty';
    }

    final name = product.name.toLowerCase();
    if (name.contains('dress') ||
        name.contains('skirt') ||
        name.contains('women')) {
      return 'women';
    }
    if (name.contains('men') ||
        name.contains('shirt') ||
        name.contains('hoodie')) {
      return 'men';
    }
    if (name.contains('beauty') ||
        name.contains('skin') ||
        name.contains('care')) {
      return 'beauty';
    }

    const fallbackOrder = ['women', 'men', 'accessories', 'beauty'];
    return fallbackOrder[index % fallbackOrder.length];
  }

  Widget _buildAdaptiveImage(
    String source, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final resolvedNetworkUrl = resolveNetworkImageUrl(source);
    final fallbackAssetPath = resolveBundledFallbackAssetPath(source);
    final fallbackLegacyUrl = resolveLegacySeedImageUrl(source);
    if (resolvedNetworkUrl != null) {
      return Image.network(
        resolvedNetworkUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (fallbackAssetPath != null) {
            return Image.asset(
              fallbackAssetPath,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 18,
                  ),
                );
              },
            );
          }

          return Container(
            width: width,
            height: height,
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
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (fallbackLegacyUrl != null) {
          return Image.network(
            fallbackLegacyUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined, size: 18),
              );
            },
          );
        }

        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, size: 18),
        );
      },
    );
  }

  List<Product> get _fallbackFeaturedProducts => [
    Product(
      id: 'f1',
      name: 'Victorian Elegance Shirt',
      description: 'Classic modern shirt for daily styling',
      price: 39.99,
      imageUrl:
          'https://images.unsplash.com/photo-1581655353564-df123a1eb820?q=80&w=500&auto=format&fit=crop', // Ảnh sơ mi trắng tối giản
    ),
    Product(
      id: 'f2',
      name: 'Long Sleeve Dress',
      description: 'Minimal long sleeve outfit with soft tone',
      price: 45.00,
      imageUrl:
          'https://images.unsplash.com/photo-1496747611176-843222e1e57c?q=80&w=500&auto=format&fit=crop', // Ảnh váy lụa dài tay
    ),
    Product(
      id: 'f3',
      name: 'Stylish Fall Coat',
      description: 'Warm and elegant for autumn days',
      price: 80.00,
      imageUrl:
          'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?q=80&w=500&auto=format&fit=crop', // Ảnh áo măng tô thu đông
    ),
    Product(
      id: 'f4',
      name: 'Essential Casual Hoodie',
      description: 'Soft hoodie for modern wardrobe',
      price: 42.50,
      imageUrl:
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=500&auto=format&fit=crop', // Ảnh áo Hoodie xám
    ),
  ];

  List<Product> get _fallbackAllProducts => [
    Product(
      id: 'a1',
      name: 'White Fashion Hoodie',
      description: 'A clean hoodie style for all-day comfort',
      price: 29.00,
      imageUrl:
          'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a2',
      name: 'Cotton Premium Shirt',
      description: 'Premium cotton shirt with modern cut',
      price: 30.00,
      imageUrl:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a3',
      name: 'Elegant Leather Bag',
      description: 'Hand-crafted leather bag for city looks',
      price: 69.00,
      imageUrl:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a4',
      name: 'Natural Beauty Set',
      description: 'Skincare essentials for daily routine',
      price: 34.00,
      imageUrl:
          'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a5',
      name: 'Classic Women Dress',
      description: 'Soft fabric dress with elegant silhouette',
      price: 54.00,
      imageUrl:
          'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a6',
      name: 'Everyday Men Shirt',
      description: 'Refined shirt for office and cafe',
      price: 37.00,
      imageUrl:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=500&auto=format&fit=crop',
    ),
  ];
}

class _HomeCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color backgroundColor;

  const _HomeCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.backgroundColor,
  });
}
