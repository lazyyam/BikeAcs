// ignore_for_file: collection_methods_unrelated_type

import 'dart:io';

import 'package:BikeAcs/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/users.dart';
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

  List<File> _selectedImages = [];
  File? _selected3DModel;

  bool enableColor = false;
  bool enableSize = false;

  List<String> selectedColors = [];
  List<String> selectedSizes = [];

  List<String> predefinedColors = [];

  List<String> predefinedSizes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUser = Provider.of<AppUsers?>(context);
    isAdmin = currentUser?.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';
  }

// 📌 PICK MULTIPLE IMAGES FROM GALLERY
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedImages = images.map((img) => File(img.path)).toList();
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
      if (filePath.endsWith('.glb') || filePath.endsWith('.gltf')) {
        setState(() {
          _selected3DModel = File(filePath);
        });
      } else {
        // Show an error if the file type is not supported
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a .glb or .gltf file")),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full-screen modal
      shape: RoundedRectangleBorder(
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
                  Text("Select Options",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),

                  // Color Selector
                  DropdownButtonFormField<String>(
                    value: selectedColor,
                    decoration: InputDecoration(
                      labelText: "Select Color",
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ['Black', 'Red', 'Blue', 'Green', 'White'].map((color) {
                      return DropdownMenuItem(value: color, child: Text(color));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedColor = value);
                    },
                  ),

                  const SizedBox(height: 15),

                  // Size Selector
                  DropdownButtonFormField<String>(
                    value: selectedSize,
                    decoration: InputDecoration(
                      labelText: "Select Size",
                      border: OutlineInputBorder(),
                    ),
                    items: ['S', 'M', 'L', 'XL', 'XXL'].map((size) {
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
                          selectedColor != null && selectedSize != null
                              ? const Color(0xFFFFBA3B)
                              : Colors.grey, // Disable if no selection
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                    onPressed: selectedColor != null && selectedSize != null
                        ? () {
                            // Add to cart logic
                            Navigator.pop(context); // Close modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Added to cart")),
                            );
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFBA3B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () {
          if (widget.product?.arModelUrl.isNotEmpty == true) {
            Navigator.pushNamed(
              context,
              AppRoutes.arView,
              arguments: widget.product!.arModelUrl,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No AR model available for this product')),
            );
          }
        },
      ),
      body: CustomScrollView(
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
                            : 1,
                        itemBuilder: (context, index) {
                          if (_selectedImages.isNotEmpty) {
                            return Image.file(_selectedImages[index],
                                fit: BoxFit.cover);
                          } else if (widget.product?.imageUrl != null &&
                              widget.product!.imageUrl.isNotEmpty) {
                            return Image.network(widget.product!.imageUrl,
                                fit: BoxFit.cover);
                          } else {
                            return Container(
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Icon(Icons.image,
                                  size: 100, color: Colors.grey),
                            );
                          }
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        child: SmoothPageIndicator(
                          controller: _imageController,
                          count: _selectedImages.isNotEmpty
                              ? _selectedImages.length
                              : 1,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdmin)
                        // Editable Name
                        _buildEditableTextField(
                          widget.product?.name ?? "Enter Product Name",
                          "Product Name",
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
                        _buildEditableTextField(
                          widget.product?.price.toStringAsFixed(2) ?? "0.00",
                          "Price",
                          prefixText: "RM",
                          isNumber: true,
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
                                  alignment:
                                      Alignment.center, // Center align the text
                                  child: Text(
                                    '${widget.product!.stock}',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Stocks:',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove,
                                            color: Colors.brown),
                                        onPressed: () {
                                          if (quantity > 1) {
                                            setState(() => quantity--);
                                          }
                                        },
                                      ),
                                      Text('$quantity',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            color: Color(0xFFFFBA3B)),
                                        onPressed: () {
                                          setState(() => quantity++);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 15),

                      // Product Description
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAccessoriesExpanded = !_isAccessoriesExpanded;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Accessory Details',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
                              ? _buildEditableTextField(
                                  widget.product?.description ??
                                      "Enter product description...",
                                  "Description",
                                  isMultiline: true,
                                )
                              : Text(
                                  widget.product?.description ??
                                      "No description available",
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),

                      const SizedBox(height: 10),
                      // Reviews Section (Clickable) //ltr change to visible if product is create
                      // if (!isAdmin)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.review);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reviews',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                        DropdownButtonFormField<String>(
                          value: [
                            'Select Category',
                            'Helmets',
                            'Gloves',
                            'Saddlebags',
                            'Phone Mounts',
                            'Decals',
                            'LED Lights',
                          ].contains(widget.product?.category)
                              ? widget.product?.category
                              : 'Select Category', // Default to "Select Category" if value is invalid

                          decoration: InputDecoration(
                            labelText: "Product Category",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            'Select Category', // Default placeholder
                            'Helmets',
                            'Gloves',
                            'Saddlebags',
                            'Phone Mounts',
                            'Decals',
                            'LED Lights',
                          ].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (selectedCategory) {
                            setState(() {
                              widget.product!.category = selectedCategory!;
                            });
                          },
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
                          "Upload 3D Model (GLB/GLTF)",
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
                                "Selected File: ${_selected3DModel!.path.split('/').last}"),
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
                            if (enableColor)
                              _buildColorSelection(), // ✅ Moved below to match size selection
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              title: const Text("Enable Size Selection"),
                              value: enableSize,
                              onChanged: (value) =>
                                  setState(() => enableSize = value),
                            ),
                            if (enableSize)
                              _buildSizeSelection(), // ✅ Moved below to avoid width issues
                          ],
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 50,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFBA3B),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            if (isAdmin) {
              // Save product changes logic
            } else {
              _showAddToCartModal(context);
            }
          },
          child: Text(
            isAdmin ? 'Save Changes' : 'Add to Cart',
            style: const TextStyle(
                fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
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
