// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../pages/cart/cart_model.dart';

class CartDatabase {
  final CollectionReference _cartCollection =
      FirebaseFirestore.instance.collection('carts');

  Future<void> addToCart(String userId, Map<String, dynamic> cartItem) async {
    try {
      final userCart = _cartCollection.doc(userId).collection('items');
      final existingItem = await userCart
          .where('productId', isEqualTo: cartItem['productId'])
          .where('color', isEqualTo: cartItem['color'])
          .where('size', isEqualTo: cartItem['size'])
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Update quantity if the item already exists
        final docId = existingItem.docs.first.id;
        await userCart.doc(docId).update({
          'quantity': FieldValue.increment(cartItem['quantity']),
        });
      } else {
        // Add new item to the cart
        await userCart.add(cartItem);
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  Stream<List<CartItem>> getCartItems(String userId) {
    return _cartCollection
        .doc(userId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CartItem.fromFirestore(
                  data, doc.id); // Convert to CartItem
            }).toList());
  }

  Future<void> updateCartItem(
      String userId, String itemId, Map<String, dynamic> updates) async {
    if (userId.isEmpty || itemId.isEmpty) {
      debugPrint(
          "Error: Invalid userId or itemId. userId: $userId, itemId: $itemId");
      throw Exception('Invalid userId or itemId');
    }
    try {
      await _cartCollection
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .update(updates);
    } catch (e) {
      debugPrint("Error updating cart item: $e");
      throw Exception('Failed to update cart item: $e');
    }
  }

  Future<void> deleteCartItem(String userId, String itemId) async {
    if (userId.isEmpty || itemId.isEmpty) {
      debugPrint(
          "Error: Invalid userId or itemId. userId: $userId, itemId: $itemId");
      throw Exception('Invalid userId or itemId');
    }
    try {
      await _cartCollection
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting cart item: $e");
      throw Exception('Failed to delete cart item: $e');
    }
  }
}
