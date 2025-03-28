class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String arModelUrl;
  String category; //for product
  // final int stocks; //for product
  // final int no_of record; //for trending accessories
  // final String size;
  // final String color;
  // final int quantity; //for order
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.arModelUrl,
    required this.category,
    required this.stock,
    required this.description,
  });
}
