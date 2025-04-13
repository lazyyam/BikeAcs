class Address {
  final String? id;
  final String name;
  final String phone;
  final String address;

  Address(
      {this.id,
      required this.name,
      required this.phone,
      required this.address});

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      name: data['name'],
      phone: data['phone'],
      address: data['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
