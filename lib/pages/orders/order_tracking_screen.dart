// ignore_for_file: library_private_types_in_public_api

import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/users.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);
    bool isAdmin = currentUser!.uid == 'L8sozYOUb2QZGu6ED1mekTWXuj72';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          isAdmin ? "Customer's Orders" : 'My Order',
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFFFFBA3B),
          unselectedLabelColor: Color(0xFF3C312B),
          indicatorColor: Color(0xFFFFBA3B),
          labelStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("Pending"),
          _buildOrderList("In Progress"),
          _buildOrderList("Completed"),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    List<Map<String, dynamic>> orders = [
      {
        "orderId": "234534124435435FD",
        "products": [
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
        ],
        "trackingStatus":
            "Your parcel is being transported to the delivery hub."
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, index) {
        var order = orders[index];

        return InkWell(
          onTap: () {
            // Navigate to OrderDetailsScreen and pass order status
            Navigator.pushNamed(
              context,
              AppRoutes.orderDetails,
              arguments: {
                "orderId": order["orderId"],
                "status": status,
                "products": order["products"],
                "trackingStatus": order["trackingStatus"]
              },
            );
          },
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: ${order['orderId']}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Column(
                    children: order['products'].map<Widget>((product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Image.network(product['image'],
                                width: 50, height: 50),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'],
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "RM${product['price'].toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                ],
                              ),
                            ),
                            Text("X${product['quantity']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  // Show tracking status ONLY if the order is "In Progress"
                  if (status == "In Progress" || status == "Completed")
                    const Divider(),
                  if (status == "In Progress" || status == "Completed")
                    Row(
                      children: [
                        const Icon(Icons.local_shipping,
                            color: Color(0xFFFFBA3B)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(order['trackingStatus'],
                              style: const TextStyle(
                                  color: Color(0xFFFFBA3B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
