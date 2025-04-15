// ignore_for_file: deprecated_member_use

import 'package:BikeAcs/pages/cart/cart_checkout_fail_screen.dart';
import 'package:BikeAcs/pages/orders/order_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/order_database.dart';
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

          // Case 1: Fail or Cancel detected
          if (url.contains("x-cancel") || url.contains("x-fail")) {
            _hasHandledPayment = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CartCheckoutFailScreen(autoRedirect: true),
              ),
            );
            return;
          }

          // Case 3: Success redirect
          if (url.contains("x-success=true") &&
              url.contains("payment-complete")) {
            _hasHandledPayment = true;
            try {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.checkoutSuccess,
                (route) => false,
              );
              await OrderDatabase().createOrder(widget.order);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Order error: $e")),
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
