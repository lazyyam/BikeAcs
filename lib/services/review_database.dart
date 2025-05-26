import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(String productId, double rating, String uid,
      String name, String opinion, String orderId) async {
    try {
      await _firestore.collection('reviews').add({
        'productId': productId,
        'rating': rating,
        'uid': uid,
        'name': name, // Store the user's name
        'opinion': opinion,
        'orderId': orderId, // Include the orderId
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchReviews(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<bool> hasReviewed(String productId, String uid, String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('uid', isEqualTo: uid)
          .where('orderId',
              isEqualTo: orderId) // Check for the specific orderId
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking review: $e");
      return false;
    }
  }
}
