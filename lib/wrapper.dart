import 'package:BikeAcs/models/users.dart';
import 'package:BikeAcs/pages/authenticate/authenticate.dart';
import 'package:BikeAcs/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);
    if (currentUser == null) {
      print('User undetected. Navigating to Authenticate screen.');
      return Authenticate();
    } else {
      print('User detected. Navigating to Home screen.');
      return Home();
    }
  }
}
