// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:BikeAcs/pages/cart/cart_checkout_fail_screen.dart';
import 'package:BikeAcs/pages/cart/cart_view_model.dart';
import 'package:BikeAcs/pages/orders/order_model.dart';
import 'package:BikeAcs/pages/orders/order_view_model.dart'; // Import OrderViewModel
import 'package:BikeAcs/pages/products/product_view_model.dart'; // Import ProductViewModel
import 'package:BikeAcs/routes.dart';
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
  final CartViewModel _cartViewModel = CartViewModel(); // Use CartViewModel
  final ProductViewModel _productViewModel =
      ProductViewModel(); // Use ProductViewModel
  final OrderViewModel _orderViewModel = OrderViewModel(); // Use OrderViewModel

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
                // Decrease product stock
                for (final item in widget.order.items) {
                  final productId = item['productId'];
                  final quantity = item['quantity'];
                  final color = item['color'];
                  final size = item['size'];

                  if (productId != null && quantity != null) {
                    await _productViewModel.decreaseVariantStock(
                        productId, color, size, quantity);
                    await _productViewModel.notifyLowStock(productId);
                  }
                }

                // Navigate to success screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.checkoutSuccess,
                  (route) => false,
                );

                // Save order in Firestore
                await _orderViewModel.createOrder(widget.order);

                // Delete selected cart items from Firebase
                for (final item in widget.order.items) {
                  final cartItemId = item['id']; // cart item id
                  if (cartItemId != null && cartItemId.toString().isNotEmpty) {
                    await _cartViewModel.deleteCartItem(
                        widget.order.uid, cartItemId);
                  } else {
                    print(
                        "[BillPayment] Missing cartItemId for item: ${item['name']}");
                  }
                }
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
