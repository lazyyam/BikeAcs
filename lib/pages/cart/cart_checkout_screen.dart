// ignore_for_file: prefer_const_literals_to_create_immutables, library_private_types_in_public_api, unnecessary_null_comparison, avoid_print

import 'dart:async';

import 'package:BikeAcs/appUsers/users.dart';
import 'package:BikeAcs/pages/cart/bill_payment_web_view.dart';
import 'package:BikeAcs/pages/orders/order_model.dart';
import 'package:BikeAcs/services/auth.dart';
import 'package:BikeAcs/services/payment_service.dart'; // Import PaymentService
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/address_database.dart'; // Import AddressDatabase
import '../address/address_model.dart'; // Import Address model
import '../cart/cart_model.dart'; // Import CartItem model;
import 'cart_view_model.dart';

class CartCheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CartCheckoutScreen({super.key, required this.cartItems});

  @override
  _CartCheckoutScreenState createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final CartViewModel _cartViewModel = CartViewModel();
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
    final uid = currentUser?.uid; // Replace with actual user ID
    final addressStream = AddressDatabase().getAddresses(uid!);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Shipping Address",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDeliveryAddress(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Summary",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCartItems(),
                      ],
                    ),
                  ),
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
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBA3B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on,
                              color: Color(0xFFFFBA3B)),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Delivery Address",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Choose where to deliver your items",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey[200], thickness: 1),

                  // Address List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: availableAddresses.length,
                      itemBuilder: (context, index) {
                        final address = availableAddresses[index];
                        final isSelected = address == defaultAddress;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, address),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFBA3B).withOpacity(0.1)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFFBA3B)
                                    : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Radio(
                                  value: true,
                                  groupValue: isSelected,
                                  onChanged: (_) =>
                                      Navigator.pop(context, address),
                                  activeColor: const Color(0xFFFFBA3B),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            address.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (address.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Default',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        address.phone,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address.address,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          height: 1.3,
                                        ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFBA3B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFFFFBA3B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (defaultAddress != null) ...[
                    Text(
                      defaultAddress!.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      defaultAddress!.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      defaultAddress!.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else
                    const Text(
                      "Select delivery address",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
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
                            fontSize: 14, fontWeight: FontWeight.bold),
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
                          fontSize: 14, fontWeight: FontWeight.bold),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBA3B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFFFFBA3B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Billplz Payment",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Payment",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "RM${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFBA3B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: defaultAddress == null
                    ? Colors.grey[300]
                    : const Color(0xFFFFBA3B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                                  'id': item.id,
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
                          uid: currentUser.uid,
                          billId: billData['billId']!,
                          trackingNumber: billData['trackingNumber'] ?? '',
                          courierCode: billData['courierCode'] ?? '',
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
              child: Text(
                "Place Order",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      defaultAddress == null ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ...rest of existing code...
}
