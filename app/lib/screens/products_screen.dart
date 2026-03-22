import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/home_header.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_nav_bar.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  int _selectedBottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String? _errorText;
  bool _appliedInitialRouteFilters = false;

  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'default';

  double _minPrice = 0;
  double _maxPrice = 0;
  RangeValues _selectedPriceRange = const RangeValues(0, 0);
  bool _hasInitializedPriceRange = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedInitialRouteFilters) {
      return;
    }

    _appliedInitialRouteFilters = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) {
      return;
    }

    final categoryId = (args['categoryId'] as String?) ?? 'all';
    final sortBy = (args['sortBy'] as String?) ?? 'default';
    final search = (args['search'] as String?) ?? '';

    final normalizedCategory =
        {'all', 'women', 'men', 'accessories', 'beauty'}.contains(categoryId)
        ? categoryId
        : 'all';

    final normalizedSort =
        {'default', 'priceAsc', 'priceDesc', 'nameAsc'}.contains(sortBy)
        ? sortBy
        : 'default';

    _searchController.text = search;
    setState(() {
      _selectedCategory = normalizedCategory;
      _sortBy = normalizedSort;
      _searchQuery = search;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final products = await ProductService.getProducts();
      final prices = products.map((item) => item.price.toDouble()).toList();
      prices.sort();

      final minPrice = prices.isEmpty ? 0.0 : prices.first;
      final maxPrice = prices.isEmpty ? 0.0 : prices.last;

      RangeValues nextRange;
      if (!_hasInitializedPriceRange) {
        nextRange = RangeValues(minPrice, maxPrice);
      } else {
        final clampedStart = _selectedPriceRange.start.clamp(
          minPrice,
          maxPrice,
        );
        final clampedEnd = _selectedPriceRange.end.clamp(minPrice, maxPrice);
        final start = clampedStart.toDouble();
        final end = clampedEnd.toDouble();
        nextRange = start <= end
            ? RangeValues(start, end)
            : RangeValues(minPrice, maxPrice);
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _minPrice = minPrice;
          _maxPrice = maxPrice;
          _selectedPriceRange = nextRange;
          _hasInitializedPriceRange = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText = 'Không thể tải danh sách sản phẩm: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _resolveCategoryId(Product product) {
    final categoryRaw =
        '${product.categoryId ?? ''} ${product.categoryName ?? ''}'
            .toLowerCase();

    if (categoryRaw.contains('women') ||
        categoryRaw.contains('female') ||
        categoryRaw.contains('lady') ||
        categoryRaw.contains('nữ') ||
        categoryRaw.contains('nu')) {
      return 'women';
    }

    if (categoryRaw.contains('men') ||
        categoryRaw.contains('male') ||
        categoryRaw.contains('man') ||
        categoryRaw.contains('nam')) {
      return 'men';
    }

    if (categoryRaw.contains('accessories') ||
        categoryRaw.contains('accessory') ||
        categoryRaw.contains('phụ kiện') ||
        categoryRaw.contains('phu kien')) {
      return 'accessories';
    }

    if (categoryRaw.contains('beauty') ||
        categoryRaw.contains('skin') ||
        categoryRaw.contains('care') ||
        categoryRaw.contains('cosmetic') ||
        categoryRaw.contains('làm đẹp') ||
        categoryRaw.contains('lam dep') ||
        categoryRaw.contains('chăm sóc') ||
        categoryRaw.contains('cham soc')) {
      return 'beauty';
    }

    final name = product.name.toLowerCase();
    if (name.contains('dress') ||
        name.contains('skirt') ||
        name.contains('women') ||
        name.contains('đầm') ||
        name.contains('váy')) {
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
        name.contains('phụ kiện') ||
        name.contains('túi') ||
        name.contains('thắt lưng')) {
      return 'accessories';
    }

    return 'beauty';
  }

  List<Product> get _filteredProducts {
    final keyword = _searchQuery.trim().toLowerCase();

    final filtered = _allProducts.where((product) {
      final hitSearch =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.description.toLowerCase().contains(keyword);

      final categoryId = _resolveCategoryId(product);
      final hitCategory =
          _selectedCategory == 'all' || _selectedCategory == categoryId;

      final hitPrice =
          product.price >= _selectedPriceRange.start &&
          product.price <= _selectedPriceRange.end;

      return hitSearch && hitCategory && hitPrice;
    }).toList();

    if (_sortBy == 'priceAsc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'priceDesc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'nameAsc') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'all';
      _sortBy = 'default';
      _selectedPriceRange = RangeValues(_minPrice, _maxPrice);
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
    final products = _filteredProducts;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tất cả sản phẩm',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    '${products.length} sản phẩm',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Đặt lại bộ lọc',
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên sản phẩm...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showFilterBottomSheet();
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 46),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildActiveFilterSummary(),
            const SizedBox(height: 10),
            Expanded(child: _buildProductsBody(products)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTabChanged: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildProductsBody(List<Product> products) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorText!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return const Center(child: Text('Không có sản phẩm phù hợp bộ lọc'));
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                Navigator.pushNamed(
                  context,
                  '/product-detail',
                  arguments: products[index],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFilterSummary() {
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final hasCategory = _selectedCategory != 'all';
    final hasSort = _sortBy != 'default';
    final hasPrice =
        _allProducts.isNotEmpty &&
        (_selectedPriceRange.start > _minPrice ||
            _selectedPriceRange.end < _maxPrice);

    if (!hasSearch && !hasCategory && !hasSort && !hasPrice) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (hasSearch)
            _buildFilterChip('Từ khóa: ${_searchQuery.trim()}', () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            }),
          if (hasCategory)
            _buildFilterChip(
              'Danh mục: ${_categoryLabel(_selectedCategory)}',
              () {
                setState(() {
                  _selectedCategory = 'all';
                });
              },
            ),
          if (hasSort)
            _buildFilterChip('Sắp xếp: ${_sortLabel(_sortBy)}', () {
              setState(() {
                _sortBy = 'default';
              });
            }),
          if (hasPrice)
            _buildFilterChip(
              'Giá: ${formatVnd(_selectedPriceRange.start)} - ${formatVnd(_selectedPriceRange.end)}',
              () {
                setState(() {
                  _selectedPriceRange = RangeValues(_minPrice, _maxPrice);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemoved) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemoved,
      ),
    );
  }

  String _categoryLabel(String categoryId) {
    switch (categoryId) {
      case 'women':
        return 'Nữ';
      case 'men':
        return 'Nam';
      case 'accessories':
        return 'Phụ kiện';
      case 'beauty':
        return 'Làm đẹp';
      default:
        return 'Tất cả';
    }
  }

  String _sortLabel(String sortBy) {
    switch (sortBy) {
      case 'priceAsc':
        return 'Giá tăng dần';
      case 'priceDesc':
        return 'Giá giảm dần';
      case 'nameAsc':
        return 'Tên A-Z';
      default:
        return 'Mặc định';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        String draftCategory = _selectedCategory;
        String draftSortBy = _sortBy;
        RangeValues draftPriceRange = _selectedPriceRange;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final canSlide = _maxPrice > _minPrice;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bộ lọc sản phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            draftCategory = 'all';
                            draftSortBy = 'default';
                            draftPriceRange = RangeValues(_minPrice, _maxPrice);
                          });
                        },
                        child: const Text('Đặt lại'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Danh mục'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: draftCategory == 'all',
                        onSelected: (_) {
                          setModalState(() {
                            draftCategory = 'all';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Nữ'),
                        selected: draftCategory == 'women',
                        onSelected: (_) {
                          setModalState(() {
                            draftCategory = 'women';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Nam'),
                        selected: draftCategory == 'men',
                        onSelected: (_) {
                          setModalState(() {
                            draftCategory = 'men';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Phụ kiện'),
                        selected: draftCategory == 'accessories',
                        onSelected: (_) {
                          setModalState(() {
                            draftCategory = 'accessories';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Làm đẹp'),
                        selected: draftCategory == 'beauty',
                        onSelected: (_) {
                          setModalState(() {
                            draftCategory = 'beauty';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Sắp xếp'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: draftSortBy,
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('Mặc định'),
                      ),
                      DropdownMenuItem(
                        value: 'priceAsc',
                        child: Text('Giá tăng dần'),
                      ),
                      DropdownMenuItem(
                        value: 'priceDesc',
                        child: Text('Giá giảm dần'),
                      ),
                      DropdownMenuItem(
                        value: 'nameAsc',
                        child: Text('Tên A-Z'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        draftSortBy = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Khoảng giá: ${formatVnd(draftPriceRange.start)} - ${formatVnd(draftPriceRange.end)}',
                  ),
                  RangeSlider(
                    values: draftPriceRange,
                    min: _minPrice,
                    max: _maxPrice <= _minPrice ? _minPrice + 1 : _maxPrice,
                    divisions: canSlide ? 20 : null,
                    onChanged: !canSlide
                        ? null
                        : (values) {
                            setModalState(() {
                              draftPriceRange = values;
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = draftCategory;
                          _sortBy = draftSortBy;
                          _selectedPriceRange = draftPriceRange;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Áp dụng bộ lọc'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
