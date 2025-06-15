import 'package:cloud_firestore/cloud_firestore.dart';

class SalesAnalysisService {
  Future<Map<String, dynamic>> getSalesAnalysis() async {
    try {
      final ordersRef =
          FirebaseFirestore.instance.collectionGroup('user_orders');
      final querySnapshot = await ordersRef.get();

      double totalRevenue = 0.0;
      int totalOrders = 0;
      Map<String, double> monthlyRevenue = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final monthKey =
            "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}";

        totalRevenue += (data['totalPrice'] ?? 0.0).toDouble();
        totalOrders++;

        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) +
            (data['totalPrice'] ?? 0.0).toDouble();
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      print("Error fetching sales analysis: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTopDealsForMonth(
      int year, int month) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth =
          DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));

      final ordersRef =
          FirebaseFirestore.instance.collectionGroup('user_orders');
      final querySnapshot = await ordersRef
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      Map<String, int> productOrderCount = {};
      Map<String, Map<String, dynamic>> productDetails = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        for (var item in items) {
          final productId = item['productId'];
          final productName = item['name'];
          final productImage = item['image'];
          // final productPrice = item['price'];

          productOrderCount[productId] =
              (productOrderCount[productId] ?? 0) + 1;

          if (!productDetails.containsKey(productId)) {
            productDetails[productId] = {
              'name': productName,
              'image': productImage,
              // 'price': productPrice,
            };
          }
        }
      }

      // Sort products by order count in descending order
      final sortedProducts = productOrderCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Prepare the top deals list (limit to top 5)
      final topDeals = sortedProducts.take(5).map((entry) {
        final productId = entry.key;
        return {
          'productId': productId,
          'name': productDetails[productId]?['name'],
          'image': productDetails[productId]?['image'],
          // 'price': productDetails[productId]?['price'],
          'orderCount': entry.value,
        };
      }).toList();

      return topDeals;
    } catch (e) {
      print("Error fetching top deals for the month: $e");
      return [];
    }
  }

  Future<Map<String, int>> getOrderStatusCounts() async {
    try {
      final ordersRef =
          FirebaseFirestore.instance.collectionGroup('user_orders');
      final querySnapshot = await ordersRef.get();

      Map<String, int> statusCounts = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'unknown';

        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return statusCounts;
    } catch (e) {
      print("Error fetching order status counts: $e");
      return {};
    }
  }

  Future<List<String>> getMostOrderedProductIds() async {
    try {
      final ordersRef =
          FirebaseFirestore.instance.collectionGroup('user_orders');
      final querySnapshot = await ordersRef.get();

      Map<String, int> productOrderCount = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        for (var item in items) {
          final productId = item['productId'];
          productOrderCount[productId] =
              (productOrderCount[productId] ?? 0) + 1;
        }
      }

      // Sort products by order count in descending order
      final sortedProducts = productOrderCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Return the top 10 product IDs
      return sortedProducts.take(10).map((entry) => entry.key).toList();
    } catch (e) {
      print("Error fetching most ordered product IDs: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopPositiveReviewProducts() async {
    try {
      final reviewsRef = FirebaseFirestore.instance.collection('reviews');
      final querySnapshot = await reviewsRef.get();

      Map<String, double> productRatings = {};
      Map<String, int> productReviewCounts = {};
      Map<String, Map<String, dynamic>> productDetails = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final productId = data['productId'];
        final rating = (data['rating'] ?? 0.0).toDouble();

        // Fetch product details if not already cached
        if (!productDetails.containsKey(productId)) {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            productDetails[productId] = {
              'name': productData['name'] ?? 'Unknown Product',
              'image': productData['images'] != null &&
                      (productData['images'] as List).isNotEmpty
                  ? productData['images'][0]
                  : null,
            };
          } else {
            productDetails[productId] = {
              'name': 'Unknown Product',
              'image': null,
            };
          }
        }

        // Accumulate ratings and review counts
        productRatings[productId] = (productRatings[productId] ?? 0.0) + rating;
        productReviewCounts[productId] =
            (productReviewCounts[productId] ?? 0) + 1;
      }

      // Calculate average ratings and sort products by highest average rating
      final averageRatings = productRatings.map((key, value) =>
          MapEntry(key, value / (productReviewCounts[key] ?? 1)));
      final sortedProducts = averageRatings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Prepare the top positive review products list (limit to top 5)
      final topPositiveReviews = sortedProducts.take(5).map((entry) {
        final productId = entry.key;
        return {
          'productId': productId,
          'name': productDetails[productId]?['name'],
          'image': productDetails[productId]?['image'],
          'averageRating': entry.value,
          'reviewCount': productReviewCounts[productId],
        };
      }).toList();

      print("Top Positive Reviews: $topPositiveReviews"); // Debugging log
      return topPositiveReviews;
    } catch (e) {
      print("Error fetching top positive review products: $e");
      return [];
    }
  }
}
