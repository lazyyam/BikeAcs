// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, depend_on_referenced_packages, prefer_final_fields, must_be_immutable, dead_code, deprecated_member_use, avoid_print, unnecessary_nullable_for_final_variable_declarations

import 'dart:io';

import 'package:BikeAcs/pages/cart/cart_view_model.dart';
import 'package:BikeAcs/pages/home/home_category_view_model.dart';
import 'package:BikeAcs/pages/reviews/review_model.dart';
import 'package:BikeAcs/pages/reviews/review_screen.dart';
import 'package:BikeAcs/pages/reviews/review_view_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../appUsers/users.dart';
import 'product_model.dart';
import 'product_view_model.dart';

class ProductDetailScreen extends StatefulWidget {
  Product? product; // Allow null for adding new products
  ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetailScreen> {
  final ProductViewModel _productViewModel = ProductViewModel();
  final HomeCategoryViewModel _categoryViewModel = HomeCategoryViewModel();
  final ReviewViewModel _reviewViewModel = ReviewViewModel();
  final CartViewModel _cartViewModel = CartViewModel();
  int quantity = 1;
  final PageController _imageController = PageController();
  late bool isAdmin;
  bool isLoading = false;
  bool _isRefreshing = false;

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  // Selected category
  String _selectedCategory = 'Select Category';

  // Categories fetched from Firebase
  List<String> _categories = ['Select Category']; // Default placeholder

  List<File> _selectedImages = [];
  File? _selected3DModel;

  bool enableColor = false;
  bool enableSize = false;

  List<String> selectedColors = [];
  List<String> selectedSizes = [];

  List<String> predefinedColors = [];
  List<String> predefinedSizes = [];

  List<String> _tempDeletedImages = []; // Track images marked for deletion
  List<String> _originalImages = []; // Backup of original images

  Map<String, int> _variantStock = {}; // Track variant-specific stock

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories from Firebase
    if (widget.product != null) {
      _originalImages =
          List.from(widget.product!.images); // Backup original images
      _variantStock =
          Map.from(widget.product!.variantStock); // Load variant stock
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUser = Provider.of<AppUsers?>(context);
    isAdmin = currentUser?.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';
    _restoreOriginalImages(); // Restore images when re-entering the page

    // Call _refreshProductDetail here to ensure BuildContext is valid
    if (!_isRefreshing) {
      _isRefreshing = true; // Prevent multiple calls
      _refreshProductDetail().then((_) {
        setState(() {
          _isRefreshing = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _initializeProductData() {
    // Initialize with existing product data if available
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _descriptionController.text = widget.product!.description;
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category;
      quantity = widget.product!.stock;

      // Initialize colors and sizes if available
      if (widget.product!.colors.isNotEmpty) {
        enableColor = true;
        selectedColors = List.from(widget.product!.colors);
      }

      if (widget.product!.sizes.isNotEmpty) {
        enableSize = true;
        selectedSizes = List.from(widget.product!.sizes);
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories = await _categoryViewModel.fetchCategories();
      final categoryNames = fetchedCategories
          .map((category) => category.name)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _categories = ['Select Category', ...categoryNames];

        // If current selected category is not in the list, reset it
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'Select Category';
        }
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // Function to delete the 3D model
  Future<void> _delete3DModel() async {
    if (widget.product?.arModelUrl != null &&
        widget.product!.arModelUrl!.isNotEmpty) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        await FirebaseStorage.instance
            .refFromURL(widget.product!.arModelUrl!)
            .delete();

        await _productViewModel.update3DModelUrl(widget.product!.id, null);

        setState(() {
          widget.product = widget.product!.copyWith(arModelUrl: null);
          _selected3DModel = null;
        });

        // Force reload product details
        await _refreshProductDetail();

        Navigator.pop(context); // Dismiss loading dialog
        _showSuccessDialog(context, "3D model deleted successfully.");
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog(context, "Error deleting 3D model: ${e.toString()}");
      }
    }
  }

  // Save or update product
  Future<void> _saveProduct() async {
    if (!_validateInputs()) return;

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      List<String> imageUrls = widget.product?.images ?? [];
      String? arModelUrl = widget.product?.arModelUrl;

      if (_selectedImages.isNotEmpty) {
        // Delete old images from Firebase Storage if they exist
        // for (String oldImageUrl in imageUrls) {
        //   await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
        // }
        imageUrls = await Future.wait(
          _selectedImages
              .map((image) => _productViewModel.uploadImageToStorage(image)),
        );
      }

      if (_selected3DModel != null) {
        if (arModelUrl != null && arModelUrl.isNotEmpty) {
          await _productViewModel.delete3DModel(arModelUrl);
        }
        arModelUrl =
            await _productViewModel.upload3DModelToStorage(_selected3DModel!);
      }

      if (imageUrls.isEmpty) {
        _showErrorDialog(context, "Please upload at least one product image.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Handle variant stock cleanup and updates
      Map<String, int> updatedVariantStock = {};
      if (enableColor && enableSize) {
        for (String color in selectedColors) {
          for (String size in selectedSizes) {
            final key = '$color-$size';
            updatedVariantStock[key] = _variantStock[key] ?? 0;
          }
        }
      } else if (enableColor) {
        for (String color in selectedColors) {
          updatedVariantStock[color] = _variantStock[color] ?? 0;
        }
        // Reset all size-based variants to 0 in UI
        setState(() {
          _variantStock.keys
              .where((key) => key.contains('-'))
              .forEach((key) => _variantStock[key] = 0);
        });
      } else if (enableSize) {
        for (String size in selectedSizes) {
          updatedVariantStock[size] = _variantStock[size] ?? 0;
        }
        // Reset all color-based variants to 0 in UI
        setState(() {
          _variantStock.keys
              .where((key) => key.contains('-'))
              .forEach((key) => _variantStock[key] = 0);
        });
      } else {
        // Allow manual adjustment of stock if both are disabled
        updatedVariantStock.clear();
      }

      // Calculate total stock from variant stocks if enabled
      final int totalStock = (enableColor || enableSize)
          ? updatedVariantStock.values.fold(0, (sum, qty) => sum + qty)
          : int.tryParse(_stockController.text) ?? 0;

      final updatedProduct = widget.product != null
          ? widget.product!.copyWith(
              name: capitalizeEachWord(_nameController.text.trim()),
              price: double.tryParse(_priceController.text) ?? 0.0,
              images: imageUrls,
              category: _selectedCategory,
              description: _descriptionController.text.trim(),
              stock: totalStock,
              arModelUrl: arModelUrl,
              colors: enableColor ? selectedColors : [],
              sizes: enableSize ? selectedSizes : [],
              variantStock: updatedVariantStock,
            )
          : Product(
              id: '', // Use an empty string; the firebase will generate the ID
              name: capitalizeEachWord(_nameController.text.trim()),
              price: double.tryParse(_priceController.text) ?? 0.0,
              images: imageUrls,
              category: _selectedCategory,
              description: _descriptionController.text.trim(),
              stock: totalStock,
              arModelUrl: arModelUrl,
              colors: enableColor ? selectedColors : [],
              sizes: enableSize ? selectedSizes : [],
              variantStock: updatedVariantStock,
            );

      await _productViewModel.saveProduct(
          widget.product, updatedProduct, enableColor, enableSize);

      _showSuccessDialog(
        context,
        widget.product == null
            ? "Product created successfully."
            : "Product updated successfully.",
      );

      // Force reload product details
      if (widget.product != null) {
        await _refreshProductDetail();
      } else {
        // If it's a new product
        // Clear all fields for new product
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _stockController.clear();
        setState(() {
          _selectedCategory = 'Select Category';
          _selectedImages.clear();
          _selected3DModel = null;
          selectedColors.clear();
          selectedSizes.clear();
          _variantStock.clear();
          enableColor = false;
          enableSize = false;
        });
      }
    } catch (e) {
      _showErrorDialog(context, "Error saving product: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Delete product
  Future<void> _deleteProduct() async {
    if (widget.product == null) return;

    final bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
                'Are you sure you want to delete this product? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    setState(() => isLoading = true);

    try {
      await _productViewModel.deleteProduct(
        widget.product!.id,
        widget.product!.images,
        widget.product!.arModelUrl,
      );

      await _cartViewModel.deleteCartItemsWithProduct(widget.product!.id);

      // Then navigate back
      Navigator.pop(context);
    } catch (e) {
      _showErrorDialog(context, "Error deleting product: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshProductDetail() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Clear all existing data
      _selectedImages = [];
      _selected3DModel = null;

      final updatedProduct =
          await _productViewModel.refreshProductDetail(widget.product!.id);
      if (updatedProduct != null) {
        setState(() {
          widget.product = updatedProduct;
          _initializeProductData();
        });
      }
    } catch (e) {
      print('Error refreshing product: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add this function inside the class before build()
  Future<Map<String, dynamic>> _getReviewStats(String productId) async {
    try {
      final List<ReviewItem> reviews =
          await _reviewViewModel.getReviews(productId);
      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
        };
      }

      double totalRating = 0;
      for (var review in reviews) {
        totalRating += review.rating;
      }

      return {
        'averageRating': totalRating / reviews.length,
        'totalReviews': reviews.length,
      };
    } catch (e) {
      print('Error fetching review stats: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
      };
    }
  }

  // Validate form inputs
  bool _validateInputs() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog(context, "Product name is required.");
      return false;
    }

    final price = double.tryParse(priceText);
    if (priceText.isEmpty || price == null) {
      _showErrorDialog(context, "Please enter a valid price.");
      return false;
    } else if (price <= 0) {
      _showErrorDialog(context, "Price must be greater than zero.");
      return false;
    }

    final stock = int.tryParse(stockText);
    if (stockText.isEmpty || stock == null) {
      _showErrorDialog(context, "Please enter a valid stock amount.");
      return false;
    } else if (stock < 0) {
      _showErrorDialog(context, "Stock cannot be negative.");
      return false;
    }

    if (_selectedCategory == 'Select Category') {
      _showErrorDialog(context, "Please select a category.");
      return false;
    }

    return true;
  }

  String capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  // 📌 PICK MULTIPLE IMAGES FROM GALLERY
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  // 📌 DELETE IMAGE (ADMIN ONLY)
  void _deleteImage(int index) {
    setState(() {
      if (_selectedImages.isNotEmpty) {
        _selectedImages.removeAt(index);
      } else if (widget.product?.images != null &&
          widget.product!.images.isNotEmpty) {
        // _tempDeletedImages.add(widget.product!.images[index]);  // Delete the image from Firebase Storage (during update)
        widget.product!.images.removeAt(index);
      }
    });
  }

  // 📌 RESTORE ORIGINAL IMAGES ON PAGE RE-ENTRY
  void _restoreOriginalImages() {
    if (widget.product != null) {
      setState(() {
        widget.product!.images = List.from(_originalImages);
        _tempDeletedImages.clear();
      });
    }
  }

  // 3D Model Picker
  Future<void> _pick3DModel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Use FileType.any to avoid unsupported filter errors
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;

      // Ensure the selected file has a valid 3D model extension
      if (filePath.endsWith('.glb')) {
        setState(() {
          _selected3DModel = File(filePath);
        });
      } else {
        // Show an error if the file type is not supported
        _showErrorDialog(context, "Please select a .glb file.");
      }
    }
  }

  Color? _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'amber':
        return Colors.amber;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'light blue':
        return Colors.lightBlue;
      case 'light green':
        return Colors.lightGreen;
      case 'deep orange':
        return Colors.deepOrange;
      case 'deep purple':
        return Colors.deepPurple;
      case 'gold':
      case 'metallic gold':
        return Colors.amberAccent;
      case 'silver':
        return Colors.blueGrey;
      case 'beige':
        return Colors.brown[100]!;
      case 'maroon':
        return Colors.red[900]!;
      case 'olive':
        return Colors.green[800]!;
      case 'navy':
        return Colors.blue[900]!;
      case 'turquoise':
        return Colors.cyan[400]!;
      case 'goldenrod':
        return Colors.amber;
      case 'khaki':
        return Colors.yellow[200]!;
      case 'coral':
        return Colors.deepOrange[200]!;
      case 'salmon':
        return Colors.pink[200]!;
      case 'chocolate':
        return Colors.brown[600]!;
      case 'plum':
        return Colors.purple[200]!;
      case 'orchid':
        return Colors.purple[300]!;
      case 'lavender':
        return Colors.purple[100]!;
      case 'peach':
        return Colors.orange[200]!;
      case 'mint':
        return Colors.green[200]!;
      case 'mustard':
        return Colors.yellow[700]!;
      case 'charcoal':
        return Colors.grey[800]!;
      case 'ivory':
        return Colors.grey[50]!;
      case 'sand':
        return Colors.brown[300]!;
      case 'rose':
        return Colors.pink[400]!;
      case 'wine':
        return Colors.red[800]!;
      case 'emerald':
        return Colors.green[600]!;
      case 'jade':
        return Colors.green[700]!;
      case 'sapphire':
        return Colors.blue[800]!;
      case 'ruby':
        return Colors.red[700]!;
      case 'amethyst':
        return Colors.purple[700]!;
      default:
        return null;
    }
  }

  void _addCustomColor() {
    TextEditingController colorController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                        child: const Icon(Icons.palette_outlined,
                            color: Color(0xFFFFBA3B), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Add New Color",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 24),

                  // Color Input with Error Message
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Color Name",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: colorController,
                        decoration: InputDecoration(
                          hintText: "e.g., Red, Blue, Green",
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
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
                          prefixIcon: Icon(Icons.color_lens_outlined,
                              color: Colors.grey[600], size: 20),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          // Clear error message when user types
                          if (errorMessage != null) {
                            setDialogState(() => errorMessage = null);
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
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  String newColor = colorController.text.trim();

                                  // Validation checks
                                  if (newColor.isEmpty) {
                                    setDialogState(() => errorMessage =
                                        "Color name cannot be empty");
                                    return;
                                  }

                                  if (selectedColors.contains(newColor)) {
                                    setDialogState(() => errorMessage =
                                        "This color already exists");
                                    return;
                                  }

                                  if (_getColorFromName(newColor) == null) {
                                    setDialogState(() => errorMessage =
                                        "Please enter a valid color name");
                                    return;
                                  }

                                  // If all validation passes, add the color
                                  setState(() {
                                    selectedColors.add(newColor);
                                  });
                                  Navigator.pop(dialogContext);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFBA3B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Add Color",
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
      ),
    );
  }

  void _addCustomSize() {
    TextEditingController sizeController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                          Icons.straighten,
                          color: Color(0xFFFFBA3B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Add New Size",
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
                  const SizedBox(height: 24),

                  // Size Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Size Label",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sizeController,
                        decoration: InputDecoration(
                          hintText: "e.g., S, M, L, or any custom size",
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
                            Icons.format_size,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          // Clear error message when user types
                          if (errorMessage != null) {
                            setDialogState(() => errorMessage = null);
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
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  // Validation checks
                                  String newSize =
                                      sizeController.text.trim().toUpperCase();
                                  if (newSize.isEmpty) {
                                    setDialogState(() =>
                                        errorMessage = "Size cannot be empty");
                                    return;
                                  }

                                  if (selectedSizes.contains(newSize)) {
                                    setDialogState(() => errorMessage =
                                        "This size already exists");
                                    return;
                                  }

                                  if (newSize.isNotEmpty) {
                                    // Update the parent widget's state instead of dialog state
                                    setState(() {
                                      selectedSizes.add(newSize);
                                    });
                                    Navigator.pop(dialogContext);
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
                          child: const Text(
                            "Add Size",
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
      ),
    );
  }

  // Function for show add to cart option
  void _showAddToCartModal(BuildContext context) {
    String? selectedColor;
    String? selectedSize;
    int quantity = 1;
    bool isLoading = false; // Add loading state

    final List<String> colors = widget.product?.colors ?? [];
    final List<String> sizes = widget.product?.sizes ?? [];
    final Map<String, int> variantStock = widget.product?.variantStock ?? {};

    int getVariantStock() {
      if (selectedColor != null && selectedSize != null) {
        return variantStock['$selectedColor-$selectedSize'] ?? 0;
      } else if (selectedColor != null) {
        return variantStock[selectedColor] ?? 0;
      } else if (selectedSize != null) {
        return variantStock[selectedSize] ?? 0;
      }
      return widget.product?.stock ?? 0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Summary Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product?.images.first ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product?.name ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM${widget.product?.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFBA3B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Options Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color Selection
                        if (colors.isNotEmpty) ...[
                          const Text(
                            'Select Color',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: colors.map((color) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedColor = color;
                                        quantity = 1;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedColor == color
                                            ? const Color(0xFFFFBA3B)
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selectedColor == color
                                              ? const Color(0xFFFFBA3B)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        color,
                                        style: TextStyle(
                                          color: selectedColor == color
                                              ? Colors.black
                                              : Colors.grey[700],
                                          fontWeight: selectedColor == color
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Size Selection
                        if (sizes.isNotEmpty) ...[
                          const Text(
                            'Select Size',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: sizes.map((size) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedSize = size;
                                        quantity = 1;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedSize == size
                                            ? const Color(0xFFFFBA3B)
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selectedSize == size
                                              ? const Color(0xFFFFBA3B)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          color: selectedSize == size
                                              ? Colors.black
                                              : Colors.grey[700],
                                          fontWeight: selectedSize == size
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Stock Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Available Stock: ${getVariantStock()}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quantity Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() => quantity--);
                                      }
                                    },
                                    color: const Color(0xFFFFBA3B),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        horizontal: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (quantity < getVariantStock()) {
                                        setState(() => quantity++);
                                      }
                                    },
                                    color: const Color(0xFFFFBA3B),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Total Price and Add to Cart Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'RM${(widget.product?.price ?? 0 * quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFBA3B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (colors.isEmpty ||
                                          selectedColor != null) &&
                                      (sizes.isEmpty || selectedSize != null)
                                  ? const Color(0xFFFFBA3B)
                                  : Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : (colors.isEmpty || selectedColor != null) &&
                                        (sizes.isEmpty || selectedSize != null)
                                    ? () async {
                                        if (quantity > getVariantStock()) {
                                          _showErrorDialog(
                                            context,
                                            "Cannot add more than ${getVariantStock()} items to the cart.",
                                          );
                                          return;
                                        }

                                        final currentUser =
                                            Provider.of<AppUsers?>(context,
                                                listen: false);
                                        if (currentUser == null) return;

                                        final cartItem = {
                                          'productId': widget.product!.id,
                                          'name': widget.product!.name,
                                          'price': widget.product!.price,
                                          'image': widget.product!.images.first,
                                          'color': selectedColor,
                                          'size': selectedSize,
                                          'quantity': quantity,
                                        };

                                        setState(() {
                                          isLoading = true; // Show loading
                                        });

                                        try {
                                          await _cartViewModel.addToCart(
                                            currentUser.uid,
                                            cartItem,
                                            getVariantStock(), // Pass the available stock
                                          );
                                          Navigator.pop(context); // Close modal
                                          _showSuccessDialog(context,
                                              "Added to cart successfully!");
                                        } catch (e) {
                                          _showErrorDialog(
                                              context, e.toString());
                                        } finally {
                                          setState(() {
                                            isLoading = false; // Hide loading
                                          });
                                        }
                                      }
                                    : null,
                            child: isLoading
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
                                    'Add to Cart',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
        // Ensure the preceding code block is complete
        // Example: Add missing logic or close any open brackets
        // Correct the code above this line if necessary
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.product == null ? 'Create Accessory' : '',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          if (!isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.black),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ],
          if (isAdmin && widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          heroTag: 'productDetailARButton',
          backgroundColor: const Color(0xFFFFBA3B),
          child: const Icon(Icons.view_in_ar, color: Colors.black),
          onPressed: () {
            final arModelUrl = widget.product?.arModelUrl;
            final colors = widget.product?.colors ?? [];
            if (arModelUrl != null && arModelUrl.isNotEmpty) {
              Navigator.pushNamed(
                context,
                AppRoutes.arView,
                arguments: {
                  'arModelUrl': arModelUrl,
                  'colors': colors,
                },
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No AR model available')),
              );
            }
          },
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshProductDetail,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Image Gallery
                      GestureDetector(
                        onTap: () {},
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 350,
                              child: PageView.builder(
                                controller: _imageController,
                                itemCount: _selectedImages.isNotEmpty
                                    ? _selectedImages.length
                                    : (widget.product?.images.length ?? 1),
                                itemBuilder: (context, index) {
                                  Widget imageWidget;

                                  if (_selectedImages.isNotEmpty) {
                                    imageWidget = GestureDetector(
                                      onTap: () => _viewFullImage(
                                          context, _selectedImages[index]),
                                      child: Image.file(
                                        _selectedImages[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    );
                                  } else if (widget.product?.images != null &&
                                      widget.product!.images.isNotEmpty) {
                                    imageWidget = GestureDetector(
                                      onTap: () => _viewFullImage(context,
                                          widget.product!.images[index]),
                                      child: Image.network(
                                        widget.product!.images[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    );
                                  } else {
                                    imageWidget = Container(
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image,
                                          size: 100, color: Colors.grey),
                                    );
                                  }

                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      imageWidget,
                                      if (isAdmin)
                                        Positioned(
                                          top: 16,
                                          right: 16,
                                          child: GestureDetector(
                                            onTap: () => _deleteImage(index),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFFBA3B),
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(Icons.close,
                                                  color: Colors.black,
                                                  size: 20),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            // Add Upload Image button for admin
                            if (isAdmin)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFBA3B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: _pickImages,
                                    icon: const Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.black,
                                    ),
                                    tooltip: 'Upload Images',
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SmoothPageIndicator(
                                    controller: _imageController,
                                    count: (_selectedImages.isNotEmpty
                                            ? _selectedImages.length
                                            : (widget.product?.images.length ??
                                                0))
                                        .clamp(1, 100),
                                    effect: WormEffect(
                                      dotHeight: 8,
                                      dotWidth: 8,
                                      activeDotColor: const Color(0xFFFFBA3B),
                                      dotColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Product Info Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isAdmin) ...[
                              Text(
                                widget.product?.name ?? "Unknown Product",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'RM${widget.product?.price.toStringAsFixed(2) ?? "0.00"}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFBA3B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${widget.product?.stock ?? 0} left',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Admin editing fields
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    // Basic Info Header
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined,
                                              color: Colors.grey[600],
                                              size: 20),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Basic Information",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Product Name
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      size: 18,
                                                      color: Colors.grey[600]),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    "Product Name",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    " *",
                                                    style: TextStyle(
                                                        color: Colors.red[400],
                                                        fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _nameController,
                                                style: const TextStyle(
                                                    fontSize: 15),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      "Enter product name",
                                                  hintStyle: TextStyle(
                                                      color: Colors.grey[400]),
                                                  filled: true,
                                                  fillColor: Colors.grey[50],
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: Color(
                                                                0xFFFFBA3B)),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 12),
                                                ),
                                                textCapitalization:
                                                    TextCapitalization.words,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // Price & Stock Row
                                          Row(
                                            children: [
                                              // Price Field
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .monetization_on_outlined,
                                                            size: 18,
                                                            color: Colors
                                                                .grey[600]),
                                                        const SizedBox(
                                                            width: 8),
                                                        const Text(
                                                          "Price (RM)",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        Text(
                                                          " *",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .red[400],
                                                              fontSize: 14),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextFormField(
                                                      controller:
                                                          _priceController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      style: const TextStyle(
                                                          fontSize: 15),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "0.00",
                                                        hintStyle: TextStyle(
                                                            color: Colors
                                                                .grey[400]),
                                                        prefixText: "RM ",
                                                        filled: true,
                                                        fillColor:
                                                            Colors.grey[50],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]!),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]!),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Color(
                                                                      0xFFFFBA3B)),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Stock Field
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .inventory_2_outlined,
                                                            size: 18,
                                                            color: Colors
                                                                .grey[600]),
                                                        const SizedBox(
                                                            width: 8),
                                                        const Text(
                                                          "Stock",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        if (!enableColor &&
                                                            !enableSize)
                                                          Text(
                                                            " *",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red[400],
                                                                fontSize: 14),
                                                          ),
                                                        if (enableColor ||
                                                            enableSize) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .amber[50],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                              border: Border.all(
                                                                  color: const Color(
                                                                      0xFFFFBA3B)),
                                                            ),
                                                            child: Text(
                                                              'Variant Mode',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .amber[800],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextFormField(
                                                      controller:
                                                          _stockController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      enabled: !(enableColor ||
                                                          enableSize),
                                                      style: const TextStyle(
                                                          fontSize: 15),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText:
                                                            "Enter quantity",
                                                        hintStyle: TextStyle(
                                                            color: Colors
                                                                .grey[400]),
                                                        filled: true,
                                                        fillColor:
                                                            enableColor ||
                                                                    enableSize
                                                                ? Colors
                                                                    .grey[100]
                                                                : Colors
                                                                    .grey[50],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]!),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                          .grey[
                                                                      300]!),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Color(
                                                                      0xFFFFBA3B)),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Divider with spacing
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: Colors.grey[300]),
                            ),
                            // Delivery Info Section (Customer View)
                            if (!isAdmin) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.local_shipping,
                                            color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Standard Delivery: 3-5 working days',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Description Section
                            Container(
                              margin: const EdgeInsets.only(top: 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  // Description Header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.description_outlined,
                                            color: Colors.grey[600], size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Product Description",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Description Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isAdmin)
                                          TextFormField(
                                            controller: _descriptionController,
                                            maxLines: 8,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Describe your product in detail...',
                                              hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: Color(0xFFFFBA3B)),
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              contentPadding:
                                                  const EdgeInsets.all(16),
                                            ),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          )
                                        else if (widget.product?.description
                                                .isNotEmpty ??
                                            false)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.grey[200]!),
                                                ),
                                                child: Text(
                                                  widget.product?.description ??
                                                      '',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.5,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ),
                                              if (isAdmin)
                                                const SizedBox(height: 16),
                                            ],
                                          )
                                        else
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[200]!),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.info_outline,
                                                    size: 16,
                                                    color: Colors.grey[400]),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'No description available',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Reviews Section
                            if (widget.product != null)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    // Reviews Header
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star_rounded,
                                              color: Colors.amber[600],
                                              size: 24),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Product Reviews",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Reviews Preview with real data
                                    FutureBuilder<Map<String, dynamic>>(
                                      future:
                                          _getReviewStats(widget.product!.id),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xFFFFBA3B)),
                                              ),
                                            ),
                                          );
                                        }

