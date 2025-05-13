import 'package:flutter/material.dart';

import '../../services/address_database.dart';
import 'address_model.dart';
import 'edit_address.dart';

class AddressViewModel {
  static Future<void> saveAddress(
    BuildContext context,
    GlobalKey<FormState> formKey,
    String uid,
    Address? address,
    String name,
    String phone,
    String addressText,
    bool isDefault,
  ) async {
    if (formKey.currentState!.validate()) {
      final newAddress = Address(
        id: address?.id,
        name: name,
        phone: phone,
        address: addressText,
        isDefault: isDefault,
      );
      await AddressDatabase().saveAddress(uid, newAddress);
      if (isDefault) {
        await AddressDatabase().setDefaultAddress(uid, newAddress.id!);
      }
      Navigator.pop(context);
    }
  }

  static void confirmDelete(
      BuildContext context, String uid, Address? address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (address != null) {
                AddressDatabase().deleteAddress(uid, address.id!);
              }
              Navigator.pop(context); // Close the dialog
              Navigator.pop(context); // Navigate back
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static String? getDefaultAddressId(List<Address> addresses) {
    return addresses
        .firstWhere(
          (a) => a.isDefault,
          orElse: () => Address(
              id: '', name: '', phone: '', address: '', isDefault: false),
        )
        .id;
  }

  static void navigateToEditAddress(BuildContext context, String uid,
      [Address? address]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressScreen(uid: uid, address: address),
      ),
    );
  }
}
