import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  List<String> images; // Changed from single imageUrl to a list
  final String category;
  final String description;
  final int stock;
  final String? arModelUrl;
  final List<String> colors; // Changed from single color to a list
  final List<String> sizes; // Changed from single size to a list
  final Map<String, int> variantStock; // Add variant stock mapping

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.category,
    required this.description,
    required this.stock,
    this.arModelUrl,
    required this.colors,
    required this.sizes,
    required this.variantStock, // Initialize variant stock
  });

  // Create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []), // Parse list of images
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      stock: data['stock'] ?? 0,
      arModelUrl: data['arModelUrl'],
      colors: List<String>.from(data['colors'] ?? []), // Parse list of colors
      sizes: List<String>.from(data['sizes'] ?? []), // Parse list of sizes
      variantStock: Map<String, int>.from(
          data['variantStock'] ?? {}), // Parse variantStock
    );
  }

  // Convert Product to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'images': images, // Save list of images
      'category': category,
      'description': description,
      'stock': stock,
      'arModelUrl': arModelUrl,
      'colors': colors, // Save list of colors
      'sizes': sizes, // Save list of sizes
      'variantStock': variantStock, // Save variant stock
      'keywords': _generateKeywords(name), // Add keywords field
    };
  }

  // Helper function to generate keywords from the product name
  List<String> _generateKeywords(String name) {
    final words = name.toLowerCase().split(' ');
    final keywords = <String>{};

    for (int i = 0; i < words.length; i++) {
      for (int j = i + 1; j <= words.length; j++) {
        keywords.add(words.sublist(i, j).join(' '));
      }
    }

    return keywords.toList();
  }

  // Create a copy of this Product with new values
  Product copyWith({
    String? id,
    String? name,
    double? price,
    List<String>? images,
    String? category,
    String? description,
    int? stock,
    String? arModelUrl,
    List<String>? colors,
    List<String>? sizes,
    Map<String, int>? variantStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      images: images ?? this.images,
      category: category ?? this.category,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      arModelUrl: arModelUrl ?? this.arModelUrl,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      variantStock: variantStock ?? this.variantStock,
    );
  }
}
