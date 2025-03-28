import 'package:flutter/material.dart';

class DeliveryStartedScreen extends StatefulWidget {
  @override
  _DeliveryStartedScreenState createState() => _DeliveryStartedScreenState();
}

class _DeliveryStartedScreenState extends State<DeliveryStartedScreen> {
  @override
  void initState() {
    super.initState();

    // Auto close the screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
            const SizedBox(height: 10),
            const Text(
              "Delivery Started!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Redirecting...", style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
