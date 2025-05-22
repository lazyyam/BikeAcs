// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';

import 'package:BikeAcs/pages/products/product_listing.dart';
import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/product_database.dart';
import 'package:BikeAcs/services/sell_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/users.dart';
import '../home/home_banner_model.dart';
import '../home/home_banner_view_model.dart';
import '../home/home_category_model.dart';
import '../home/home_category_view_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HomeCategoryViewModel _categoryViewModel = HomeCategoryViewModel();
  final HomeBannerViewModel _bannerViewModel = HomeBannerViewModel();
  final ProductDatabase _productDatabase = ProductDatabase();
  List<HomeCategoryModel> _categories = [];
  List<HomeBannerModel> _promoBanners = [];
  List<Product> _trendingProducts = [];
  bool _isRefreshing = false;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _initializePage(); // Initialize the page
  }

  Future<void> _initializePage() async {
    try {
      await Future.wait([
        _fetchBanners(),
        _fetchCategories(),
        _fetchTrendingProducts(),
      ]);
    } catch (e) {
      print('Error initializing page: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categoryData = await _categoryViewModel.fetchCategories();
      setState(() {
        _categories = categoryData;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final banners = await _bannerViewModel.fetchBanners();
      setState(() {
        _promoBanners = banners;
      });
    } catch (e) {
      print('Error fetching banners: $e');
    }
  }

  Future<void> _fetchTrendingProducts() async {
    try {
      final productIds = await SellAnalysisService().getMostOrderedProductIds();
      final List<Product> products = [];

      for (String productId in productIds) {
        final productData = await _productDatabase.getProduct(productId);
        if (productData != null) {
          products.add(productData); // Add Product object to the list
        }
      }

      setState(() {
        _trendingProducts = products; // Assign the List<Product>
      });
    } catch (e) {
      print('Error fetching trending products: $e');
    }
  }

  Future<void> _addCategory(String name) async {
    try {
      await _categoryViewModel.addCategory(name);
      _fetchCategories();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _categoryViewModel.deleteCategory(id);
      _fetchCategories();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  Future<void> _updateCategory(String id, String newName) async {
    try {
      await _categoryViewModel.updateCategory(id, newName);
      _fetchCategories();
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> _addBanner(File imageFile) async {
    try {
      await _bannerViewModel.addBanner(imageFile);
      _fetchBanners();
    } catch (e) {
      print('Error adding banner: $e');
    }
  }

  Future<void> _updateBanner(String id, File imageFile) async {
    try {
      await _bannerViewModel.updateBanner(id, imageFile);
      _fetchBanners();
    } catch (e) {
      print('Error updating banner: $e');
    }
  }

  Future<void> _deleteBanner(String id) async {
    try {
      await _bannerViewModel.deleteBanner(id);
      _fetchBanners();
    } catch (e) {
      print('Error deleting banner: $e');
    }
  }

  Future<void> _refreshHomeScreen() async {
    setState(() {
      _isLoading = true; // Use _isLoading instead of _isRefreshing
    });
    await Future.wait([
      _fetchBanners(),
      _fetchCategories(),
      _fetchTrendingProducts(),
    ]);
    setState(() {
      _isLoading = false; // Set _isLoading to false after refreshing
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(), // Show loading spinner
            )
          else
            RefreshIndicator(
              onRefresh: _refreshHomeScreen, // Trigger refresh on pull-down
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildPromoBanner(),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Categories',
                        onAdd: _showAddCategoryDialog),
                    _buildCategories(),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Trending Accessories'),
                    _buildTrendingProductsGrid(),
                  ],
                ),
              ),
            ),
        ],
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
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListing(
                  category: value.trim(),
                  isSearch: true, // Indicate this is a search action
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    final PageController _pageController = PageController();
    final currentUser = Provider.of<AppUsers?>(context);
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promoBanners.length,
            itemBuilder: (ctx, index) {
              final banner = _promoBanners[index];
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(banner.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFFFBA3B), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showEditBannerDialog(banner.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteBanner(banner.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _pageController,
          count: _promoBanners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: const Color(0xFFFFBA3B),
            dotColor: Colors.grey.shade400,
          ),
        ),
        if (isAdmin)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFBA3B),
            ),
            onPressed: _showAddBannerDialog,
            child: const Text(
              "Add Banner",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  void _showAddBannerDialog() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _addBanner(imageFile);
    }
  }

  void _showEditBannerDialog(String id) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _updateBanner(id, imageFile);
    }
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
    final currentUser = Provider.of<AppUsers?>(context);
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListing(
                      category: _categories[i].name,
                      isSearch: false,
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBA3B),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _categories[i].name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showEditCategoryDialog(
                            _categories[i].id, _categories[i].name),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _confirmDeleteCategory(_categories[i].id),
                        child: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Category"),
          content: const Text("Are you sure you want to delete this category?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteCategory(id);
                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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
                const Text(
                  "Add New Category",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
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
                        Navigator.pop(context);
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
                    const SizedBox(width: 10),
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
                          _addCategory(newCategory);
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

  void _showEditCategoryDialog(String id, String currentName) {
    TextEditingController _categoryController =
        TextEditingController(text: currentName);

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
                const Text(
                  "Edit Category",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: "Enter new category name",
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
                        Navigator.pop(context);
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
                    const SizedBox(width: 10),
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
                        String newCategoryName =
                            _categoryController.text.trim();
                        if (newCategoryName.isNotEmpty) {
                          _updateCategory(id, newCategoryName);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Update",
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

  Widget _buildTrendingProductsGrid() {
    if (_trendingProducts.isEmpty) {
      return const Center(child: Text("No trending products available"));
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
          childAspectRatio: 0.85,
        ),
        itemCount: _trendingProducts.length,
        itemBuilder: (ctx, i) {
          final product = _trendingProducts[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pushNamed(
                ctx,
                AppRoutes.productDetail,
                arguments: product, // Pass the Product object as an argument
              );
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product.images.isNotEmpty ? product.images[0] : '',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFFBA3B),
                            fontWeight: FontWeight.bold,
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
}
