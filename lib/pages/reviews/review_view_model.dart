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
}
