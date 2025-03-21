import 'package:BikeAcs/models/users.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/auth.dart';
import 'package:BikeAcs/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure WidgetsBinding is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<AppUsers?>.value(
      value: AuthService().userStream,
      initialData: null,
      catchError: (_, __) => null, // Add this line to prevent crashes
      child: MaterialApp(
        home: const Wrapper(),
        theme: ThemeData(
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: Colors.white, // ✅ Background stays white
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white, // ✅ AppBar stays white after scroll
            elevation: 0, // Optional: Removes shadow
            iconTheme:
                IconThemeData(color: Colors.black), // Optional: Icon color
            titleTextStyle:
                TextStyle(color: Colors.black, fontSize: 20), // Text color
          ),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.amber,
            backgroundColor: Colors.white, // ✅ Containers also stay white
          ).copyWith(
            surface: Colors.white, // ✅ Fixes blue tint on scrolling surfaces
            onSurface:
                Colors.black, // Optional: Text/icons on surfaces stay visible
          ),
        ),
        onGenerateRoute:
            AppRoutes.generateRoute, //this is the place to get route
      ),
    );
  }
}
