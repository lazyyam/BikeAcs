class ReviewItem {
  final String id;
  final String productId;
  final double rating;
  final String uid;
  final String name;
  final String opinion;
  final String orderId;
  final DateTime? timestamp;

  ReviewItem({
    required this.id,
    required this.productId,
    required this.rating,
    required this.uid,
    required this.name,
    required this.opinion,
    required this.orderId,
    this.timestamp,
  });

  factory ReviewItem.fromFirestore(Map<String, dynamic> data, String id) {
    return ReviewItem(
      id: id,
      productId: data['productId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'Anonymous',
      opinion: data['opinion'] ?? '',
      orderId: data['orderId'] ?? '',
      timestamp: data['timestamp']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'rating': rating,
      'uid': uid,
      'name': name,
      'opinion': opinion,
      'orderId': orderId,
      'timestamp': timestamp,
    };
  }
}
