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

  Future<Address?> saveAddress(String uid, Address address) async {
    try {
      final addressRef = _usersCollection.doc(uid).collection('addresses');

      if (address.id?.isEmpty ?? true) {
        // New address
        final docRef = await addressRef.add(address.toMap());
        return address.copyWith(id: docRef.id);
      } else {
        // Update existing address
        await addressRef.doc(address.id).update(address.toMap());
        return address;
      }
    } catch (e) {
      print('Error saving address: $e');
      return null;
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
