// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_const_constructors

import 'package:BikeAcs/pages/profile/delete_confirmation.dart';
import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/userprofile.dart';
import '../../models/users.dart';
import '../../services/auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => ProfileState();
}

class ProfileState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfile?>(context);
    final currentUser = Provider.of<AppUsers?>(context);
    bool isCustomer = currentUser!.uid != 'L8sozYOUb2QZGu6ED1mekTWXuj72';

    void _showPanel() {
      showDialog(
        context: context,
        builder: (context) {
          return deleteConfirmation(
              title: "Delete", subtitle: "Do you want to delete your account?");
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
        child: Column(
          children: [
            // Profile Avatar & Name
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFFFBA3B).withOpacity(0.3),
                  child:
                      const Icon(Icons.person, color: Colors.black54, size: 50),
                ),
                const SizedBox(height: 10),
                Text(
                  profile?.name ?? 'User Name',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  profile?.email ?? 'user@example.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Column(
              children: [
                if (isCustomer)
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.editProfile);
                    },
                  ),
                if (isCustomer)
                  const SizedBox(height: 15), // Add spacing between buttons
                if (isCustomer)
                  _buildProfileOption(
                    icon: Icons.block,
                    title: 'Delete Account',
                    onTap: _showPanel,
                  ),
                const SizedBox(height: 15), // Spacing
                _buildProfileOption(
                  icon: Icons.exit_to_app,
                  title: 'Sign Out',
                  onTap: () async {
                    await _auth.signOut(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFFFBA3B), // Theme color
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.black, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
