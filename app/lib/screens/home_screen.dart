import 'package:flutter/material.dart';
import '../models/carousel_item.dart';
import '../widgets/carousel_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<CarouselItem> carouselItems = [
    CarouselItem(
      title: 'Discover something new',
      subtitle: 'Special new arrivals just for you',
      imagePath: 'assets/images/carousel_1.jpg',
    ),
    CarouselItem(
      title: 'Update trendy outfit',
      subtitle: 'Favorite brands and hottest trends',
      imagePath: 'assets/images/carousel_2.jpg',
    ),
    CarouselItem(
      title: 'Explore your true style',
      subtitle: 'Relax and let us bring the style to you',
      imagePath: 'assets/images/carousel_3.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: carouselItems.length,
            itemBuilder: (context, index) {
              return CarouselCard(item: carouselItems[index]);
            },
          ),

          // Dots indicator at bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                carouselItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
