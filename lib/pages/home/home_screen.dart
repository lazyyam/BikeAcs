// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildPromoBanner(),
            const SizedBox(height: 16),
            _buildSectionTitle('Categories'),
            _buildCategories(),
            const SizedBox(height: 16),
            _buildSectionTitle('Trending Accessories'),
            _buildTrendingProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search accessories...",
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    final PageController _pageController = PageController();
    final List<String> _promoImages = [
      'https://picsum.photos/800/300?random=1',
      'https://picsum.photos/800/300?random=2',
      'https://picsum.photos/800/300?random=3',
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promoImages.length,
            itemBuilder: (ctx, index) {
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_promoImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _pageController,
          count: _promoImages.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: const Color(0xFFFFBA3B),
            dotColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      'Helmets',
      'Gloves',
      'Phone Holders',
      'LED Lights',
      'Saddlebags'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 22.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(20), // Smooth tap effect
            onTap: () {
              Navigator.pushNamed(
                ctx,
                AppRoutes.productListing,
                arguments: categories[i], // Pass category name as argument
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFBA3B),
                borderRadius: BorderRadius.circular(15), // Rounded edges
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Light shadow
                    blurRadius: 5,
                    offset: const Offset(0, 1), // Soft lift effect
                  ),
                ],
              ),
              child: Text(
                categories[i],
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingProducts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 4,
        itemBuilder: (ctx, i) => InkWell(
          onTap: () => Navigator.pushNamed(
            ctx,
            AppRoutes.productDetail,
            arguments: Product(
              id: '${i + 1}',
              name: 'Product ${i + 1}',
              price: 99.99,
              imageUrl: 'https://picsum.photos/200',
              arModelUrl: 'assets/3d_models/t1_helmet.glb',
              stock: (50 + i),
              description: 'T1_HELMET',
            ),
          ),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network('https://picsum.photos/200',
                      height: 120, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
                Text(
                  'Product ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '\RM99.99',
                  style: TextStyle(
                      color: Color(0xFFFFBA3B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
