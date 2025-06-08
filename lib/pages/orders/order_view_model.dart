import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../appUsers/users.dart';
import '../../services/order_database.dart';
import '../../services/order_tracking_service.dart';
import 'order_model.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderDatabase _orderDatabase = OrderDatabase();
  final OrderTrackingService _trackingService = OrderTrackingService();

  // Order Tracking Screen Functions
  Future<Map<String, List<Order>>> fetchOrders(AppUsers? currentUser) async {
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';
    Map<String, List<Order>> ordersByStatus = {
      "Pending": [],
      "In Progress": [],
      "Completed": [],
    };

    try {
      ordersByStatus = {
        "Pending": isAdmin
            ? await _orderDatabase.fetchAllOrdersByStatus("Pending")
            : await _orderDatabase.fetchOrdersByStatus(
                currentUser.uid, "Pending"),
        "In Progress": isAdmin
            ? await _orderDatabase.fetchAllOrdersByStatus("In Progress")
            : await _orderDatabase.fetchOrdersByStatus(
                currentUser.uid, "In Progress"),
        "Completed": isAdmin
            ? await _orderDatabase.fetchAllOrdersByStatus("Completed")
            : await _orderDatabase.fetchOrdersByStatus(
                currentUser.uid, "Completed"),
      };
    } catch (e) {
      print("Error fetching orders: $e");
    }
    return ordersByStatus;
  }

  // Order Details Screen Functions
  Future<Order?> fetchOrderDetails(String? orderId) async {
    if (orderId == null) return null;
    try {
      return await _orderDatabase.fetchOrderById(orderId);
    } catch (e) {
      print("Error fetching order details: $e");
      return null;
    }
  }

  Future<void> confirmStartDelivery(
      String orderId, String trackingNumber, String courierCode) async {
    try {
      await _trackingService.createTracking(trackingNumber, courierCode);
      await _orderDatabase.updateOrderTrackingInfo(
        orderId,
        trackingNumber,
        courierCode,
        "In Progress",
      );
    } catch (e) {
      print('Failed to submit tracking info: $e');
      rethrow;
    }
  }

  Future<void> confirmOrderReceived(
      String orderId, String trackingNumber, String courierCode) async {
    try {
      await _orderDatabase.updateOrderTrackingInfo(
        orderId,
        trackingNumber,
        courierCode,
        "Completed",
      );
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  Future<void> updateOrderTrackingInfo(String orderId, String trackingNumber,
      String courierCode, String status) async {
    try {
      await _orderDatabase.updateOrderTrackingInfo(
        orderId,
        trackingNumber,
        courierCode,
        status,
      );
    } catch (e) {
      print("Error updating order tracking info: $e");
      throw Exception("Failed to update order tracking info: $e");
    }
  }

  // Order Status Screen Functions
  Future<Map<String, dynamic>> loadTracking(
      String trackingNumber, String courierCode) async {
    try {
      return await _trackingService.fetchTrackingStatus(
        trackingNumber,
        courierCode,
      );
    } catch (e) {
      print("Error fetching tracking status: $e");
      return {};
    }
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Unknown time';
    final parsed = DateTime.tryParse(time)?.toLocal();
    if (parsed == null) return 'Invalid date';
    return DateFormat('MMM dd, yyyy – hh:mm a').format(parsed);
  }

  Color getStatusColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'intransit':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      case 'exception':
      case 'failedattempt':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData getStatusIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'intransit':
        return Icons.local_shipping_outlined;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'exception':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> createOrder(Order order) async {
    try {
      await _orderDatabase.createOrder(order);
    } catch (e) {
      print("Error creating order: $e");
      throw Exception("Failed to create order: $e");
    }
  }
}
