// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:BikeAcs/home.dart';
import 'package:flutter/material.dart';

class CartCheckoutSuccessScreen extends StatefulWidget {
  @override
  _CartCheckoutSuccessScreenState createState() =>
      _CartCheckoutSuccessScreenState();
}

class _CartCheckoutSuccessScreenState extends State<CartCheckoutSuccessScreen> {
  @override
  void initState() {
    super.initState();

    // Auto redirect to Home screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Home()),
          (route) => false,
        );
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
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Color(0xFFFFBA3B),
                ),
              ),
              const SizedBox(height: 20),

              // Success Text
              const Text(
                "Your Order has been accepted",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text("Redirecting To Home...", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}