// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/address/address_model.dart';

class AddressDatabase {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('address');

  Stream<List<Address>> getAddresses(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Address.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> saveAddress(String uid, Address address) async {
    final addressCollection = _usersCollection.doc(uid).collection('addresses');
    if (address.id == null) {
      await addressCollection.add(address.toMap());
    } else {
      await addressCollection.doc(address.id).update(address.toMap());
    }
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _usersCollection
        .doc(uid)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Future<void> setDefaultAddress(String uid, String addressId) async {
    final addressCollection = _usersCollection.doc(uid).collection('addresses');
    final batch = FirebaseFirestore.instance.batch();

    // Fetch all addresses
    final snapshot = await addressCollection.get();
    for (var doc in snapshot.docs) {
      // Set isDefault to true for the selected address, false for others
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }

    await batch.commit();
  }
}
