// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, depend_on_referenced_packages, prefer_final_fields

import 'dart:io';

import 'package:BikeAcs/home.dart';
import 'package:BikeAcs/pages/ar/ar_view.dart';
import 'package:BikeAcs/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:uuid/uuid.dart';

import '../../models/users.dart';
import '../../services/cart_database.dart';
import '../../services/home_category_database.dart';
import '../../services/product_database.dart';
import 'product_model.dart';

class ProductDetail extends StatefulWidget {
  final Product? product; // Allow null for adding new products
  const ProductDetail({super.key, this.product});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  int quantity = 1;
  final PageController _imageController = PageController();
  bool _isAccessoriesExpanded = true;
  late bool isAdmin;
  bool isLoading = false;

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  // Selected category
  String _selectedCategory = 'Select Category';

  // Product database reference
  final ProductDatabase _productDB = ProductDatabase();
  final HomeCategoryDatabase _categoryDatabase = HomeCategoryDatabase();
  final CartDatabase _cartDatabase = CartDatabase();
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

  @override
  void initState() {
    super.initState();
    _initializeProductData();
    _fetchCategories(); // Fetch categories from Firebase
    if (widget.product != null) {
      _originalImages =
          List.from(widget.product!.images); // Backup original images
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories = await _categoryDatabase.fetchCategories();
      final categoryNames = fetchedCategories
          .map((category) => category['name'] ?? '')
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUser = Provider.of<AppUsers?>(context);
    isAdmin = currentUser?.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';
    _restoreOriginalImages(); // Restore images when re-entering the page
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

  // Upload image to Firebase Storage
  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload 3D model to Firebase Storage
  Future<String> _upload3DModelToStorage(File modelFile) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.glb';
      final Reference ref =
          FirebaseStorage.instance.ref().child('ar_models').child(fileName);

      final UploadTask uploadTask = ref.putFile(modelFile);
      final TaskSnapshot taskSnapshot = await uploadTask;

      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload 3D model: $e');
    }
  }

  // Save or update product
  Future<void> _saveProduct() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<String> imageUrls = widget.product?.images ?? [];
      String? arModelUrl = widget.product?.arModelUrl;

      // Upload new images if selected
      if (_selectedImages.isNotEmpty) {
        for (File image in _selectedImages) {
          imageUrls.add(await _uploadImageToStorage(image));
        }
      }

      // Remove images marked for deletion
      for (String deletedImage in _tempDeletedImages) {
        imageUrls.remove(deletedImage);
        await FirebaseStorage.instance.refFromURL(deletedImage).delete();
      }

      // Upload new 3D model if selected
      if (_selected3DModel != null) {
        arModelUrl = await _upload3DModelToStorage(_selected3DModel!);
      }

      // Parse input values
      final String name = _nameController.text.trim();
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final String description = _descriptionController.text.trim();
      final int stock = int.tryParse(_stockController.text) ?? quantity;

      // Use selected colors and sizes
      final List<String> colors = enableColor ? selectedColors : [];
      final List<String> sizes = enableSize ? selectedSizes : [];

