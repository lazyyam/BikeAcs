// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../pages/cart/cart_model.dart';

class CartDatabase {
  final CollectionReference _cartCollection =
      FirebaseFirestore.instance.collection('carts');

  Future<void> addToCart(
      String uid, Map<String, dynamic> cartItem, int availableStock) async {
    try {
      final userCart = _cartCollection.doc(uid).collection('items');
      final existingItem = await userCart
          .where('productId', isEqualTo: cartItem['productId'])
          .where('color', isEqualTo: cartItem['color'])
          .where('size', isEqualTo: cartItem['size'])
          .get();

      int currentQuantity = 0;
      if (existingItem.docs.isNotEmpty) {
        currentQuantity = existingItem.docs.first.data()['quantity'] ?? 0;
      }

      final num newQuantity = currentQuantity + cartItem['quantity'];
      if (newQuantity > availableStock) {
        throw Exception(
            'The quantity exceeds the available stock, please check your shopping cart.');
      }

      if (existingItem.docs.isNotEmpty) {
        // Update quantity if the item already exists
        final docId = existingItem.docs.first.id;
        await userCart.doc(docId).update({
          'quantity': newQuantity,
        });
      } else {
        // Add new item to the cart
        final newDocRef = userCart.doc(); // Generate a new document reference
        cartItem['id'] =
            newDocRef.id; // Include the document ID in the cart item
        await newDocRef.set(cartItem);
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  Stream<List<CartItem>> getCartItems(String uid) {
    return _cartCollection
        .doc(uid)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CartItem.fromFirestore(
                  data, doc.id); // Convert to CartItem
            }).toList());
  }

  Future<void> updateCartItem(
      String uid, String itemId, Map<String, dynamic> updates) async {
    if (uid.isEmpty || itemId.isEmpty) {
      debugPrint("Error: Invalid uid or itemId. uid: $uid, itemId: $itemId");
      throw Exception('Invalid uid or itemId');
    }
    try {
      await _cartCollection
          .doc(uid)
          .collection('items')
          .doc(itemId)
          .update(updates);
    } catch (e) {
      debugPrint("Error updating cart item: $e");
      throw Exception('Failed to update cart item: $e');
    }
  }

  Future<void> deleteCartItem(String uid, String itemId) async {
    if (uid.isEmpty || itemId.isEmpty) {
      debugPrint("Error: Invalid uid or itemId. uid: $uid, itemId: $itemId");
      throw Exception('Invalid uid or itemId');
    }
    try {
      await _cartCollection.doc(uid).collection('items').doc(itemId).delete();
    } catch (e) {
      debugPrint("Error deleting cart item: $e");
      throw Exception('Failed to delete cart item: $e');
    }
  }

  Future<void> deleteCartItemsWithProduct(String productId) async {
    try {
      final cartsRef = FirebaseFirestore.instance.collectionGroup('items');
      final querySnapshot =
          await cartsRef.where('productId', isEqualTo: productId).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error updating cart items: $e');
      throw Exception('Failed to update cart items: $e');
    }
  }

  Future<void> updateCartItemsWithProduct(
      String productId,
      String newName,
      double newPrice,
      String? newImage,
      bool enableColor,
      bool enableSize) async {
    try {
      final cartsRef = FirebaseFirestore.instance.collectionGroup('items');
      final querySnapshot =
          await cartsRef.where('productId', isEqualTo: productId).get();

      for (var doc in querySnapshot.docs) {
        final updates = {
          'name': newName,
          'price': newPrice,
          if (newImage != null) 'image': newImage,
          if (!enableColor) 'color': null, // Set color to null if disabled
          if (!enableSize) 'size': null, // Set size to null if disabled
        };
        await doc.reference.update(updates);
      }
    } catch (e) {
      print('Error updating cart items: $e');
      throw Exception('Failed to update cart items: $e');
    }
  }
}
