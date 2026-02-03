import 'package:event_scheduler/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = "";
  String result = "";

  void signIn() async {
    try {
      await authService.value.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() {
        result = "success";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "";
        result = "failure";
      });
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
      appBar: AppBar(
        title: Text("Sign up"),
        backgroundColor: Colors.redAccent[200],
      ),
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
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hint: Text("Password"),
                hintStyle: TextStyle(backgroundColor: Colors.grey[350]),
              ),
            ),
            SizedBox(height: 15),
            FloatingActionButton(
              onPressed: () {
                signIn();
              },
              child: Text("Sign up"),
            ),
            Text("Not registered yet? Click here"),
            SizedBox(height: 15),
            Text(errorMessage),
            Text(result),
          ],
        ),
      ),
    );
  }
}
