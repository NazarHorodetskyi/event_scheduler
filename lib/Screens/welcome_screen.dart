import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("hello nahui")),
      body: Center(
        child: Column(
          children: [
            FloatingActionButton(
              onPressed: () {
                // go to log in
              },
              child: Text("Have an account"),
            ),
            SizedBox(height: 15),
            FloatingActionButton(
              onPressed: () {
                // go to register screen
              },
              child: Text("Register here"),
            ),
          ],
        ),
      ),
    );
  }
}
