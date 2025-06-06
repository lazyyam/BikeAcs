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
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
                color: Colors.black87,
              ),
            ),
            body: SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue shopping",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildInputField(
                          "Email",
                          Icons.email_outlined,
                          (val) => val!.isEmpty ? 'Enter an email' : null,
                          onChanged: (val) => setState(() => email = val),
                          iconColor: iconColor,
                          onFocusChange: (hasFocus) {
                            setState(() {
                              iconColor = hasFocus
                                  ? const Color(0xFFFFBA3B)
                                  : Colors.grey[400]!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          "Password",
                          Icons.lock_outline,
                          (val) => val!.length < 6
                              ? 'Enter a password 6+ chars long'
                              : null,
                          isPassword: true,
                          onChanged: (val) => setState(() => password = val),
                          iconColor: iconColor2,
                          onFocusChange: (hasFocus) {
                            setState(() {
                              iconColor2 = hasFocus
                                  ? const Color(0xFFFFBA3B)
                                  : Colors.grey[400]!;
                            });
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.resetPassword),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildInputField(
    String label,
    IconData icon,
    String? Function(String?) validator, {
    bool isPassword = false,
    Function(String)? onChanged,
    required Color iconColor,
    required Function(bool) onFocusChange,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextFormField(
          obscureText: isPassword,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ),
    );
  }

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
}
