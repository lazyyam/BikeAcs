class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String arModelUrl;
  // final String Category;
  //final int no_of_record;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.arModelUrl,
    required this.stock,
    required this.description,
  });
}
