// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:BikeAcs/pages/cart/cart_checkout_fail_screen.dart';
import 'package:BikeAcs/pages/orders/order_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/cart_database.dart'; // Import CartDatabase
import 'package:BikeAcs/services/order_database.dart';
import 'package:BikeAcs/services/payment_service.dart';
import 'package:BikeAcs/services/product_database.dart'; // Import ProductDatabase
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
  final CartDatabase _cartDatabase = CartDatabase(); // Initialize CartDatabase
  final ProductDatabase _productDatabase =
      ProductDatabase(); // Initialize ProductDatabase

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
                    final product =
                        await _productDatabase.getProduct(productId);

                    if (product != null) {
                      if (product.colors.isNotEmpty ||
                          product.sizes.isNotEmpty) {
                        // Reduce variant stock
                        final variantKey = (color != null && size != null)
                            ? '$color-$size'
                            : (color ?? size);
                        if (variantKey != null &&
                            product.variantStock.containsKey(variantKey)) {
                          final updatedVariantStock =
                              Map<String, int>.from(product.variantStock);
                          updatedVariantStock[variantKey] =
                              (updatedVariantStock[variantKey]! - quantity)
                                  .clamp(0, double.infinity)
                                  .toInt();

                          // Update variant stock in Firestore
                          await _productDatabase.updateVariantStock(
                              productId, updatedVariantStock);

                          // Synchronize overall stock with the sum of variant stocks
                          final totalStock = updatedVariantStock.values
                              .fold(0, (sum, qty) => sum + qty);
                          await _productDatabase.updateStock(
                              productId, totalStock);
                        }
                      } else {
                        // Reduce overall stock
                        await _productDatabase.decreaseStock(
                            productId, quantity);
                      }

                      // Check if stock is low and notify admin
                      final updatedProduct =
                          await _productDatabase.getProduct(productId);
                      if (updatedProduct != null &&
                          updatedProduct.stock <= 10) {
                        print(
                            "Notify admin: Product ${updatedProduct.name} is low in stock.");
                        // Add notification logic here (e.g., update Firestore or trigger a UI update)
                      }
                    }
                  }
                }

                // Navigate to success screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.checkoutSuccess,
                  (route) => false,
                );

                // Save order in Firestore
                await OrderDatabase().createOrder(widget.order);

                // Delete selected cart items from Firebase
                for (final item in widget.order.items) {
                  final cartItemId = item['id']; // cart item id
                  if (cartItemId != null && cartItemId.toString().isNotEmpty) {
                    await _cartDatabase.deleteCartItem(
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
