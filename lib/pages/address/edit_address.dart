import 'package:flutter/material.dart';

import '../../services/address_database.dart';
import 'address_model.dart';

class EditAddressScreen extends StatefulWidget {
  final String userId;
  final Address? address;

  const EditAddressScreen({Key? key, required this.userId, this.address})
      : super(key: key);

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isDefault = false; // Track default status

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.address?.address ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        id: widget.address?.id,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        isDefault: _isDefault,
      );
      await AddressDatabase().saveAddress(widget.userId, address);
      if (_isDefault) {
        await AddressDatabase().setDefaultAddress(widget.userId, address.id!);
      }
      Navigator.pop(context);
    }
  }

  void _confirmDelete(BuildContext context) {
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
              if (widget.address != null) {
                AddressDatabase()
                    .deleteAddress(widget.userId, widget.address!.id!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        actions: widget.address != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a phone number' : null,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 25.0),
                child: TextFormField(
                  controller: _addressController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter an address' : null,
                ),
              ),
              CheckboxListTile(
                title: const Text('Set as Default Address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value!;
                  });
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBA3B),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                ),
                onPressed: _saveAddress,
                child: const Text(
                  'Save',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
