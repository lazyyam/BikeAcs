import 'package:flutter/material.dart';

import '../../services/review_database.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewDatabase _reviewDatabase = ReviewDatabase();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> fetchReviews(String productId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final reviews = await _reviewDatabase.fetchReviews(productId);
      _reviews = reviews;
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
