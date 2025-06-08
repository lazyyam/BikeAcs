// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';

import '../../services/review_database.dart';
import 'review_model.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewDatabase _reviewDatabase = ReviewDatabase();
  List<ReviewItem> _reviews = [];
  bool _isLoading = true;

  List<ReviewItem> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> fetchReviews(String productId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      _reviews = await _reviewDatabase.fetchReviews(productId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reviews: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ReviewItem>> getReviews(String productId) async {
    return await _reviewDatabase.fetchReviews(productId);
  }

  Future<bool> hasReviewed(String productId, String uid, String orderId) async {
    try {
      return await _reviewDatabase.hasReviewed(productId, uid, orderId);
    } catch (e) {
      print("Error checking if product is reviewed: $e");
      return false;
    }
  }

  Future<void> submitReview(String productId, double rating, String uid,
      String name, String opinion, String orderId) async {
    try {
      await _reviewDatabase.addReview(
          productId, rating, uid, name, opinion, orderId);
    } catch (e) {
      print("Error submitting review: $e");
      throw Exception("Failed to submit review: $e");
    }
  }
}
