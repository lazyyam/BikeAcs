import 'package:BikeAcs/models/users.dart';
import 'package:BikeAcs/pages/authenticate/authenticate.dart';
import 'package:BikeAcs/pages/authenticate/register.dart';
import 'package:BikeAcs/pages/authenticate/resetPassword.dart';
import 'package:BikeAcs/pages/authenticate/sign_in.dart';
import 'package:BikeAcs/pages/home/home.dart';
import 'package:BikeAcs/pages/payment/payment.dart';
import 'package:BikeAcs/pages/payment/payment2.dart';
import 'package:BikeAcs/pages/payment/payment3.dart';
import 'package:BikeAcs/pages/profile/editprofile.dart';
import 'package:BikeAcs/pages/wrapper.dart';
import 'package:BikeAcs/services/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'pages/menu/provider/menu_provider/menu_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure WidgetsBinding is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamProvider<AppUsers?>.value(
      // ignore: body_might_complete_normally_nullable
      catchError: (User, user) {},
      value: AuthService().changeuser,
      initialData: null,
      child: MaterialApp(
        routes: {
          '/authenticate': (context) => Authenticate(),
          '/home': (context) => Home(),
          '/signin': (context) => SignIn(),
          '/signup': (context) => Register(),
          '/cart': (context) => Payment(),
          '/editprofile': (context) => EditProfile(),
          '/method': (context) => MethodPage(),
          '/receipt': (context) => Receipt(),
          '/resetpassword': (context) => ResetPassword(),
        },
        home: const Wrapper(),
      ),
    );
  }
}
