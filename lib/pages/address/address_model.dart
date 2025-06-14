class Address {
  final String? id;
  final String name;
  final String phone;
  final String address;
  final bool isDefault; // New field

  Address({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.isDefault = false, // Default value
  });

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      name: data['name'],
      phone: data['phone'],
      address: data['address'],
      isDefault: data['isDefault'] ?? false, // Map new field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'isDefault': isDefault, // Include new field
    };
  }

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault, // Handle new field
    );
  }
}
