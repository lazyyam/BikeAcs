// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:BikeAcs/pages/cart/cart_checkout_fail_screen.dart';
import 'package:BikeAcs/pages/orders/order_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/order_database.dart';
import 'package:BikeAcs/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BillPaymentWebView extends StatefulWidget {
  final String billUrl;
  final Order order;

  const BillPaymentWebView({
    super.key,
    required this.billUrl,
    required this.order,
  });

  @override
  _BillPaymentWebViewState createState() => _BillPaymentWebViewState();
}

class _BillPaymentWebViewState extends State<BillPaymentWebView> {
  late final WebViewController _controller;
  bool _hasHandledPayment = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) async {
          print("Navigating to $url");

          if (_hasHandledPayment) return;

          final uri = Uri.parse(url);
          final isPaymentCompletePage = uri.path.contains("payment-complete");

          if (isPaymentCompletePage) {
            _hasHandledPayment = true;

            try {
              // Check real payment status from Billplz
              final status =
                  await PaymentService().getBillStatus(widget.order.billId);
              print("Billplz payment status: $status");

              if (status == "Paid") {
                // Navigate to success screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.checkoutSuccess,
                  (route) => false,
                );
                // Save order in Firestore
                await OrderDatabase().createOrder(widget.order);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CartCheckoutFailScreen(autoRedirect: true),
                  ),
                );
              }
            } catch (e) {
              print("Order creation error: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Something went wrong. Please try again.")),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CartCheckoutFailScreen(autoRedirect: true),
                ),
              );
            }
          }
        },
      ));

    _controller.loadRequest(Uri.parse(widget.billUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CartCheckoutFailScreen(autoRedirect: true),
          ),
        );
        return false; // prevent default pop
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Billplz Payment")),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
