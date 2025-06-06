import 'package:flutter/material.dart';

import '../../services/cart_database.dart';
import '../../services/product_database.dart';
import 'cart_model.dart';

class CartViewModel {
  final CartDatabase _cartDatabase = CartDatabase();
  final ProductDatabase _productDatabase = ProductDatabase();

  Stream<List<CartItem>> getCartStream(String uid) {
    return _cartDatabase.getCartItems(uid);
  }

  Future<Map<String, dynamic>> fetchProductDetails(String productId) async {
    final product = await _productDatabase.getProduct(productId);
    return {
      'availableColors': product?.colors ?? [],
      'availableSizes': product?.sizes ?? [],
      'stock': product?.stock ?? 0,
      'variantStock': product?.variantStock ?? {}, // Include variantStock
    };
  }

  Future<void> confirmDelete(
      BuildContext context, String uid, String itemId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text(
            "Are you sure you want to delete this item from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _cartDatabase.deleteCartItem(uid, itemId);
    }
  }
}
