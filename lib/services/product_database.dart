import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDatabase {
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

  Future<void> incrementNoOfRecord(String id) async {
    try {
      await _productsCollection.doc(id).update({
        'noOfRecord': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing record count: $e');
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
}
