import 'package:BikeAcs/home.dart';
import 'package:BikeAcs/pages/address/edit_address.dart';
import 'package:BikeAcs/pages/address/my_address.dart';
import 'package:BikeAcs/pages/ar/ar_view.dart';
import 'package:BikeAcs/pages/authenticate/authenticate.dart';
import 'package:BikeAcs/pages/authenticate/register.dart';
import 'package:BikeAcs/pages/authenticate/reset_password.dart';
import 'package:BikeAcs/pages/authenticate/sign_in.dart';
import 'package:BikeAcs/pages/cart/cart_checkout_fail_screen.dart';
import 'package:BikeAcs/pages/cart/cart_checkout_screen.dart';
import 'package:BikeAcs/pages/cart/cart_checkout_success_screen.dart';
import 'package:BikeAcs/pages/cart/cart_model.dart';
import 'package:BikeAcs/pages/cart/cart_screen.dart';
import 'package:BikeAcs/pages/orders/delivery_started_screen.dart';
import 'package:BikeAcs/pages/orders/delivery_update_fail_screen.dart';
import 'package:BikeAcs/pages/orders/order_details_screen.dart';
import 'package:BikeAcs/pages/orders/order_status_screen.dart';
import 'package:BikeAcs/pages/orders/order_tracking_screen.dart';
import 'package:BikeAcs/pages/products/product_detail.dart';
import 'package:BikeAcs/pages/products/product_listing.dart';
import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/pages/profile/edit_profile.dart';
import 'package:BikeAcs/pages/profile/profile.dart';
import 'package:BikeAcs/pages/reviews/review_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const initial = '/';
  static const signIn = '/sign_in';
  static const signUp = '/sign_up';
  static const resetPassword = '/reset_password';
  static const home = '/home';
  static const editProfile = '/edit_profile';
  static const profile = '/profile';
  static const myAddress = '/my_address';
  static const editAddress = '/edit_address';
  static const productListing = '/products';
  static const productDetail = '/product_detail';
  static const arView = '/ar-view';
  static const cart = '/cart';
  static const orderTracking = '/order_tracking';
  static const orderDetails = '/order_details';
  static const orderStatus = '/order_status';
  static const deliveryStarted = '/delivery_started';
  static const deliveryUpdateFail = '/delivery_update_fail';
  static const review = '/review';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout_success';
  static const checkoutFail = '/checkout_fail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => const Authenticate());
      case signIn:
        return MaterialPageRoute(builder: (_) => SignIn());
      case signUp:
        return MaterialPageRoute(builder: (_) => Register());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPassword());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfile());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case myAddress:
        return MaterialPageRoute(builder: (_) => const MyAddressScreen());
      case editAddress:
        return MaterialPageRoute(
            builder: (_) => const EditAddressScreen(
                  uid: '',
                ));
      case home:
        return MaterialPageRoute(builder: (_) => const Home());
      case productListing:
        final String category = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => ProductListing(
                  category: category,
                  isSearch: false,
                ));
      case productDetail:
        final Product product = settings.arguments as Product;
        return MaterialPageRoute(
            builder: (_) => ProductDetail(product: product));
      case arView:
        final arModelUrl = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => ARViewScreen(
            arModelUrl: arModelUrl,
          ),
        );
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case orderTracking:
        return MaterialPageRoute(builder: (_) => OrderTrackingScreen());
      case orderDetails:
        final args =
            settings.arguments as Map<String, dynamic>?; // Accept arguments
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(),
          settings:
              RouteSettings(arguments: args), // Pass arguments to the screen
        );
      case orderStatus:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
            trackingNumber: args['trackingNumber'] ?? '',
            courierCode: args['courierCode'] ?? '',
          ),
        );
      case deliveryStarted:
        return MaterialPageRoute(builder: (_) => DeliveryStartedScreen());
      case deliveryUpdateFail:
        return MaterialPageRoute(builder: (_) => DeliveryUpdateFailScreen());
      case review:
        final productId =
            settings.arguments as String; // Retrieve productId from arguments
        return MaterialPageRoute(
            builder: (_) => ReviewScreen(productId: productId));
      case checkout:
        final args =
            settings.arguments as List<CartItem>; // Ensure arguments are passed
        return MaterialPageRoute(
          builder: (_) => CartCheckoutScreen(
            cartItems: args, // Pass the arguments to the screen
          ),
        );
      case checkoutSuccess:
        return MaterialPageRoute(builder: (_) => CartCheckoutSuccessScreen());
      case checkoutFail:
        return MaterialPageRoute(builder: (_) => CartCheckoutFailScreen());
      default:
        return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Page not found'))));
    }
  }
}
