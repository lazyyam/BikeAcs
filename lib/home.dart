// ignore_for_file: prefer_const_constructors, avoid_print, use_super_parameters

import 'package:BikeAcs/constants/menuBar.dart';
import 'package:BikeAcs/models/userprofile.dart';
import 'package:BikeAcs/models/users.dart';
import 'package:BikeAcs/pages/cart/cart_screen.dart';
import 'package:BikeAcs/pages/home/home_screen.dart';
import 'package:BikeAcs/pages/orders/order_tracking_screen.dart';
import 'package:BikeAcs/pages/products/product_detail.dart';
import 'package:BikeAcs/pages/profile/profile.dart';
import 'package:BikeAcs/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Tracks selected tab index

  // Function to handle navigation bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final DatabaseService databaseService =
        DatabaseService(uid: currentUser.uid);

    return StreamProvider<UserProfile?>.value(
      value: databaseService.useraccount,
      initialData: null,
      catchError: (context, error) {
        print('Error in StreamProvider: $error');
        return null;
      },
      child: Consumer<UserProfile?>(builder: (context, userProfile, _) {
        bool isAdmin = currentUser.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';

        // Define pages for customers & sellers
        final List<Widget> pages = isAdmin
            ? [
                HomeScreen(),
                ProductDetail(), // Replaces CartScreen for Admin
                OrderTrackingScreen(),
                ProfileScreen(),
              ]
            : [
                HomeScreen(),
                CartScreen(), // Normal Cart for customers
                OrderTrackingScreen(),
                ProfileScreen(),
              ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 0; // Reset to HomeScreen
                });
              },
              child: Image.asset(
                'assets/images/BikeACS_title_logo.png',
                height: 20,
              ),
            ),
            actions: [
              CustomMenuDropdown(
                onItemTapped: _onItemTapped,
                isAdmin: isAdmin,
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
        );
      }),
    );
  }
}
