class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final String? color;
  final String? size;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.color,
    this.size,
  });

  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      color: data['color'],
      size: data['size'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'color': color,
      'size': size,
    };
  }
}
