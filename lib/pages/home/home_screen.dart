// ignore_for_file: no_leading_underscores_for_local_identifiers, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, use_build_context_synchronously, deprecated_member_use, sized_box_for_whitespace, unnecessary_const

import 'dart:io';

import 'package:BikeAcs/pages/products/product_listing_screen.dart';
import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/sales_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../appUsers/users.dart';
import '../home/home_banner_model.dart';
import '../home/home_banner_view_model.dart';
import '../home/home_category_model.dart';
import '../home/home_category_view_model.dart';
import '../products/product_view_model.dart'; // Import ProductViewModel

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HomeCategoryViewModel _categoryViewModel = HomeCategoryViewModel();
  final HomeBannerViewModel _bannerViewModel = HomeBannerViewModel();
  final ProductViewModel _productViewModel =
      ProductViewModel(); // Use ProductViewModel
  List<HomeCategoryModel> _categories = [];
  List<HomeBannerModel> _promoBanners = [];
  List<Product> _trendingProducts = [];
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
      final productIds = await SalesAnalysisService().getMostOrderedProductIds();
      final List<Product> products = [];

      for (String productId in productIds) {
        final productData = await _productViewModel.getProductById(productId);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _bannerViewModel.addBanner(imageFile);
      Navigator.pop(context); // Dismiss loading dialog
      _fetchBanners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner added successfully')),
      );
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding banner: $e')),
      );
    }
  }

  Future<void> _updateBanner(String id, File imageFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _bannerViewModel.updateBanner(id, imageFile);
      Navigator.pop(context); // Dismiss loading dialog
      _fetchBanners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner updated successfully')),
      );
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating banner: $e')),
      );
    }
  }

  Future<void> _deleteBanner(String id) async {
    bool confirmed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Banner"),
              content:
                  const Text("Are you sure you want to delete this banner?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        await _bannerViewModel.deleteBanner(id);
        Navigator.pop(context); // Dismiss loading dialog
        _fetchBanners(); // Refresh banners
      } catch (e) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting banner: $e')),
        );
      }
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

  void _showAddBannerDialog() async {
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.photo_size_select_actual, color: Color(0xFFFFBA3B)),
              SizedBox(width: 10),
              Text("Banner Requirements"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "For the best appearance, please ensure your banner image:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRequirementRow(
                  Icons.aspect_ratio, "Resolution: 1920 x 1080 pixels (16:9)"),
              _buildRequirementRow(
                  Icons.photo_size_select_large, "Minimum width: 1200 pixels"),
              _buildRequirementRow(Icons.high_quality, "Format: JPG or PNG"),
              _buildRequirementRow(Icons.photo_library, "File size: Max 5MB"),
              const SizedBox(height: 16),
              Text(
                "Note: Images will be resized to maintain aspect ratio",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBA3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Choose Image",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );

    if (proceed == true) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        _addBanner(imageFile);
      }
    }
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

  String capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  void _showAddCategoryDialog() {
    TextEditingController _categoryController = TextEditingController();
    bool _isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBA3B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.category_outlined,
                            color: Color(0xFFFFBA3B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Add New Category",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category Name Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category Name",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            hintText: "Enter category name",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            errorText: errorMessage,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFFFBA3B)),
                            ),
                            prefixIcon: Icon(
                              Icons.edit_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (value) {
                            // Clear error message when user types
                            if (errorMessage != null) {
                              setState(() => errorMessage = null);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () async {
                                    String newCategory = capitalizeEachWord(
                                        _categoryController.text.trim());
                                    if (newCategory.isEmpty) {
                                      setState(() => errorMessage =
                                          "Category name cannot be empty");
                                      return;
                                    }

                                    if (_categories.any((category) =>
                                        category.name.toLowerCase().trim() ==
                                        newCategory.toLowerCase().trim())) {
                                      setState(() => errorMessage =
                                          "This category already exists");
                                      return;
                                    }

                                    if (newCategory.isNotEmpty) {
                                      setState(() => _isSubmitting = true);
                                      try {
                                        await _addCategory(newCategory);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Category added successfully')),
                                        );
                                      } catch (e) {
                                        setState(() => _isSubmitting = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  )
                                : const Text(
                                    "Add Category",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
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
      },
    );
  }

  void _showEditCategoryDialog(String id, String currentName) {
    TextEditingController _categoryController =
        TextEditingController(text: currentName);
    bool _isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBA3B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFFFFBA3B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Edit Category",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Current name display
                    Text(
                      "Current Name",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New name input
                    Text(
                      "New Name",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        hintText: "Enter new category name",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        errorText: errorMessage,
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFFFBA3B)),
                        ),
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        // Clear error message when user types
                        if (errorMessage != null) {
                          setState(() => errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () async {
                                    String newName = capitalizeEachWord(
                                        _categoryController.text.trim());
                                    if (newName.isEmpty) {
                                      setState(() => errorMessage =
                                          "Category name cannot be empty");
                                      return;
                                    }

                                    if (_categories.any((category) =>
                                        category.name.toLowerCase().trim() ==
                                        newName.toLowerCase().trim())) {
                                      setState(() => errorMessage =
                                          "This category already exists");
                                      return;
                                    }

                                    if (newName.isNotEmpty &&
                                        newName != currentName) {
                                      setState(() => _isSubmitting = true);
                                      try {
                                        await _updateCategory(id, newName);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Category updated successfully'),
                                          ),
                                        );
                                      } catch (e) {
                                        setState(() => _isSubmitting = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  )
                                : const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
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
      },
    );
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
                    const SizedBox(height: 5),
                    _buildSectionTitle('Categories',
                        onAdd: _showAddCategoryDialog),
                    const SizedBox(height: 16),
                    _buildCategories(),
                    _buildSectionTitle('Trending Accessories'),
                    const SizedBox(height: 16),
                    _buildTrendingProductsGrid(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search accessories...",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search, color: Color(0xFFFFBA3B), size: 22),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.grey[400], size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListingScreen(
                        category: value.trim(),
                        isSearch: true,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black12)),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Color(0xFFFFBA3B)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListingScreen(
                      category: "",
                      isSearch: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    final currentUser = Provider.of<AppUsers?>(context);
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';
    final PageController _pageController = PageController();
    // Calculate height based on 16:9 aspect ratio
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight =
        (screenWidth - 32) * 9 / 16; // 32 accounts for horizontal margins

    return Column(
      children: [
        Container(
          height: bannerHeight,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promoBanners.length,
            itemBuilder: (ctx, index) {
              final banner = _promoBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        banner.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isAdmin)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 20),
                                onPressed: () =>
                                    _showEditBannerDialog(banner.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _deleteBanner(banner.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SmoothPageIndicator(
          controller: _pageController,
          count: _promoBanners.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: const Color(0xFFFFBA3B),
            dotColor: Colors.grey[300]!,
          ),
        ),
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBA3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: _showAddBannerDialog,
              icon: const Icon(Icons.add_photo_alternate, color: Colors.black),
              label: const Text("Add Banner",
                  style: TextStyle(color: Colors.black)),
            ),
          ),
      ],
    );
  }

  Widget _buildRequirementRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFFBA3B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
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
      height: isAdmin ? 140 : 100, // Increased height for admin view
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          return Container(
            width: 85, // Fixed width for consistent spacing
            margin: EdgeInsets.only(
              left: i == 0 ? 16 : 8,
              right: i == _categories.length - 1 ? 16 : 8,
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListingScreen(
                          category: _categories[i].name,
                          isSearch: false,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBA3B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.category,
                        color: Color(0xFFFFBA3B),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _categories[i].name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit, size: 14),
                          onPressed: () => _showEditCategoryDialog(
                            _categories[i].id,
                            _categories[i].name,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete,
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _confirmDeleteCategory(_categories[i].id),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingProductsGrid() {
    if (_trendingProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.motorcycle,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Trending Accessories Available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68, // Adjusted for better content fit
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _trendingProducts.length,
        itemBuilder: (ctx, i) {
          final product = _trendingProducts[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              ctx,
              AppRoutes.productDetail,
              arguments: product,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    flex: 6, // 60% of space
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        product.images.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  // Content Section
                  Expanded(
                    flex: 3, // 30% of space
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFBA3B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.stock > 0
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.stock > 0 ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                color: product.stock > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
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
