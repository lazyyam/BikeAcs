// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:BikeAcs/pages/orders/order_status_screen.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/order_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/users.dart';
import '../../services/order_database.dart';
import 'order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderDatabase _orderDatabase = OrderDatabase();
  final OrderTrackingService _trackingService = OrderTrackingService();
  Order? _orderDetails;
  bool _isLoading = true;
  bool _didFetchData = false; // Prevent multiple calls to didChangeDependencies

  String? _selectedCourier;
  final List<String> _courierOptions = [
    'testing-courier',
    'spx',
    'ninjavan-my',
    'dhl',
    'poslaju'
  ];

  final TextEditingController _trackingNumberController =
      TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchData) {
      _didFetchData = true;
      _fetchOrderDetails();
    }
  }

  Future<void> _fetchOrderDetails() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    print("Arguments received: $args"); // Debug log to confirm arguments
    final String? orderId = args?['orderId'];

    if (orderId != null) {
      print("Fetching order details for ID: $orderId"); // Debug log
      try {
        final order = await _orderDatabase.fetchOrderById(orderId);
        setState(() {
          _orderDetails = order;
          _isLoading = false;
        });
      } catch (e) {
        print("Error fetching order details: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print("No orderId provided in arguments"); // Debug log
      setState(() {
        _isLoading = false;
      });
    }
  }

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

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Courier",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: _courierOptions
                    .map((courier) => DropdownMenuItem(
                          value: courier,
                          child: Text(courier.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourier = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

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
                    backgroundColor:
                        _trackingNumberController.text.isNotEmpty &&
                                _selectedCourier != null
                            ? const Color(0xFFFFBA3B)
                            : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                  ),
                  onPressed: (_trackingNumberController.text.isNotEmpty &&
                          _selectedCourier != null)
                      ? _confirmStartDelivery
                      : null,
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

  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchOrderDetails();
  }

  void _confirmStartDelivery() async {
    final trackingNumber = _trackingNumberController.text;
    final courierCode = _selectedCourier;

    if (trackingNumber.isNotEmpty && courierCode != null) {
      try {
        final orderId = _orderDetails!.id;

        // 1. Create tracking on AfterShip
        await _trackingService.createTracking(trackingNumber, courierCode);

        // 2. Update Firestore order with tracking info
        await _orderDatabase.updateOrderTrackingInfo(
          orderId,
          trackingNumber,
          courierCode,
          "In Progress",
        );

        // 3. Show confirmation or navigate
        print('Tracking info successfully submitted.');
        Navigator.pop(context); // Close bottom sheet
        await Navigator.pushNamed(context, AppRoutes.deliveryStarted);
        _refreshPage(); // Refresh page
      } catch (e) {
        print('Failed to submit tracking info: $e');
        Navigator.pop(context); // Close bottom sheet
        await Navigator.pushNamed(context, AppRoutes.deliveryUpdateFail);
        _refreshPage();
      }
    }
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_orderDetails == null) {
      return const Scaffold(
        body: Center(child: Text("Order not found")),
      );
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Order Details',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshPage,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatusHeader(_orderDetails!.status),
                    const SizedBox(height: 10),
                    _buildOrderInfo(),
                    const SizedBox(height: 10),
                    _buildDeliveryAddress(),
                    if (_orderDetails!.status != "Pending")
                      const SizedBox(height: 10),
                    if (_orderDetails!.status != "Pending")
                      _buildOrderStatus(context),
                    const SizedBox(height: 10),
                    _buildOrderItems(),
                    const SizedBox(height: 10),
                    _buildPaymentDetails(_orderDetails!.totalPrice),
                  ],
                ),
              ),
        bottomNavigationBar: (isAdmin && _orderDetails!.status == "Pending")
            ? _buildStartDeliveryButton()
            : (!isAdmin && _orderDetails!.status == "In Progress")
                ? _buildConfirmOrderReceivedButton()
                : null);
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
          _infoRow("Order ID", _orderDetails!.id),
          _infoRow("Order Time", _orderDetails!.timestamp.toString()),
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
    final address = _orderDetails!.address;

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
            children: const [
              Icon(Icons.location_on, color: Color(0xFFFFBA3B)),
              SizedBox(width: 8),
              Text(
                "Delivery Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            address['name'] ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 4),

          // Phone
          Text(
            address['phone'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 4),

          // Address
          Text(
            address['address'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderStatusScreen(
              trackingNumber: _orderDetails!.trackingNumber,
              courierCode: _orderDetails!.courierCode,
            ),
          ),
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
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_shipping, color: Color(0xFFFFBA3B)),
                        SizedBox(width: 8),
                        Text("Order Status",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _orderDetails!.trackingNumber.isNotEmpty
                          ? "Tracking Number: ${_orderDetails!.trackingNumber}"
                          : "No tracking info",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _orderDetails!.courierCode.toUpperCase(),
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
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

  Widget _buildOrderItems() {
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
        children: _orderDetails!.items.map((item) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    item['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "RM${item['price'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "x${item['quantity']}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item['color'] != null || item['size'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (item['color'] != null)
                              Text(
                                "Color: ${item['color']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            if (item['size'] != null)
                              Text(
                                "Size: ${item['size']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              if (item != _orderDetails!.items.last)
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
          _infoRow("Payment ID", _orderDetails!.billId),
          const SizedBox(height: 3),
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
            const Text("BillPlz Payment",
                style: TextStyle(fontSize: 14, color: Colors.black54)),
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

  // ✅ Build Fixed Bottom "Start Delivery" Button
  Widget _buildConfirmOrderReceivedButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFBA3B),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () async {
          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Confirm Order Received"),
                content: const Text(
                    "Are you sure you want to confirm that the order has been received?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Confirm"),
                  ),
                ],
              );
            },
          );

          if (confirmed == true) {
            try {
              await _orderDatabase.updateOrderTrackingInfo(
                _orderDetails!.id,
                _orderDetails!.trackingNumber,
                _orderDetails!.courierCode,
                "Completed",
              );
              print("Order status updated to 'Completed'");
              _refreshPage(); // Refresh the page to reflect the updated status
            } catch (e) {
              print("Error updating order status: $e");
            }
          }
        },
        child: const Text(
          "Confirm Order Received",
          style: TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
