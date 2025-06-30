// ignore_for_file: avoid_print

import 'package:BikeAcs/pages/orders/order_model.dart' as local;
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder(local.Order order) async {
    final userOrdersRef = _firestore
        .collection('orders') // Top-level collection for users
        .doc(order.uid) // Document for the specific user
        .collection('user_orders'); // Subcollection for the user's orders

    final orderRef =
        userOrdersRef.doc(order.id); // Document for the specific order
    final orderData = order.toMap();
    orderData['id'] = order.id; // Ensure the 'id' is included in the document
    orderData['timestamp'] =
        FieldValue.serverTimestamp(); // Use Firestore timestamp
    await orderRef.set(orderData);
  }

  Future<List<local.Order>> fetchAllOrders() async {
    final ordersRef = FirebaseFirestore.instance.collectionGroup('user_orders');

    try {
      final querySnapshot = await ordersRef.get();

      return querySnapshot.docs
          .map((doc) => local.Order.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print("Error fetching all orders: $e");
      return [];
    }
  }

  Future<List<local.Order>> fetchOrdersByStatus(
      String uid, String status) async {
    final userOrdersRef =
        _firestore.collection('orders').doc(uid).collection('user_orders');

    final querySnapshot = await userOrdersRef
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => local.Order.fromMap(doc.data()..['id'] = doc.id))
        .toList(); // Add Firestore document ID to the map
  }

  Future<List<local.Order>> fetchAllOrdersByStatus(String status) async {
    final ordersRef = FirebaseFirestore.instance.collectionGroup('user_orders');

    try {
      final querySnapshot = await ordersRef
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => local.Order.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print("Error fetching orders by status '$status': $e");
      return [];
    }
  }

  Future<local.Order?> fetchOrderById(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup(
              'user_orders') // Search across all user_orders subcollections
          .where('id', isEqualTo: orderId) // Match the order ID
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print("Order found: ${querySnapshot.docs.first.data()}"); // Debug log
        return local.Order.fromMap(querySnapshot.docs.first.data());
      } else {
        print("No order found with ID: $orderId"); // Debug log
      }
    } catch (e) {
      print("Error fetching order by ID: $e");
    }
    return null;
  }

  Future<void> updateOrderTrackingInfo(
    String orderId,
    String trackingNumber,
    String courierCode,
    String status,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('user_orders')
          .where('id', isEqualTo: orderId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update({
          'trackingNumber': trackingNumber,
          'courierCode': courierCode,
          'status': status,
          'timestamp': FieldValue.serverTimestamp(), // Use Firestore timestamp
        });
      }
    } catch (e) {
      print("Error updating tracking info: $e");
    }
  }

  Future<void> updateOrderItemsWithProduct(
      String productId, String newName, String? newImage) async {
    try {
      final ordersRef =
          FirebaseFirestore.instance.collectionGroup('user_orders');
      final querySnapshot = await ordersRef.get();

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        final updatedItems = (orderData['items'] as List<dynamic>).map((item) {
          if (item['productId'] == productId) {
            return {
              ...item,
              'name': newName,
              if (newImage != null) 'image': newImage,
            };
          }
          return item;
        }).toList();

        // Only update the order if items were modified
        if (updatedItems.any((item) => item['productId'] == productId)) {
          await doc.reference.update({'items': updatedItems});
        }
      }
    } catch (e) {
      print('Error updating order items: $e');
      throw Exception('Failed to update order items: $e');
    }
  }
}
