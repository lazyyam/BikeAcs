// ignore_for_file: prefer_const_literals_to_create_immutables, library_private_types_in_public_api, unnecessary_null_comparison, avoid_print

import 'dart:async';

import 'package:BikeAcs/models/users.dart';
import 'package:BikeAcs/pages/cart/bill_payment_web_view.dart';
import 'package:BikeAcs/pages/orders/order_model.dart';
import 'package:BikeAcs/services/auth.dart';
import 'package:BikeAcs/services/payment_service.dart'; // Import PaymentService
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/address_database.dart'; // Import AddressDatabase
import '../address/address_model.dart'; // Import Address model
import '../cart/cart_model.dart'; // Import CartItem model;

class CartCheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CartCheckoutScreen({super.key, required this.cartItems});

  @override
  _CartCheckoutScreenState createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  late List<CartItem> cartItems;
  Address? defaultAddress;
  List<Address> availableAddresses = [];
  StreamSubscription<List<Address>>?
      _addressSubscription; // Add a subscription reference

  @override
  void initState() {
    super.initState();
    cartItems = widget.cartItems; // Initialize cartItems from widget
    _fetchAddresses(); // Fetch addresses
  }

  Future<void> _fetchAddresses() async {
    final currentUser = Provider.of<AppUsers?>(context, listen: false);
    final userId = currentUser?.uid; // Replace with actual user ID
    final addressStream = AddressDatabase().getAddresses(userId!);
    _addressSubscription = addressStream.listen((addresses) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          availableAddresses = addresses;
          if (addresses.isNotEmpty) {
            defaultAddress = addresses.firstWhere(
                (address) => address.isDefault,
                orElse: () => addresses[0]);
          } else {
            defaultAddress = null; // No default address if the list is empty
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _addressSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  double get totalPrice {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CHECKOUT', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddress(),
                  const SizedBox(height: 15),
                  _buildCartItems(),
                ],
              ),
            ),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return GestureDetector(
      onTap: () async {
        final selectedAddress = await showModalBottomSheet<Address>(
          context: context,
          isScrollControlled: true, // Allow full-screen height adjustment
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    "Select Address",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Address List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableAddresses.length,
                      itemBuilder: (context, index) {
                        final address = availableAddresses[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context, address);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: address == defaultAddress,
                                  onChanged: (isSelected) {
                                    if (isSelected == true) {
                                      Navigator.pop(context, address);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        address.phone,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        address.address,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (selectedAddress != null) {
          setState(() {
            defaultAddress = selectedAddress;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFFFBA3B)),
                const SizedBox(width: 8),
                const Text("Delivery Address",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              defaultAddress != null
                  ? "${defaultAddress!.name}\n${defaultAddress!.phone}\n${defaultAddress!.address}"
                  : "No address selected",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return SizedBox(
      height: 450, // Adjust height as needed
      child: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "RM${item.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (item.color != null)
                            Text(
                              "Color: ${item.color}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          if (item.color != null && item.size != null)
                            const SizedBox(width: 10),
                          if (item.size != null)
                            Text(
                              "Size: ${item.size}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),

                // Quantity and Total Price (Right-Aligned)
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // Align to the right
                  children: [
                    Text(
                      "X${item.quantity}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Total: RM${(item.price * item.quantity).toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaymentMethod(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("RM${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFBA3B))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: defaultAddress == null
                    ? Colors.grey // Disabled color
                    : const Color(0xFFFFBA3B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: defaultAddress == null
                  ? null
                  : () async {
                      final currentUser =
                          Provider.of<AppUsers?>(context, listen: false);

                      // Check if currentUser is null to avoid any errors
                      if (currentUser == null) {
                        print("Current user is null.");
                        return;
                      }

                      // Use StreamBuilder to listen to the UserProfile stream and get the profile data
                      final profile = await AuthService()
                          .getUserProfile(currentUser.uid)
                          .first;

                      if (profile == null) {
                        print("Profile is null, using fallback values.");
                      }

                      final name = profile.name;
                      final email = profile.email;
                      final amountInCents = (totalPrice * 100).toInt();

                      final billData = await PaymentService.createBill(
                        name: name,
                        email: email,
                        amountInCents: amountInCents,
                      );

                      if (billData != null) {
                        final orderId =
                            DateTime.now().millisecondsSinceEpoch.toString();

                        final orderItems = cartItems
                            .map((item) => {
                                  'productId': item.productId,
                                  'name': item.name,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                  'image': item.image,
                                  'color': item.color,
                                  'size': item.size,
                                })
                            .toList();

                        final order = Order(
                          id: orderId,
                          userId: currentUser.uid,
                          billId: billData['billId']!,
                          items: orderItems,
                          address: {
                            'name': defaultAddress!.name,
                            'phone': defaultAddress!.phone,
                            'address': defaultAddress!.address,
                          },
                          status: 'Pending', // Set initial status to 'Pending'
                          totalPrice: totalPrice,
                          timestamp: DateTime.now(),
                        );

                        // Navigate to WebView and wait for payment result
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillPaymentWebView(
                                billUrl: billData['billUrl']!, order: order),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to create payment.')),
                        );
                      }
                    },
              child: const Text(
                "Place Order",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Payment Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const SizedBox(width: 5),
              const Text("BillPlz Payment", style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
