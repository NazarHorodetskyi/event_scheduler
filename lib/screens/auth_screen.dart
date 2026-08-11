import 'package:event_scheduler/screens/register_screen.dart';
import 'package:event_scheduler/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
// Імпортуй сюди свої LoginScreen та RegisterScreen

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showLogin = true;

  void toggleView() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogin) {
      return SignInScreen(onToggle: toggleView);
    } else {
      return RegisterScreen(onToggle: toggleView);
    }
  }
}
