import 'package:flutter/material.dart';

import 'address_model.dart';
import 'address_view_model.dart'; // Import the new ViewModel

class EditAddressScreen extends StatefulWidget {
  final String uid;
  final Address? address;

  const EditAddressScreen({Key? key, required this.uid, this.address})
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
  bool _isLoading = false; // Add this line after other state variables

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

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  bool _validatePhoneNumber(String phone) {
    // Malaysian phone number format validation
    RegExp regex = RegExp(r'^(\+?6?01)[0-46-9]*[0-9]{7,8}$');
    return regex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.address == null ? 'Add Address' : 'Edit Address',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: widget.address != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => AddressViewModel.confirmDelete(
                    context,
                    widget.uid,
                    widget.address,
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a phone number' : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextFormField(
                    controller: _addressController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Complete Address',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter an address' : null,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Set as Default Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _isDefault,
                    activeColor: const Color(0xFFFFBA3B),
                    onChanged: (value) => setState(() => _isDefault = value!),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBA3B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await AddressViewModel.saveAddress(
                              context,
                              _formKey,
                              widget.uid,
                              widget.address,
                              _nameController.text,
                              _phoneController.text,
                              _addressController.text,
                              _isDefault,
                            );
                            setState(() => _isLoading = false);
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Save Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FormFieldValidator<String> validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (label == 'Phone Number') {
            if (value!.isEmpty) {
              return 'Enter a phone number';
            }
            if (!_validatePhoneNumber(value)) {
              _showErrorDialog(context,
                  'Please enter a valid Malaysian phone number format\nExample: 601XXXXXXXX');
              return 'Invalid phone number format';
            }
          }
          return validator(value);
        },
      ),
    );
  }
}
