import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/image_resolver.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  String _selectedCategoryId = 'all';
  late Future<_HomeData> _homeDataFuture;

  final List<_HomeCategory> _categories = const [
    _HomeCategory(
      id: 'all',
      title: 'Tất cả',
      icon: Icons.apps_outlined,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'women',
      title: 'Nữ',
      icon: Icons.female,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'men',
      title: 'Nam',
      icon: Icons.male,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'accessories',
      title: 'Phụ kiện',
      icon: Icons.shopping_bag_outlined,
      backgroundColor: Color(0xFFF2EEE8),
    ),
    _HomeCategory(
      id: 'beauty',
      title: 'Làm đẹp',
      icon: Icons.spa_outlined,
      backgroundColor: Color(0xFFF2EEE8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    List<Product> featuredProducts = [];
    List<Product> allProducts = [];

    try {
      final results = await Future.wait<List<Product>>([
        ProductService.getFeaturedProducts(),
        ProductService.getProducts(),
      ]);
      featuredProducts = results[0];
      allProducts = results[1];
    } catch (_) {
      featuredProducts = [];
      allProducts = [];
    }

    if (allProducts.isEmpty) {
      allProducts = _fallbackAllProducts;
    }

    if (featuredProducts.isEmpty) {
      featuredProducts = _fallbackFeaturedProducts;
    }

    return _HomeData(featured: featuredProducts, all: allProducts);
  }

  Future<void> _refreshHomeData() async {
    final nextFuture = _loadHomeData();
    setState(() {
      _homeDataFuture = nextFuture;
    });
    await nextFuture;
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

  String get _selectedCategoryTitle {
    return _categories
        .firstWhere(
          (category) => category.id == _selectedCategoryId,
          orElse: () => _categories.first,
        )
        .title;
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
              child: RefreshIndicator(
                onRefresh: _refreshHomeData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategories(),
                      const SizedBox(height: 10),
                      _buildHeroBanner(),
                      const SizedBox(height: 24),
                      FutureBuilder<_HomeData>(
                        future: _homeDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          }

                          if (snapshot.hasError &&
                              !snapshot.hasData &&
                              snapshot.connectionState ==
                                  ConnectionState.done) {
                            return _buildErrorState();
                          }

                          final data =
                              snapshot.data ??
                              _HomeData(
                                featured: _fallbackFeaturedProducts,
                                all: _fallbackAllProducts,
                              );

                          return _buildDataSections(data);
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
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

  Widget _buildDataSections(_HomeData data) {
    final filteredAll = _filterByCategory(data.all);
    final filteredFeatured = _filterByCategory(data.featured);

    final featureProducts = _ensureMinItems(
      filteredFeatured,
      6,
      fallbackPool: filteredAll,
    );

    final recommendedProducts = _ensureMinItems(
      filteredAll,
      6,
      fallbackPool: data.all,
    );

    final topCollection = _buildTopCollectionPool(
      filteredAll,
      fallbackPool: data.all,
    );

    final hasCategoryData =
        _selectedCategoryId == 'all' || filteredAll.isNotEmpty;

    if (!hasCategoryData) {
      return _buildCategoryEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Sản phẩm nổi bật', 'Xem tất cả', () {
          Navigator.pushNamed(context, '/products');
        }),
        const SizedBox(height: 12),
        _buildFeatureProducts(featureProducts),
        const SizedBox(height: 24),
        _buildNewCollectionBanner(),
        const SizedBox(height: 24),
        _buildSectionHeader('Gợi ý cho bạn', 'Xem tất cả', () {
          Navigator.pushNamed(context, '/products');
        }),
        const SizedBox(height: 12),
        _buildRecommendedProducts(recommendedProducts),
        const SizedBox(height: 24),
        _buildSectionHeader('Bộ sưu tập nổi bật', 'Xem tất cả', () {
          Navigator.pushNamed(context, '/products');
        }),
        const SizedBox(height: 12),
        _buildTopCollection(topCollection),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildSectionHeader('Sản phẩm nổi bật', 'Xem tất cả', () {}),
        const SizedBox(height: 12),
        const SizedBox(
          height: 230,
          child: Center(child: CircularProgressIndicator(color: Colors.black)),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Gợi ý cho bạn', 'Xem tất cả', () {}),
        const SizedBox(height: 12),
        const SizedBox(
          height: 124,
          child: Center(child: CircularProgressIndicator(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Không thể tải dữ liệu trang chủ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng kiểm tra kết nối và thử lại.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshHomeData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chưa có sản phẩm trong "$_selectedCategoryTitle"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử danh mục khác để khám phá thêm sản phẩm.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _onCategorySelected('all'),
              child: const Text('Hiển thị tất cả sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategoryId == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category.id),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.black
                          : category.backgroundColor,
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
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
              Colors.black.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Lựa chọn theo mùa',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Làm mới\nphong cách mỗi ngày',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/products');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text(
                  'Mua ngay',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureProducts(List<Product> products) {
    if (products.isEmpty) {
      return _buildSectionEmptyHint('Không có sản phẩm nổi bật.');
    }

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
  }

  Widget _buildFeatureProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: SizedBox(
        width: 112,
        child: Container(
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
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
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
              'BỘ SƯU TẬP MỚI',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Xuống phố\n& Dự tiệc',
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

  Widget _buildRecommendedProducts(List<Product> products) {
    if (products.isEmpty) {
      return _buildSectionEmptyHint('Chưa có gợi ý phù hợp.');
    }

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
  }

  Widget _buildRecommendedCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: SizedBox(
        width: 98,
        child: Container(
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
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCollection(List<Product> products) {
    if (products.isEmpty) {
      return _buildSectionEmptyHint('Chưa có dữ liệu bộ sưu tập.');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product-detail',
                arguments: product,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildAdaptiveImage(product.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionEmptyHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(message, style: TextStyle(color: Colors.grey[700])),
      ),
    );
  }

  List<Product> _buildTopCollectionPool(
    List<Product> source, {
    required List<Product> fallbackPool,
  }) {
    return _ensureMinItems(source, 4, fallbackPool: fallbackPool);
  }

  List<Product> _filterByCategory(List<Product> products) {
    if (_selectedCategoryId == 'all') {
      return products;
    }

    return products.where((product) {
      final categoryId = _resolveCategoryId(product);
      return categoryId == _selectedCategoryId;
    }).toList();
  }

  List<Product> _ensureMinItems(
    List<Product> source,
    int minItems, {
    List<Product>? fallbackPool,
  }) {
    if (minItems <= 0) {
      return [];
    }

    final output = <Product>[];
    final existingIds = <String>{};

    for (final product in source) {
      if (output.length >= minItems) {
        break;
      }
      if (existingIds.add(product.id)) {
        output.add(product);
      }
    }

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

  String _resolveCategoryId(Product product) {
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
        name.contains('women') ||
        name.contains('dam') ||
        name.contains('nu') ||
        name.contains('nữ') ||
        name.contains('đầm')) {
      return 'women';
    }

    if (name.contains('shirt') ||
        name.contains('hoodie') ||
        name.contains('men') ||
        name.contains('nam')) {
      return 'men';
    }

    if (name.contains('bag') ||
        name.contains('watch') ||
        name.contains('wallet') ||
        name.contains('accessory') ||
        name.contains('phu kien') ||
        name.contains('phụ kiện') ||
        name.contains('tui') ||
        name.contains('túi')) {
      return 'accessories';
    }

    if (name.contains('beauty') ||
        name.contains('skin') ||
        name.contains('care') ||
        name.contains('lam dep') ||
        name.contains('làm đẹp')) {
      return 'beauty';
    }

    return 'accessories';
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
      name: 'Áo thanh lịch Victoria',
      description: 'Mẫu áo cổ điển hiện đại để mặc hằng ngày',
      price: 39.99,
      imageUrl:
          'https://images.unsplash.com/photo-1581655353564-df123a1eb820?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'f2',
      name: 'Đầm tay dài',
      description: 'Thiết kế tối giản, tông màu nhẹ nhàng',
      price: 45.00,
      imageUrl:
          'https://images.unsplash.com/photo-1496747611176-843222e1e57c?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'f3',
      name: 'Áo khoác thu sành điệu',
      description: 'Ấm áp và thanh lịch cho ngày se lạnh',
      price: 80.00,
      imageUrl:
          'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'f4',
      name: 'Áo hoodie cơ bản',
      description: 'Chất liệu mềm mại cho tủ đồ hiện đại',
      price: 42.50,
      imageUrl:
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=500&auto=format&fit=crop',
    ),
  ];

  List<Product> get _fallbackAllProducts => [
    Product(
      id: 'a1',
      name: 'Hoodie trắng thời trang',
      description: 'Phong cách tối giản, thoải mái cả ngày',
      price: 29.00,
      imageUrl:
          'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a2',
      name: 'Áo sơ mi cotton cao cấp',
      description: 'Chất cotton cao cấp với phom dáng hiện đại',
      price: 30.00,
      imageUrl:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a3',
      name: 'Túi da thanh lịch',
      description: 'Túi da chế tác tỉ mỉ cho phong cách thành thị',
      price: 69.00,
      imageUrl:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a4',
      name: 'Bộ chăm sóc da tự nhiên',
      description: 'Sản phẩm cần thiết cho quy trình chăm sóc da',
      price: 34.00,
      imageUrl:
          'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a5',
      name: 'Đầm nữ cổ điển',
      description: 'Chất vải mềm với dáng váy thanh lịch',
      price: 54.00,
      imageUrl:
          'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?q=80&w=500&auto=format&fit=crop',
    ),
    Product(
      id: 'a6',
      name: 'Áo sơ mi nam hằng ngày',
      description: 'Tinh tế cho công sở và đi cà phê',
      price: 37.00,
      imageUrl:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=500&auto=format&fit=crop',
    ),
  ];
}

class _HomeData {
  final List<Product> featured;
  final List<Product> all;

  const _HomeData({required this.featured, required this.all});
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
