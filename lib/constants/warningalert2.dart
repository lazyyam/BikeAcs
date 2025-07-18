import 'package:flutter/material.dart';

class WarningAlert2 extends StatelessWidget {
  final String title;
  final String subtitle;
  const WarningAlert2({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.symmetric(vertical: 30),
      contentPadding: EdgeInsets.all(0),
      content: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      title,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 30),
                    child: Text(
                      subtitle,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close the dialog after updating
                      Navigator.pop(context); // Close the dialog after updating
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFFFFBA3B)),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFFFFFFCC)),
                      minimumSize:
                          MaterialStateProperty.all<Size>(Size(200, 50)),
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
