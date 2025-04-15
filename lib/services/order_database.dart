import 'package:BikeAcs/pages/orders/order_model.dart' as local;
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder(local.Order order) async {
    final userOrdersRef = _firestore
        .collection('orders') // Top-level collection for users
        .doc(order.userId) // Document for the specific user
        .collection('user_orders'); // Subcollection for the user's orders

    final orderRef =
        userOrdersRef.doc(order.id); // Document for the specific order
    final orderData = order.toMap();
    orderData['id'] = order.id; // Ensure the 'id' is included in the document
    await orderRef.set(orderData);
  }
}
