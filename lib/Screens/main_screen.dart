import 'package:event_scheduler/screens/sign_in_screen.dart';
import 'package:event_scheduler/services/auth_service.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> signOutButtonClick() async {
    await authService.value.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Something here")),
      body: Center(
        child: Column(
          children: [
            Text("Succesfuly logged in"),
            FloatingActionButton(
              onPressed: () async {
                await authService.value.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
