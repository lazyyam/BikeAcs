import 'package:BikeAcs/home.dart';
import 'package:BikeAcs/pages/ar/ar_view.dart';
import 'package:BikeAcs/pages/authenticate/authenticate.dart';
import 'package:BikeAcs/pages/authenticate/register.dart';
import 'package:BikeAcs/pages/authenticate/reset_password.dart';
import 'package:BikeAcs/pages/authenticate/sign_in.dart';
import 'package:BikeAcs/pages/cart/cart_checkout_screen.dart';
import 'package:BikeAcs/pages/cart/cart_checkout_success_screen.dart';
import 'package:BikeAcs/pages/cart/cart_screen.dart';
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
  static const productListing = '/products';
  static const productDetail = '/product_detail';
  static const arView = '/ar-view';
  static const cart = '/cart';
  static const orderTracking = '/order_tracking';
  static const orderDetails = '/order_details';
  static const orderStatus = '/order_status';
  static const review = '/review';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout_success';

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
      case home:
        return MaterialPageRoute(builder: (_) => const Home());
      case productListing:
        final String category = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => ProductListing(category: category));
      case productDetail:
        final Product product = settings.arguments as Product;
        return MaterialPageRoute(
            builder: (_) => ProductDetail(product: product));
      case arView:
        final String modelUrl = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => ARView(modelUrl: modelUrl));
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case orderTracking:
        return MaterialPageRoute(builder: (_) => OrderTrackingScreen());
      case orderDetails:
        return MaterialPageRoute(builder: (_) => OrderDetailsScreen());
      case orderStatus:
        return MaterialPageRoute(builder: (_) => OrderStatusScreen());
      case review:
        return MaterialPageRoute(builder: (_) => ReviewScreen());
      case checkout:
        return MaterialPageRoute(builder: (_) => CartCheckoutScreen());
      case checkoutSuccess:
        return MaterialPageRoute(builder: (_) => CartCheckoutSuccessScreen());
      default:
        return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Page not found'))));
    }
  }
}
