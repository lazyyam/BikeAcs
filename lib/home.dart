// ignore_for_file: prefer_const_constructors, avoid_print, use_super_parameters

import 'package:BikeAcs/constants/menuBar.dart';
import 'package:BikeAcs/models/userprofile.dart';
import 'package:BikeAcs/models/users.dart';
import 'package:BikeAcs/pages/cart/cart_screen.dart';
import 'package:BikeAcs/pages/home/home_screen.dart';
import 'package:BikeAcs/pages/orders/order_tracking_screen.dart';
import 'package:BikeAcs/pages/products/product_detail.dart';
import 'package:BikeAcs/pages/products/product_model.dart'; // Import Product model
import 'package:BikeAcs/pages/profile/profile.dart';
import 'package:BikeAcs/pages/sell_analysis/sell_analysis_screen.dart'; // Import Sell Analysis Screen
import 'package:BikeAcs/services/database.dart';
import 'package:BikeAcs/services/product_database.dart'; // Import ProductDatabase
import 'package:badges/badges.dart'
    as custom_badge; // Import badge package with alias
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Tracks selected tab index
  final ProductDatabase _productDatabase =
      ProductDatabase(); // Initialize ProductDatabase

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
                ProductDetail(),
                OrderTrackingScreen(),
                SellAnalysisScreen(),
                ProfileScreen(),
              ]
            : [
                HomeScreen(),
                CartScreen(),
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
              if (isAdmin)
                StreamBuilder<List<Product>>(
                  stream: _productDatabase
                      .getLowStockProducts(), // Stream for low-stock products
                  builder: (context, snapshot) {
                    List<Product> lowStockProducts = snapshot.data ?? [];
                    return PopupMenuButton<Product>(
                      icon: custom_badge.Badge(
                        showBadge: lowStockProducts.isNotEmpty,
                        badgeContent: Text(
                          lowStockProducts.length.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        child: Icon(Icons.notifications),
                      ),
                      itemBuilder: (context) {
                        if (lowStockProducts.isEmpty) {
                          return [
                            PopupMenuItem(
                              child: Text("No low-stock products"),
                            ),
                          ];
                        }
                        return lowStockProducts.map((product) {
                          return PopupMenuItem<Product>(
                            value: product,
                            child: ListTile(
                              title: Text("${product.name} is low on stock"),
                              subtitle: Text("Stock: ${product.stock}"),
                              onTap: () {
                                Navigator.pop(context); // Close the dropdown
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetail(
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                    );
                  },
                ),
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
