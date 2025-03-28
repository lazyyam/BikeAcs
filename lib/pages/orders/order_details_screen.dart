// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/users.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final List<Map<String, dynamic>> orderItems = [
    {
      "image": "https://picsum.photos/100",
      "name": "Throttle Body & Trumpet Y15ZR",
      "price": 15.99,
      "quantity": 1,
    },
    {
      "image": "https://picsum.photos/101",
      "name": "Meter Bulb T105",
      "price": 9.99,
      "quantity": 1,
    }
  ];

  // ✅ Show Slide-Up Panel for Tracking Number Input
  void _showTrackingInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Centered Title
              const Center(
                child: Text(
                  "Tracking Number",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 5),

              // Left-aligned instruction text
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Enter the tracking number of the parcel to start the delivery",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 15),

              // Left-aligned tracking number input field
              TextField(
                controller: _trackingNumberController,
                decoration: InputDecoration(
                  labelText: "Tracking Number",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              // Left-aligned note
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Note: Make sure the buyer mailing address is correct",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 20),
              // Centered Confirm Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _trackingNumberController.text.isNotEmpty
                        ? const Color(0xFFFFBA3B)
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                  ),
                  onPressed: () {
                    if (_trackingNumberController.text.isNotEmpty) {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.deliveryStarted,
                        arguments: {
                          "trackingNumber": _trackingNumberController.text
                        },
                      );
                    }
                  },
                  child: const Text(
                    'Confirm & Start Delivery',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Other UI Components (Unchanged)
  Widget _buildStatusHeader(String status) {
    return Center(
      child: Text(
        status,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFBA3B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';
    // Get order details from arguments
    final Map<String, dynamic>? orderData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    String orderStatus =
        orderData?["status"] ?? "Pending"; // Default to Pending

    double totalPrice = orderItems.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Status',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildStatusHeader("In Progress"),
            const SizedBox(height: 10),
            _buildOrderInfo(),
            const SizedBox(height: 10),
            _buildDeliveryAddress(),
            // if (orderStatus == "In Progress") const SizedBox(height: 10),
            // ✅ Hide _buildOrderStatus if order is NOT "In Progress"
            // if (orderStatus == "In Progress") _buildOrderStatus(context),
            const SizedBox(height: 10),
            _buildOrderStatus(context),
            const SizedBox(height: 10),
            _buildCartItems(),
            const SizedBox(height: 10),
            _buildPaymentDetails(totalPrice),
          ],
        ),
      ),
      // ✅ Fixed Start Delivery Button for Admin
      bottomNavigationBar: isAdmin ? _buildStartDeliveryButton() : null,
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Order ID", "234534124435435FD"),
          _infoRow("Order Time", "05-05-2024 10:54AM"),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            "Yam Yuan Zhan\nNo 20, Taman Jementah, 85200 Jementah,\nSegamat, Johor",
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the Order Status Page
        Navigator.pushNamed(
          context,
          AppRoutes.orderStatus,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Color(0xFFFFBA3B)),
                        SizedBox(width: 8),
                        Text("Order Status",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text("Parcel has been delivered",
                        style: TextStyle(fontSize: 14, color: Colors.black)),
                    SizedBox(height: 5),
                    Text("07-05-2024 01:18PM",
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.black54, size: 16), // Added arrow icon
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: orderItems.map((item) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(item['image'],
                      width: 60, height: 60, fit: BoxFit.cover),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("RM${item['price'].toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text("X${item['quantity']}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (item != orderItems.last)
                const Divider(thickness: 1, height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentDetails(double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Order Total", "RM${totalPrice.toStringAsFixed(2)}"),
          _infoRow("Payment ID", "5435GSDFD56FGDG"),
          _paymentMethodRow(),
        ],
      ),
    );
  }

  Widget _paymentMethodRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Payment Method",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Row(
          children: [
            const Text("Touch' n Go eWallet",
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(width: 5),
          ],
        ),
      ],
    );
  }

  // ✅ Build Fixed Bottom "Start Delivery" Button
  Widget _buildStartDeliveryButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFBA3B),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _showTrackingInput(),
        child: Text(
          "Start Delivery",
          style: const TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
