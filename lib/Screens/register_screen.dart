import 'package:event_scheduler/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void register() async {
    try {
      await authService.value.createUser(
        email: emailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hint: Text("Input your email"),
                hintStyle: TextStyle(backgroundColor: Colors.grey[350]),
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hint: Text("Password"),
                hintStyle: TextStyle(backgroundColor: Colors.grey[350]),
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                register();
              },
            ),
          ],
        ),
      ),
    );
  }
}
