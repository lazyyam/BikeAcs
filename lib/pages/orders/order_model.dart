class Order {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> address;
  final double totalPrice;
  final DateTime timestamp;
  final String status;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.address,
    required this.totalPrice,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'address': address,
      'totalPrice': totalPrice,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}
