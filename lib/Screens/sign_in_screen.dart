import 'package:event_scheduler/Screens/main_screen.dart';
import 'package:event_scheduler/Screens/register_screen.dart';
import 'package:event_scheduler/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.initialEmail});
  final String? initialEmail;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = "";

  void signIn() async {
    setState(() {
      errorMessage = "";
    });
    try {
      await authService.value.signIn(
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
                signIn();
              },
              child: Text("Sign up"),
            ),
            RichText(
              text: TextSpan(
                text: "Don't have an account?",
                children: [
                  TextSpan(
                    text: "register here",
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
