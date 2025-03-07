import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BikeFix/models/users.dart';
import 'package:BikeFix/pages/authenticate/authenticate.dart';
import 'package:BikeFix/pages/home/home.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);
    if (currentUser == null) {
      return Authenticate();
    } else {
      print('User detected. Navigating to Home screen.');
      return Home();
    }
  }
}
