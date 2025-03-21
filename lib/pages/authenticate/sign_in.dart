import 'package:BikeAcs/constants/warningalert.dart';
import 'package:BikeAcs/routes.dart';
import 'package:BikeAcs/services/auth.dart';
import 'package:flutter/material.dart';

import '../../shared/loading.dart';

class SignIn extends StatefulWidget {
  // final Function toggleView;
  // SignIn({required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _auth = AuthService();
  bool loading = false;
  bool error = false;
  final _formKey = GlobalKey<FormState>();
  var iconColor = Color(0xFF3C312B).withOpacity(0.40);
  var iconColor2 = Color(0xFF3C312B).withOpacity(0.40);
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    void _showPanel() {
      showDialog(
        context: context,
        builder: (context) {
          return WarningAlert(
            title: 'Error',
            subtitle: 'Your email or password is wrong',
          );
        },
      );
    }

    ;
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              iconTheme: IconThemeData(
                color:
                    Colors.black, // Set the color you want for the back button
              ),
              actions: <Widget>[],
            ),
            body: ListView(children: [
              Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
                  child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 50.0),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              children: [
                                Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.0),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              children: [
                                Text(
                                  "Welcome to BikeAcs: A Motorcycle Accessories Marketplace",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40.0),
                          Focus(
                            onFocusChange: (hasFocus) {
                              setState(() {
                                iconColor = hasFocus
                                    ? Color(0xFF3C312B)
                                        .withOpacity(0.75) // Focused color
                                    : Color(0xFF3C312B)
                                        .withOpacity(0.40); // Unfocused color
                              });
                            },
                            child: TextFormField(
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(),
                                labelText: 'Email',
                                labelStyle: TextStyle(color: iconColor),
                                prefixIcon: Icon(Icons.email,
                                    color: iconColor), // Email icon
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Color(0xFF3C312B).withOpacity(0.25),
                                      width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Color(0xFF3C312B).withOpacity(0.75),
                                      width: 2.0),
                                ),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Enter an email' : null,
                              onChanged: (value) {
                                setState(() {
                                  email = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 15),
                          Focus(
                            onFocusChange: (hasFocus) {
                              setState(() {
                                iconColor2 = hasFocus
                                    ? Color(0xFF3C312B)
                                        .withOpacity(0.75) // Focused color
                                    : Color(0xFF3C312B)
                                        .withOpacity(0.40); // Unfocused color
                              });
                            },
                            child: TextFormField(
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(),
                                labelText: 'Password',
                                labelStyle: TextStyle(color: iconColor2),
                                prefixIcon: Icon(Icons.lock, color: iconColor2),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Color(0xFF3C312B).withOpacity(0.25),
                                      width: 2.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Color(0xFF3C312B).withOpacity(0.75),
                                      width: 2.0),
                                ),
                              ),
                              validator: (val) => val!.length < 6
                                  ? 'Enter a password 6+ chars long'
                                  : null,
                              obscureText: true,
                              onChanged: (val) {
                                setState(() {
                                  password = val;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                      context, AppRoutes.resetPassword);
                                },
                                child: Text(
                                  'Forgot Password',
                                  style: TextStyle(
                                      color:
                                          Color(0xFF3C312B).withOpacity(0.90)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.0),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 100),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  loading = true;
                                });
                                dynamic result =
                                    await _auth.signInWithEmailAndPassword(
                                        email, password);
                                if (result == null) {
                                  setState(() {
                                    loading = false;
                                    _showPanel();
                                  });
                                } else {
                                  print(
                                      'Successfully signed in. Navigating back...');
                                  Navigator.pop(context);
                                }
                              }
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 30.0),
                        ],
                      ))),
            ]));
  }
}
