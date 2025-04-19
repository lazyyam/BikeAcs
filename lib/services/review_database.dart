import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(String productId, double rating, String uid,
      String name, String opinion) async {
    try {
      await _firestore.collection('reviews').add({
        'productId': productId,
        'rating': rating,
        'uid': uid,
        'name': name, // Store the user's name
        'opinion': opinion,
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
}