      if (widget.product == null) {
        // Create new product
        final newProduct = Product(
          id: '', // Will be set by Firestore
          name: name,
          price: price,
          images: imageUrls,
          category: _selectedCategory,
          description: description,
          stock: stock,
          noOfRecord: 0,
          arModelUrl: arModelUrl,
          colors: colors,
          sizes: sizes,
        );

        final docId = await _productDB.addProduct(newProduct);
        if (docId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created successfully')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Home()),
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          name: name,
          price: price,
          images: imageUrls,
          category: _selectedCategory,
          description: description,
          stock: stock,
          arModelUrl: arModelUrl,
          colors: colors,
          sizes: sizes,
        );

        await _productDB.setProduct(updatedProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }

      // Clear temporary deleted images after saving
      _tempDeletedImages.clear();
      _originalImages = List.from(imageUrls); // Update backup with saved images
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Delete product
  Future<void> _deleteProduct() async {
    if (widget.product == null) return;

    // Show confirmation dialog
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

    setState(() {
      isLoading = true;
    });

    try {
      await _productDB.deleteProduct(widget.product!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Validate form inputs
  bool _validateInputs() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name is required')),
      );
      return false;
    }

    if (_priceController.text.trim().isEmpty ||
        double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return false;
    }

    if (_selectedCategory == 'Select Category') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return false;
    }

    return true;
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
        _tempDeletedImages.add(widget.product!.images[index]);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a .glb file")),
        );
      }
    }
  }

  // Function to pick colors
  void _addCustomColor() {
    String newColor = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Color Name"),
        content: TextField(
          onChanged: (value) {
            newColor = value;
          },
          decoration: const InputDecoration(
            hintText: "e.g., Red, Blue, Metallic Gold",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (newColor.isNotEmpty) {
                setState(() {
                  selectedColors.add(newColor);
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Function to add a custom size
  void _addCustomSize() {
    TextEditingController sizeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Custom Size"),
        content: TextField(
          controller: sizeController,
          decoration: const InputDecoration(hintText: "Enter size (e.g., XXL)"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (sizeController.text.isNotEmpty) {
                setState(() {
                  selectedSizes.add(sizeController.text.toUpperCase());
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Function for show add to cart option
  void _showAddToCartModal(BuildContext context) {
    String? selectedColor;
    String? selectedSize;
    int quantity = 1;

    // Fetch colors and sizes dynamically
    final List<String> colors = widget.product?.colors ?? [];
    final List<String> sizes = widget.product?.sizes ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full-screen modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text("Select Options",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),

                  // Color Selector
                  if (colors.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      decoration: const InputDecoration(
                        labelText: "Select Color",
                        border: OutlineInputBorder(),
                      ),
                      items: colors.map((color) {
                        return DropdownMenuItem(
                            value: color, child: Text(color));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedColor = value);
                      },
                    ),

                  const SizedBox(height: 15),

                  // Size Selector
                  if (sizes.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedSize,
                      decoration: const InputDecoration(
                        labelText: "Select Size",
                        border: OutlineInputBorder(),
                      ),
                      items: sizes.map((size) {
                        return DropdownMenuItem(value: size, child: Text(size));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedSize = value);
                      },
                    ),

                  const SizedBox(height: 15),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.brown),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() => quantity--);
                              }
                            },
                          ),
                          Text('$quantity',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon:
                                const Icon(Icons.add, color: Color(0xFFFFBA3B)),
                            onPressed: () {
                              setState(() => quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Add to Cart Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (colors.isEmpty || selectedColor != null) &&
                                  (sizes.isEmpty || selectedSize != null)
                              ? const Color(0xFFFFBA3B)
                              : Colors.grey, // Disable if no selection
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                    onPressed: (colors.isEmpty || selectedColor != null) &&
                            (sizes.isEmpty || selectedSize != null)
                        ? () async {
                            final currentUser =
                                Provider.of<AppUsers?>(context, listen: false);
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

                            try {
                              await _cartDatabase.addToCart(
                                  currentUser.uid, cartItem);
                              Navigator.pop(context); // Close modal
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Added to cart")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        : null, // Disable button if selections are missing
                    child: const Text(
                      'Confirm & Add to Cart',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isAdmin)
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.cart);
              },
            ),
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
          backgroundColor: const Color(0xFFFFBA3B),
          child: const Icon(Icons.camera_alt, color: Colors.white),
          onPressed: () {
            final arModelUrl = widget.product?.arModelUrl;
            if (arModelUrl != null && arModelUrl.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ARViewScreen(
                    arModelUrl: arModelUrl, // Pass the AR model URL dynamically
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No AR model available for this product'),
                ),
              );
            }
          },
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Section
                    SizedBox(
                      height: 350,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          PageView.builder(
                            controller: _imageController,
                            itemCount: _selectedImages.isNotEmpty
                                ? _selectedImages.length
                                : (widget.product?.images.length ?? 1),
                            itemBuilder: (context, index) {
                              Widget imageWidget;

                              if (_selectedImages.isNotEmpty) {
                                imageWidget = Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              } else if (widget.product?.images != null &&
                                  widget.product!.images.isNotEmpty) {
                                imageWidget = Image.network(
                                  widget.product!.images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
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
                                              color: Colors.black, size: 20),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            child: SmoothPageIndicator(
                              controller: _imageController,
                              count: (_selectedImages.isNotEmpty
                                      ? _selectedImages.length
                                      : (widget.product?.images.length ?? 0))
                                  .clamp(1, 100),
                              effect: ExpandingDotsEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                activeDotColor: const Color(0xFFFFBA3B),
                                dotColor: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image Upload Button (Admin Only)
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFBA3B),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20),
                          ),
                          onPressed: _pickImages,
                          child: const Text(
                            'Upload Image',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    // Product Name & Price
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAdmin)
                            // Editable Name
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: "Product Name",
                                ),
                              ),
                            )
                          else
                            // Plain Text Name for Customers
                            Text(
                              widget.product?.name ?? "Unknown Product",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),

                          const SizedBox(height: 5),

                          if (isAdmin)
                            // Editable Price
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: "Price",
                                  prefixText: "RM",
                                ),
                              ),
                            )
                          else
                            // Plain Text Price for Customers
                            Text(
                              'RM${widget.product?.price.toStringAsFixed(2) ?? "0.00"}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFBA3B)),
                            ),

                          const SizedBox(height: 10),

                          // Stocks
                          if (!isAdmin)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Stock left:',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 5), // Adjust padding
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      alignment: Alignment
                                          .center, // Center align the text
                                      child: Text(
                                        '${widget.product?.stock ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 18, // Slightly larger font
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign
                                            .center, // Ensure text is centered
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            // Stock input for admin
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: "Stock Quantity",
                                ),
                              ),
                            ),

                          const SizedBox(height: 15),

                          // Product Description
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAccessoriesExpanded =
                                    !_isAccessoriesExpanded;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Accessory Details',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Icon(
                                  _isAccessoriesExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                              ],
                            ),
                          ),

                          if (_isAccessoriesExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: isAdmin
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextFormField(
                                        controller: _descriptionController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: "Description",
                                        ),
                                      ),
                                    )
                                  : Text(
                                      widget.product?.description ??
                                          "No description available",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),

                          const SizedBox(height: 10),
                          // Reviews Section (Clickable)
                          if (widget.product != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.review);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Reviews',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.arrow_forward_ios,
                                        size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                          // Category Selector for Admin
                          if (isAdmin)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonFormField<String>(
                                value: _categories.contains(_selectedCategory)
                                    ? _selectedCategory
                                    : null,
                                decoration: InputDecoration(
                                  labelText: "Product Category",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                items: _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (selectedCategory) {
                                  setState(() {
                                    _selectedCategory = selectedCategory!;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 3D Model Upload (Admin Only)
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Upload 3D Model (GLB)",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFBA3B),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 20),
                                ),
                                onPressed: _pick3DModel,
                                child: const Text(
                                  'Upload 3D Model',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            if (_selected3DModel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Selected File: ${_selected3DModel!.path.split('/').last}",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (widget.product?.arModelUrl != null &&
                                widget.product!.arModelUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Uploaded File: ${widget.product!.arModelUrl!.split('/').last}",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Add Color or Size",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

                    const SizedBox(height: 130), // Space for bottom buttons
                  ],
                ),
              ),
            ],
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (isAdmin)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFBA3B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isLoading ? null : _saveProduct,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                widget.product == null
                                    ? 'Add Product'
                                    : 'Update Product',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFBA3B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: widget.product?.stock == 0
                            ? null
                            : () => _showAddToCartModal(context),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
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
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField(String initialValue, String label,
      {bool isMultiline = false,
      bool isNumber = false,
      String prefixText = ""}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isMultiline ? 3 : 1,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          prefixText: prefixText,
        ),
      ),
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Available Colors:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: [
            ...predefinedColors
                .map((color) => _colorChip(color)), // Predefined colors
            ...selectedColors.map((color) =>
                _colorChip(color, removable: true)), // Selected colors
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFBA3B),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          onPressed: _addCustomColor, // Opens text input dialog
          child: const Text(
            'Add Custom Color',
            style: TextStyle(
                fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Available Sizes:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: [
            ...predefinedSizes.map((size) => _sizeChip(size)),
            ...selectedSizes.map((size) => _sizeChip(size, removable: true)),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFBA3B),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          onPressed: _addCustomSize,
          child: const Text(
            'Add Custom Size',
            style: TextStyle(
                fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _colorChip(String color, {bool removable = false}) {
    return Chip(
      label: Text(color, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.grey.shade200,
      onDeleted: removable
          ? () {
              setState(() {
                selectedColors.remove(color);
              });
            }
          : null,
    );
  }

  Widget _sizeChip(String size, {bool removable = false}) {
    return Chip(
      label: Text(size, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.grey.shade200,
      onDeleted: removable
          ? () {
              setState(() {
                selectedSizes.remove(size);
              });
            }
          : null,
    );
  }
}
