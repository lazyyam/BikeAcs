// ignore_for_file: prefer_const_constructors, avoid_print, use_super_parameters, no_leading_underscores_for_local_identifiers, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:BikeAcs/appUsers/users.dart';
import 'package:BikeAcs/constants/menuBar.dart';
import 'package:BikeAcs/pages/cart/cart_screen.dart';
import 'package:BikeAcs/pages/home/home_screen.dart';
import 'package:BikeAcs/pages/orders/order_tracking_screen.dart';
import 'package:BikeAcs/pages/products/product_detail_screen.dart';
import 'package:BikeAcs/pages/products/product_model.dart'; // Import Product model
import 'package:BikeAcs/pages/products/product_view_model.dart'; // Import ProductViewModel
import 'package:BikeAcs/pages/profile/profile_screen.dart';
import 'package:BikeAcs/pages/profile/userprofile.dart';
import 'package:BikeAcs/pages/profile/userprofile_view_model.dart'; // Import UserProfileViewModel
import 'package:BikeAcs/pages/sell_analysis/sales_analysis_screen.dart'; // Import Sell Analysis Screen
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
  final ProductViewModel _productViewModel =
      ProductViewModel(); // Use ProductViewModel
  late final UserProfileViewModel
      _userProfileViewModel; // Use UserProfileViewModel

  // Function to handle navigation bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final currentUser = Provider.of<AppUsers?>(context, listen: false);
    if (currentUser != null) {
      _userProfileViewModel = UserProfileViewModel(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamProvider<UserProfile?>.value(
      value: _userProfileViewModel.getUserProfileStream(), // Use ViewModel
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
                ProductDetailScreen(),
                OrderTrackingScreen(),
                SalesAnalysisScreen(),
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
                  stream:
                      _productViewModel.getLowStockProducts(), // Use ViewModel
                  builder: (context, snapshot) {
                    List<Product> lowStockProducts = snapshot.data ?? [];
                    return PopupMenuButton<Product>(
                      offset: const Offset(0, 45),
                      icon: custom_badge.Badge(
                        position:
                            custom_badge.BadgePosition.topEnd(top: -5, end: -3),
                        showBadge: lowStockProducts.isNotEmpty,
                        badgeContent: Text(
                          lowStockProducts.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        badgeStyle: custom_badge.BadgeStyle(
                          badgeColor: const Color.fromARGB(255, 255, 59, 59),
                          elevation: 2,
                          padding: const EdgeInsets.all(4),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: lowStockProducts.isNotEmpty
                                ? const Color(0xFFFFBA3B).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: lowStockProducts.isNotEmpty
                                ? const Color(0xFFFFBA3B)
                                : Colors.grey[700],
                            size: 22,
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) {
                        if (lowStockProducts.isEmpty) {
                          return [
                            PopupMenuItem(
                              enabled: false,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.grey[400], size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      "No notifications",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ];
                        }
                        return [
                          PopupMenuItem(
                            enabled: false,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                              child: const Text(
                                "Stock Notifications",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          ...lowStockProducts.map((product) {
                            return PopupMenuItem<Product>(
                              value: product,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.warning_amber_rounded,
                                          color: Colors.red[400], size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Current Stock: ${product.stock}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ];
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
