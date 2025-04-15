// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';

class DeliveryUpdateFailScreen extends StatefulWidget {
  @override
  _DeliveryUpdateFailScreenState createState() =>
      _DeliveryUpdateFailScreenState();
}

class _DeliveryUpdateFailScreenState
    extends State<DeliveryUpdateFailScreen> {
  @override
  void initState() {
    super.initState();

    // Auto navigate back to the previous screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);  // Pops the current screen (navigates back)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  size: 80,
                  color: Color(0xFFEF5350),
                ),
              ),
              const SizedBox(height: 20),

              // Error Text
              const Text(
                "Delivery Status Failed to Update, Please Try Again.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text("Redirecting to the previous page...", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
