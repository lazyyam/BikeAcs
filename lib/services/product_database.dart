import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/services/cart_database.dart'; // Import CartDatabase
import 'package:BikeAcs/services/order_database.dart'; // Import OrderDatabase
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDatabase {
  final OrderDatabase _orderDatabase =
      OrderDatabase(); // Add OrderDatabase instance
  final CartDatabase _cartDatabase =
      CartDatabase(); // Add CartDatabase instance
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> getProductsByCategory(String category) {
    return _productsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProduct(String id) async {
    DocumentSnapshot doc = await _productsCollection.doc(id).get();
    return doc.exists ? Product.fromFirestore(doc) : null;
  }

  Future<String?> addProduct(Product product) async {
    try {
      DocumentReference docRef =
          await _productsCollection.add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      return null;
    }
  }

  Future<void> setProduct(Product product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toFirestore());
      // Update orders with the new product name and image
      await _orderDatabase.updateOrderItemsWithProduct(
        product.id,
        product.name,
        product.images.isNotEmpty ? product.images.first : null,
      );
      // Update cart items with the new product name, price, and image
      await _cartDatabase.updateCartItemsWithProduct(
        product.id,
        product.name,
        product.price,
        product.images.isNotEmpty ? product.images.first : null,
      );
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      // Delete associated reviews
      final reviewsCollection =
          FirebaseFirestore.instance.collection('reviews');
      final querySnapshot =
          await reviewsCollection.where('productId', isEqualTo: id).get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the product
      await _productsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> updateStock(String id, int newStock) async {
    try {
      await _productsCollection.doc(id).update({'stock': newStock});
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Failed to update stock: $e');
    }
  }

  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      await _productsCollection.doc(productId).update({
        'stock': FieldValue.increment(-quantity),
      });
    } catch (e) {
      print('Error decreasing stock for product $productId: $e');
      throw Exception('Failed to decrease stock: $e');
    }
  }

  Stream<List<Product>> searchProductsByName(String name) {
    return _productsCollection
        .where('name', isGreaterThanOrEqualTo: name)
        .where('name', isLessThanOrEqualTo: name + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> getLowStockProducts() {
    return _productsCollection
        .where('stock', isLessThanOrEqualTo: 10)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<void> updateVariantStock(
      String productId, Map<String, int> variantStock) async {
    try {
      await _productsCollection
          .doc(productId)
          .update({'variantStock': variantStock});
    } catch (e) {
      print('Error updating variant stock: $e');
      throw Exception('Failed to update variant stock: $e');
    }
  }

  Future<void> syncProductStockWithVariants(String productId) async {
    try {
      final productDoc = await _productsCollection.doc(productId).get();
      if (productDoc.exists) {
        final data = productDoc.data() as Map<String, dynamic>;
        final variantStock = Map<String, int>.from(data['variantStock'] ?? {});
        final int totalStock =
            variantStock.values.fold(0, (sum, qty) => sum + qty);

        await _productsCollection.doc(productId).update({'stock': totalStock});
      }
    } catch (e) {
      print('Error syncing product stock with variants: $e');
      throw Exception('Failed to sync product stock: $e');
    }
  }

  Future<Map<String, dynamic>> fetchProductDetails(String productId) async {
    final product = await getProduct(productId);
    return {
      'availableColors': product?.colors ?? [],
      'availableSizes': product?.sizes ?? [],
      'stock': product?.stock ?? 0,
      'variantStock':
          product?.variantStock ?? {}, // Ensure variantStock is included
    };
  }
}
