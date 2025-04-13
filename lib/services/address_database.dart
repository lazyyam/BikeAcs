// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/address/address_model.dart';

class AddressDatabase {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('address');

  Stream<List<Address>> getAddresses(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Address.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> saveAddress(String userId, Address address) async {
    final addressCollection =
        _usersCollection.doc(userId).collection('addresses');
    if (address.id == null) {
      await addressCollection.add(address.toMap());
    } else {
      await addressCollection.doc(address.id).update(address.toMap());
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _usersCollection
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }
}
