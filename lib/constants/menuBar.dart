// ignore_for_file: prefer_const_constructors, use_super_parameters

import 'package:flutter/material.dart';

class CustomMenuDropdown extends StatelessWidget {
  final Function(int) onItemTapped;
  final bool isAdmin;

  const CustomMenuDropdown({
    Key? key,
    required this.onItemTapped,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.menu),
      onSelected: onItemTapped,
      itemBuilder: (context) {
        List<PopupMenuEntry<int>> menuItems = [
          const PopupMenuItem(value: 0, child: Text('Home')),
        ];

        if (isAdmin) {
          menuItems.add(
              const PopupMenuItem(value: 1, child: Text('Create Accessory')));
          menuItems.add(
              const PopupMenuItem(value: 2, child: Text('Order Tracking')));
          menuItems.add(const PopupMenuItem(
              value: 3, child: Text('Sales Analysis'))); // New menu item
          menuItems.add(const PopupMenuItem(value: 4, child: Text('Profile')));
        } else {
          menuItems.add(const PopupMenuItem(value: 1, child: Text('Cart')));
          menuItems.add(
              const PopupMenuItem(value: 2, child: Text('Order Tracking')));
          menuItems.add(const PopupMenuItem(value: 3, child: Text('Profile')));
        }

        return menuItems;
      },
    );
  }
}
