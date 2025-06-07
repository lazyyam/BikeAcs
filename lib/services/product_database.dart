import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/services/cart_database.dart'; // Import CartDatabase
import 'package:BikeAcs/services/order_database.dart'; // Import OrderDatabase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; // Import RxDart for Rx.combineLatest2

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

  Future<void> setProduct(
      Product product, bool enableColor, bool enableSize) async {
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
        enableColor,
        enableSize,
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

      // Delete associated cart items
      final cartItemsCollection =
          FirebaseFirestore.instance.collectionGroup('items');
      final cartQuerySnapshot =
          await cartItemsCollection.where('productId', isEqualTo: id).get();
      for (var doc in cartQuerySnapshot.docs) {
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

  Stream<List<Product>> getProductsStream({
    String? category,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
  }) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final keywords = searchQuery
          .toLowerCase()
          .split(' ')
          .where((k) => k.isNotEmpty)
          .toList();

      // Run two separate queries: one for 'name' and one for 'keywords'
      final nameQuery = _productsCollection
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');

      final keywordsQuery =
          _productsCollection.where('keywords', arrayContainsAny: keywords);

      return Rx.combineLatest2(
        nameQuery.snapshots(),
        keywordsQuery.snapshots(),
        (QuerySnapshot nameSnap, QuerySnapshot keywordSnap) {
          final allDocs = [...nameSnap.docs, ...keywordSnap.docs];

          // Remove duplicates based on product ID
          final uniqueDocs = {
            for (var doc in allDocs) doc.id: doc,
          }.values.toList();

          return uniqueDocs.map((doc) => Product.fromFirestore(doc)).toList();
        },
      );
    }

    // No search, just build base query
    Query queryBuilder = _productsCollection;

    if (category != null && category.isNotEmpty) {
      queryBuilder = queryBuilder.where('category', isEqualTo: category);
    }
    if (minPrice != null) {
      queryBuilder =
          queryBuilder.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      queryBuilder = queryBuilder.where('price', isLessThanOrEqualTo: maxPrice);
    }

    return queryBuilder.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<void> update3DModelUrl(String productId, String? arModelUrl) async {
    try {
      await _productsCollection.doc(productId).update({
        'arModelUrl': arModelUrl,
      });
    } catch (e) {
      print('Error updating 3D model URL: $e');
      throw Exception('Failed to update 3D model URL: $e');
    }
  }
}
