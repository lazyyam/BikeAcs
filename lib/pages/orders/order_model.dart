class Order {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> address;
  final double totalPrice;
  final DateTime timestamp;
  final String status;
  final String billId;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.address,
    required this.totalPrice,
    required this.timestamp,
    required this.status,
    required this.billId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'address': address,
      'totalPrice': totalPrice,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'billId': billId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      address: map['address'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['address'])
          : {'address': map['address'] ?? ''}, // Handle both map and string
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? '',
      billId: map['billId'] ?? '',
    );
  }
}
