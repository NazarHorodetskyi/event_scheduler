import 'package:event_scheduler/other/app_validators.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/user_profie_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  String errorText = "";

  @override
  void initState() {
    errorText = "";
    super.initState();
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Change password")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Previous password"),
            Padding(
              padding: EdgeInsetsGeometry.all(8),
              child: SizedBox(
                width: 200,
                child: TextFormField(
                  validator: AppValidator.validatePassword,
                  maxLines: 1,
                  controller: oldPasswordController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hint: Text("Input your old password"),
                  ),
                ),
              ),
            ),
            Text("New password"),
            Padding(
              padding: EdgeInsetsGeometry.all(8),
              child: SizedBox(
                width: 200,
                child: TextFormField(
                  validator: AppValidator.validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  maxLines: 1,
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    hint: Text("Create new password"),
                  ),
                ),
              ),
            ),
            Text(errorText, style: TextStyle(color: Colors.red)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  final oldPassword = oldPasswordController.text.trim();
                  final newPassword = newPasswordController.text.trim();

                  if (oldPassword.length < 6 || newPassword.length < 6) {
                    setState(() {
                      errorText = "Password must be at least 6 characters long";
                    });
                    return;
                  }

                  try {
                    await ref
                        .read(authServiceProvider)
                        .updatePassword(
                          oldPassword: oldPassword,
                          newPassword: newPassword,
                        );
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text("Change"),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = ref.read(userProfileProvider).email;
                try {
                  await ref
                      .read(authServiceProvider)
                      .sendPasswordResetEmail(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Reset email sent! Check your mailbox."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text("Send email to reset"),
            ),
          ],
        ),
      ),
    );
  }
}
