// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class CustomMenuDropdown extends StatelessWidget {
  final Function(int) onItemTapped;

  const CustomMenuDropdown({Key? key, required this.onItemTapped})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.menu),
      onSelected: onItemTapped, // Directly update the index
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('Home')),
        const PopupMenuItem(value: 1, child: Text('Cart')),
        const PopupMenuItem(value: 2, child: Text('Order Tracking')),
        const PopupMenuItem(value: 3, child: Text('Profile')),
      ],
    );
  }
}
