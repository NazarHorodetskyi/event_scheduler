import 'package:event_scheduler/other/app_validators.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, required this.onToggle, this.initialEmail});
  final String? initialEmail;
  final VoidCallback onToggle;
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = "";

  Future<void> _showPasswordResetDialog(BuildContext context) async {
    final emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Password recovery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email for recovery list'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                try {
                  ref.read(authServiceProvider).sendPasswordResetEmail(email);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

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
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
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
              maxLines: 1,
              decoration: InputDecoration(
                hint: Text("Input your email"),
                hintStyle: TextStyle(backgroundColor: Colors.grey[350]),
              ),
            ),
            SizedBox(height: 15),
            TextFormField(
              validator: AppValidator.validatePassword,
              maxLines: 1,
              obscureText: true,
              controller: passwordController,
              decoration: InputDecoration(
                hint: Text("Password"),
                hintStyle: TextStyle(backgroundColor: Colors.grey[350]),
              ),
            ),
            SizedBox(height: 15),
            FloatingActionButton(
              heroTag: null,
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
                        widget.onToggle();
                      },
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(errorMessage),
            TextButton(
              onPressed: () {
                _showPasswordResetDialog(context);
              },
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }
}
