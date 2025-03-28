// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/users.dart';

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
            _buildSectionTitle('Categories', onAdd: _showAddCategoryDialog),
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

  Widget _buildSectionTitle(String title, {VoidCallback? onAdd}) {
    final currentUser = Provider.of<AppUsers?>(context);
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isAdmin && onAdd != null) ...[
            // Only show for admin
            const SizedBox(width: 10), // Space between text and button
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBA3B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
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
      height: 60, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 6.0, vertical: 10.0), // Reduced vertical padding
          child: InkWell(
            borderRadius:
                BorderRadius.circular(15), // Slightly smaller rounding
            onTap: () {
              Navigator.pushNamed(ctx, AppRoutes.productListing,
                  arguments: categories[i]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6), // Smaller padding
              decoration: BoxDecoration(
                color: const Color(0xFFFFBA3B),
                borderRadius: BorderRadius.circular(
                    12), // Adjusted to match smaller height
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4, // Reduced shadow intensity
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                // Ensures the text is perfectly centered
                child: Text(
                  categories[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController _categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Add New Category",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // Input Field
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: "Enter category name",
                    prefixIcon: const Icon(Icons.category, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Color(0xFF3C312B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Spacing
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBA3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        String newCategory = _categoryController.text.trim();
                        if (newCategory.isNotEmpty) {
                          setState(() {
                            // categories.add(newCategory); // Update list
                          });
                        }
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Add",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              category: 'Helmet',
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
