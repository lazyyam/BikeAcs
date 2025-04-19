import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String uid;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> address;
  final double totalPrice;
  final DateTime timestamp;
  final String status;
  final String billId;
  final String trackingNumber;
  final String courierCode;

  Order({
    required this.id,
    required this.uid,
    required this.items,
    required this.address,
    required this.totalPrice,
    required this.timestamp,
    required this.status,
    required this.billId,
    required this.trackingNumber,
    required this.courierCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'items': items,
      'address': address,
      'totalPrice': totalPrice,
      'timestamp': timestamp,
      'status': status,
      'billId': billId,
      'trackingNumber': trackingNumber,
      'courierCode': courierCode,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      address: map['address'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['address'])
          : {'address': map['address'] ?? ''},
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] is Timestamp) // Handle Firestore Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toString()),
      status: map['status'] ?? '',
      billId: map['billId'] ?? '',
      trackingNumber: map['trackingNumber'] ?? '',
      courierCode: map['courierCode'] ?? '',
    );
  }
}