                                        final stats = snapshot.data ??
                                            {
                                              'averageRating': 0.0,
                                              'totalReviews': 0
                                            };
                                        final averageRating =
                                            (stats['averageRating'] as double)
                                                .toStringAsFixed(1);
                                        final totalReviews =
                                            stats['totalReviews'] as int;

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ReviewScreen(
                                                  productId: widget.product!.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        averageRating,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.amber[700],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.star,
                                                        size: 18,
                                                        color:
                                                            Colors.amber[700],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Based on $totalReviews reviews",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Tap to read all reviews",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Arrow Icon
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Colors.grey[400],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            // Category Selector for Admin
                            if (isAdmin)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.category_outlined,
                                              color: Colors.grey[600],
                                              size: 20),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Product Category",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: DropdownButtonFormField<String>(
                                        value: _categories
                                                .contains(_selectedCategory)
                                            ? _selectedCategory
                                            : null,
                                        decoration: InputDecoration(
                                          hintText: "Select a category",
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          prefixIcon: Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.grey[600],
                                              size: 20),
                                        ),
                                        icon: Icon(Icons.arrow_drop_down,
                                            color: Colors.grey[600]),
                                        items: _categories.map((category) {
                                          return DropdownMenuItem(
                                            value: category,
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                color: category ==
                                                        'Select Category'
                                                    ? Colors.grey[600]
                                                    : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (selectedCategory) {
                                          setState(() {
                                            _selectedCategory =
                                                selectedCategory!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 3D Model Upload (Admin Only)
                      if (isAdmin)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.view_in_ar,
                                        color: Colors.grey[600], size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "3D Model Preview",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Upload Section
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.file_upload_outlined,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            "Upload your 3D model file",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Supports .glb format only",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFFBA3B),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: _pick3DModel,
                                            icon: const Icon(
                                                Icons.add_box_outlined,
                                                size: 18,
                                                color: Colors.black),
                                            label: const Text(
                                              'Choose File',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selected3DModel != null ||
                                        (widget.product?.arModelUrl != null &&
                                            widget.product!.arModelUrl!
                                                .isNotEmpty))
                                      Container(
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFBA3B)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.file_present,
                                                color: Color(0xFFFFBA3B)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _selected3DModel != null
                                                    ? _selected3DModel!.path
                                                        .split('/')
                                                        .last
                                                    : widget
                                                        .product!.arModelUrl!
                                                        .split('/')
                                                        .last,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (widget.product?.arModelUrl !=
                                                    null &&
                                                widget.product!.arModelUrl!
                                                    .isNotEmpty)
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: 20),
                                                onPressed: _delete3DModel,
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Color and Size Selection for Admin
                      if (isAdmin)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   "Add Color or Size",
                              //   style: TextStyle(
                              //       fontSize: 16, fontWeight: FontWeight.bold),
                              // ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SwitchListTile(
                                    title: const Text("Enable Color Selection"),
                                    value: enableColor,
                                    onChanged: (value) =>
                                        setState(() => enableColor = value),
                                  ),
                                  if (enableColor) _buildColorSelection(),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SwitchListTile(
                                    title: const Text("Enable Size Selection"),
                                    value: enableSize,
                                    onChanged: (value) {
                                      setState(() => enableSize = value);
                                    },
                                  ),
                                  if (enableSize) _buildSizeSelection(),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Stock editor for variants
                      if (isAdmin && (enableColor || enableSize))
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   "Set Stock for Variants",
                              //   style: TextStyle(
                              //       fontSize: 16, fontWeight: FontWeight.bold),
                              // ),
                              // const SizedBox(height: 10),
                              _buildVariantStockEditor(),
                            ],
                          ),
                        ),

                      const SizedBox(height: 130), // Space for bottom buttons
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isAdmin)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.product?.stock == 0
                                  ? Colors.grey[300]
                                  : const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: widget.product?.stock == 0
                                ? null
                                : () => _showAddToCartModal(context),
                            child: Text(
                              widget.product?.stock == 0
                                  ? 'Out of Stock'
                                  : 'Add to Cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.product?.stock == 0
                                    ? Colors.grey[600]
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading ? null : _saveProduct,
                            child: Text(
                              widget.product == null
                                  ? 'Add Product'
                                  : 'Update Product',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFBA3B)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context, dynamic imageSource) {
    if (imageSource is File) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.file(imageSource),
              ),
            ),
          ),
        ),
      );
    } else if (imageSource is String && imageSource.startsWith('http')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.network(imageSource),
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image source')),
      );
    }
  }

  Widget _buildColorSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined,
                      color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Available Colors",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBA3B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _addCustomColor,
                icon: const Icon(Icons.add, size: 18, color: Colors.black),
                label: const Text(
                  'Add Color',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedColors.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                'No colors added yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedColors.map((color) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IntrinsicWidth(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text(
                            color,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(color: Colors.grey[200]!)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.close,
                                size: 16, color: Colors.grey[600]),
                            onPressed: () =>
                                setState(() => selectedColors.remove(color)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.straighten, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Available Sizes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBA3B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _addCustomSize,
                icon: const Icon(Icons.add, size: 18, color: Colors.black),
                label: const Text(
                  'Add Size',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedSizes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                'No sizes added yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedSizes.map((size) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IntrinsicWidth(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text(
                            size,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(color: Colors.grey[200]!)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.close,
                                size: 16, color: Colors.grey[600]),
                            onPressed: () =>
                                setState(() => selectedSizes.remove(size)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Function to build the variant stock editor
  Widget _buildVariantStockEditor() {
    List<String> variants = [];

    if (enableColor && enableSize) {
      for (String color in selectedColors) {
        for (String size in selectedSizes) {
          variants.add('$color-$size');
        }
      }
    } else if (enableColor) {
      variants.addAll(selectedColors);
    } else if (enableSize) {
      variants.addAll(selectedSizes);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Variant Stock Management",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Variant List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: variants.length,
            itemBuilder: (context, index) {
              final variant = variants[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == variants.length - 1
                          ? Colors.transparent
                          : Colors.grey[200]!,
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Variant Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            variant,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            enableColor && enableSize
                                ? 'Color-Size Variant'
                                : enableColor
                                    ? 'Color Variant'
                                    : 'Size Variant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stock Input
                    Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Decrease Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                int currentStock = _variantStock[variant] ?? 0;
                                if (currentStock > 0) {
                                  setState(() {
                                    _variantStock[variant] = currentStock - 1;
                                  });
                                }
                              },
                              child: Container(
                                width: 32,
                                height: 40,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: Color(0xFFFFBA3B),
                                ),
                              ),
                            ),
                          ),
                          // Stock Input
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              (_variantStock[variant] ?? 0).toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Increase Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                int currentStock = _variantStock[variant] ?? 0;
                                setState(() {
                                  _variantStock[variant] = currentStock + 1;
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 40,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Color(0xFFFFBA3B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Total Stock Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Stock:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _variantStock.values
                      .fold(0, (sum, qty) => sum + qty)
                      .toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFBA3B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
