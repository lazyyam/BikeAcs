// ignore_for_file: deprecated_member_use, unnecessary_string_interpolations, no_leading_underscores_for_local_identifiers, sized_box_for_whitespace, use_super_parameters

import 'package:BikeAcs/pages/profile/userprofile.dart';
import 'package:BikeAcs/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../appUsers/users.dart';
import 'userprofile_view_model.dart'; // Import UserProfileViewModel

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phonenumController = TextEditingController();
  bool editEnable = false;
  late final UserProfileViewModel
      _userProfileViewModel; // Use UserProfileViewModel

  @override
  void initState() {
    super.initState();
    final currentUser = Provider.of<AppUsers?>(context, listen: false);
    _userProfileViewModel = UserProfileViewModel(currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
          color: Colors.black87,
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              editEnable ? Icons.close : Icons.edit,
              size: 22,
              color: const Color(0xFFFFBA3B),
            ),
            onPressed: () => setState(() => editEnable = !editEnable),
          ),
        ],
      ),
      body: FutureBuilder<UserProfile?>(
        future: _userProfileViewModel.fetchUserProfile(), // Use ViewModel
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data!;
          nameController.text = user.name;
          emailController.text = user.email;
          phonenumController.text = user.phonenum;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFBA3B),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor:
                              const Color(0xFFFFBA3B).withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFFFFBA3B),
                            size: 45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        "Full Name",
                        nameController,
                        Icons.person_outline,
                        editEnable,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        "Email",
                        emailController,
                        Icons.email_outlined,
                        false,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        "Phone Number",
                        phonenumController,
                        Icons.phone_outlined,
                        editEnable,
                      ),
                      if (editEnable) ...[
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
                            onPressed: () async {
                              if (nameController.text.isEmpty ||
                                  phonenumController.text.isEmpty) {
                                _showErrorDialog("Please fill in all fields");
                              } else if (!RegExp(
                                      r'^(\+?6?01)[0-46-9]*[0-9]{7,8}$')
                                  .hasMatch(phonenumController.text)) {
                                _showErrorDialog(
                                    "Please enter a valid Malaysian phone number format\nExample: 601XXXXXXXX");
                              } else {
                                await _userProfileViewModel.updateUserProfile(
                                  nameController.text,
                                  emailController.text,
                                  phonenumController.text,
                                );
                                setState(() => editEnable = false);
                                _showSuccessDialog();
                              }
                            },
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool enabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 15,
              color: enabled ? Colors.black87 : Colors.grey[600],
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: enabled ? const Color(0xFFFFBA3B) : Colors.grey[400],
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFFFFBA3B),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "Profile Updated",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your profile has been updated successfully",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBA3B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
