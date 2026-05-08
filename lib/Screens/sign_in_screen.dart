import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/screens/main_screen.dart';
import 'package:event_scheduler/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.initialEmail});
  final String? initialEmail;
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = "";

  void signInButtonClick() async {
    setState(() {
      errorMessage = "";
    });

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "All fields must be filled";
      });
      return;
    }

    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorText;
      switch (e.code) {
        case "user-not-found":
        case "invalid-credential":
          errorText = "User not found or passport is incorect";
          break;
        case "invalid-email":
          errorText = "Invalid email format";
          break;
        case "user-disabled":
          errorText = "This user has been disabled";
          break;
        case "wrong-password":
          errorText = "Wrong password";
          break;
        case "too-many-requests":
          errorText = "Too many requests, try again later";
          break;
        case "network-request-failed":
          errorText = "No internet connection";
          break;
        default:
          errorText = "Error: ${e.message}";
      }

      if (mounted) {
        setState(() {
          errorMessage = errorText;
        });
      }
    }
  }

  @override
  void initState() {
    emailController = TextEditingController(text: widget.initialEmail ?? "");
    super.initState();
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
                signInButtonClick();
              },
              child: Text("Sign up"),
            ),
            SizedBox(height: 15),
            RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "Register here",
                    style: TextStyle(color: Colors.blue[400]),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(errorMessage),
          ],
        ),
      ),
    );
  }
}
