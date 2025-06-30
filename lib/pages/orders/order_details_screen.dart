// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, unnecessary_null_comparison

import 'package:BikeAcs/pages/orders/order_status_screen.dart';
import 'package:BikeAcs/pages/reviews/review_view_model.dart'; // Import ReviewViewModel
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../appUsers/users.dart';
import 'order_model.dart';
import 'order_view_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ReviewViewModel _reviewViewModel =
      ReviewViewModel(); // Use ReviewViewModel
  Order? _orderDetails;
  bool _isLoading = true;
  bool _didFetchData = false; // Prevent multiple calls to didChangeDependencies
  double _rating = 0;
  final TextEditingController _opinionController = TextEditingController();
  Map<String, bool> _reviewedProducts =
      {}; // Track reviewed products by productId

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

  bool _isConfirmingOrder = false;
  bool _isSubmittingReview = false;
  bool _isStartingDelivery = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchData) {
      _didFetchData = true;
      _fetchOrderDetails();
      _checkReviewedProducts(); // Check if products in the order are reviewed
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    print("Arguments received: $args"); // Debug log to confirm arguments
    final String? orderId = args?['orderId'];

    if (orderId != null) {
      print("Fetching order details for ID: $orderId"); // Debug log
      try {
        final order = await _orderViewModel.fetchOrderDetails(orderId);
        if (order != null) {
          final currentUser = Provider.of<AppUsers?>(context, listen: false);

          // Initialize all products as not reviewed
          final reviewedProducts = {
            for (var item in order.items) item['productId']: false
          };

          // Check each product asynchronously
          if (currentUser != null) {
            for (var item in order.items) {
              final hasReviewed = await _reviewViewModel.hasReviewed(
                item['productId'],
                currentUser.uid,
                order.id,
              );
              reviewedProducts[item['productId']] = hasReviewed;
            }
          }

          setState(() {
            _orderDetails = order;
            _reviewedProducts = reviewedProducts.cast<String, bool>();
          });
        }
      } catch (e) {
        print("Error fetching order details: $e");
      }
    } else {
      print("No orderId provided in arguments"); // Debug log
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkReviewedProducts() async {
    try {
      final currentUser = Provider.of<AppUsers?>(context, listen: false);
      if (currentUser == null || _orderDetails == null) return;

      // Initialize all products as not reviewed
      setState(() {
        _reviewedProducts = {
          for (var item in _orderDetails!.items) item['productId']: false
        };
      });

      // Check each product asynchronously
      for (var item in _orderDetails!.items) {
        final hasReviewed = await _reviewViewModel.hasReviewed(
          item['productId'],
          currentUser.uid,
          _orderDetails!.id,
        );
        setState(() {
          _reviewedProducts[item['productId']] = hasReviewed;
        });
      }
    } catch (e) {
      print("Error checking reviewed products: $e");
    }
  }

  // ✅ Show Slide-Up Panel for Tracking Number Input
  void _showTrackingInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 26,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFBA3B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping,
                            color: Color(0xFFFFBA3B)),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Shipment Details",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Courier Selection
                  Text(
                    "Courier Service",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCourier,
                      decoration: const InputDecoration(
                        hintText: "Select courier service",
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      items: _courierOptions.map((courier) {
                        return DropdownMenuItem(
                          value: courier,
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  color: Colors.grey[600], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                courier.toUpperCase(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCourier = value!),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tracking Number Input
                  Text(
                    "Tracking Number",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _trackingNumberController,
                    decoration: InputDecoration(
                      hintText: "Enter tracking number",
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFBA3B)),
                      ),
                      prefixIcon: Icon(Icons.qr_code,
                          color: Colors.grey[600], size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Please verify the shipping address before proceeding with delivery.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _trackingNumberController.text.isNotEmpty &&
                                    _selectedCourier != null
                                ? const Color(0xFFFFBA3B)
                                : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (_trackingNumberController.text.isNotEmpty &&
                              _selectedCourier != null &&
                              !_isStartingDelivery)
                          ? () => _confirmStartDelivery(setModalState)
                          : null,
                      child: _isStartingDelivery
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Text(
                              'Confirm & Start Delivery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    _trackingNumberController.text.isNotEmpty &&
                                            _selectedCourier != null
                                        ? Colors.black
                                        : Colors.grey[500],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmStartDelivery(
      [void Function(void Function())? setModalState]) async {
    final trackingNumber = _trackingNumberController.text;
    final courierCode = _selectedCourier;

    if (trackingNumber.isNotEmpty && courierCode != null) {
      try {
        if (setModalState != null) {
          setModalState(() {
            _isStartingDelivery = true;
          });
        } else {
          setState(() {
            _isStartingDelivery = true;
          });
        }
        await _orderViewModel.confirmStartDelivery(
            _orderDetails!.id, trackingNumber, courierCode);
        Navigator.pop(context);
        await Navigator.pushNamed(context, AppRoutes.deliveryStarted);
        _refreshPage();
      } catch (_) {
        Navigator.pop(context);
        // Clear courier and tracking number, and reset loading state
        if (setModalState != null) {
          setModalState(() {
            _selectedCourier = null;
            _trackingNumberController.clear();
            _isStartingDelivery = false;
          });
        } else {
          setState(() {
            _selectedCourier = null;
            _trackingNumberController.clear();
            _isStartingDelivery = false;
          });
        }
        await Navigator.pushNamed(context, AppRoutes.deliveryUpdateFail);
        _refreshPage();
      } finally {
        if (setModalState != null) {
          setModalState(() {
            _isStartingDelivery = false;
          });
        } else {
          setState(() {
            _isStartingDelivery = false;
          });
        }
      }
    }
  }

  // Function to show rating modal
  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFBA3B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFBA3B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Rate Your Order",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Share your experience",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating Stars
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _rating = index + 1.0;
                              });
                              setState(() {
                                _rating = index + 1.0;
                              });
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 36,
                                color: const Color(0xFFFFBA3B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Opinion Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Share your thoughts",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _opinionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "What did you like or dislike?",
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 14),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFFFBA3B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _rating > 0
                                ? const Color(0xFFFFBA3B)
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (_rating > 0 && !_isSubmittingReview)
                              ? () => _submitRating(setModalState)
                              : null,
                          child: _isSubmittingReview
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                )
                              : Text(
                                  'Submit Review',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _rating > 0
                                        ? Colors.black
                                        : Colors.grey[500],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(
      [void Function(void Function())? setModalState]) async {
    try {
      if (setModalState != null) {
        setModalState(() => _isSubmittingReview = true);
      } else {
        setState(() => _isSubmittingReview = true);
      }
      final currentUser = Provider.of<AppUsers?>(context, listen: false);

      if (currentUser == null) {
        print("Current user is null.");
        return;
      }

      final profile = await AuthService().getUserProfile(currentUser.uid).first;

      if (profile == null) {
        print("Profile is null, using fallback values.");
        return;
      }

      final name = profile.name; // Fetch the user's name

      for (var item in _orderDetails!.items) {
        if (_reviewedProducts[item['productId']] == true)
          continue; // Skip already reviewed products

        await _reviewViewModel.submitReview(
          item['productId'],
          _rating,
          _orderDetails!.uid,
          name, // Pass the user's name
          _opinionController.text.trim(), // Save the opinion
          _orderDetails!.id, // Pass the orderId
        );
      }

      await _checkReviewedProducts(); // Refresh reviewed products
      Navigator.pop(context); // Close the modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    } finally {
      if (setModalState != null) {
        setModalState(() => _isSubmittingReview = false);
      } else {
        setState(() => _isSubmittingReview = false);
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
                    const SizedBox(height: 10),
                  ],
                ),
              ),
        bottomNavigationBar: (isAdmin && _orderDetails!.status == "Pending")
            ? _buildStartDeliveryButton()
            : (!isAdmin && _orderDetails!.status == "In Progress")
                ? _buildConfirmOrderReceivedButton()
                : (!isAdmin && _orderDetails!.status == "Completed")
                    ? _buildGiveRatingButton()
                    : null);
  }

  Widget _buildOrderInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Order ID", "#${_orderDetails!.id.substring(0, 8)}"),
            const Divider(height: 16),
            _infoRow("Order Time", _orderDetails!.timestamp.toString()),
          ],
        ),
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBA3B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.location_on, color: Color(0xFFFFBA3B)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Delivery Address",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              address['name'] ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              address['phone'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              address['address'] ?? '',
              style:
                  TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Items",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...List.generate(_orderDetails!.items.length, (index) {
              final item = _orderDetails!.items[index];
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['image'],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (item['color'] != null || item['size'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    if (item['color'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['color'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    if (item['color'] != null &&
                                        item['size'] != null)
                                      const SizedBox(width: 8),
                                    if (item['size'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['size'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "RM${item['price'].toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFBA3B),
                                  ),
                                ),
                                Text(
                                  "×${item['quantity']}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
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
            const Text("Billplz Payment",
                style: TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  // ✅ Build Fixed Bottom "Start Delivery" Button
  Widget _buildStartDeliveryButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBA3B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _showTrackingInput(),
              child: const Text(
                "Start Delivery",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Fixed Bottom "Confirm Order Received" Button
  Widget _buildConfirmOrderReceivedButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBA3B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isConfirmingOrder
                  ? null
                  : () async {
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
                                child: const Text("Confirm",
                                    style: TextStyle(color: Colors.green)),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true) {
                        try {
                          setState(() => _isConfirmingOrder = true);
                          await _orderViewModel.updateOrderTrackingInfo(
                            _orderDetails!.id,
                            _orderDetails!.trackingNumber,
                            _orderDetails!.courierCode,
                            "Completed",
                          );
                          _refreshPage();
                        } finally {
                          setState(() => _isConfirmingOrder = false);
                        }
                      }
                    },
              child: _isConfirmingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      "Confirm Order Received",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Fixed Bottom "Start Delivery" Button
  Widget _buildGiveRatingButton() {
    final bool allReviewed = _orderDetails!.items
        .every((item) => _reviewedProducts[item['productId']] == true);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allReviewed ? Colors.grey[300] : const Color(0xFFFFBA3B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: allReviewed ? null : _showRatingModal,
              child: Text(
                allReviewed ? "Already Rated" : "Rate",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: allReviewed ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
