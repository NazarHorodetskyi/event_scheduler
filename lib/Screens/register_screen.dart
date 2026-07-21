import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/screens/main_screen.dart';
import 'package:event_scheduler/screens/sign_in_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  String errorMessage = "";

  void _registerButtonClick() async {
    setState(() {
      errorMessage = "";
    });

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nicknameController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "All fields must be filled";
      });
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);

      final isNicknameAvaible = await authService.isNicknameAvaible(
        nicknameController.text.trim(),
      );

      if (!isNicknameAvaible) {
        setState(() {
          errorMessage = "Nickname is not avaible";
        });
        return;
      }

      await authService.createUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        nickname: nicknameController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registration"), backgroundColor: Colors.blue),
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
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(
                hint: Text("Choose nickname"),
                hintStyle: TextStyle(backgroundColor: Colors.grey[350]),
              ),
            ),
            SizedBox(height: 15),
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _registerButtonClick();
              },
              child: Text("Register"),
            ),
            SizedBox(height: 15),
            RichText(
              text: TextSpan(
                text: "ALready registered? ",
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "Sign in",
                    style: TextStyle(color: Colors.blue[400]),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
            Text(errorMessage),
          ],
        ),
      ),
    );
  }
}
