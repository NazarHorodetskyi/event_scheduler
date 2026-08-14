import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:event_scheduler/providers/user_profie_provider.dart';
import 'package:event_scheduler/screens/profile_editing_screen.dart';
import 'package:event_scheduler/screens/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text("PROFILE!!!")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(profileData.nickname),
          ),
          Text(profileData.email),
          // Change nickname button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditingScreen(
                      currentNickname: profileData.nickname,
                    ),
                  ),
                );

                if (result == true) ref.invalidate(groupParticipantsProvider);

                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Nickname changed"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },

              child: Icon(Icons.edit),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdatePasswordScreen()),
              );

              if (result && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Password changed!"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },

            child: Text("Change password"),
          ),
          // Log out button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
              },
              child: Text("Log out"),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _showDeleteAccountDialog(context, ref),
            child: const Text("Delete account"),
          ),
        ],
      ),
    );
  }
}

Future<void> _showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final passwordController = TextEditingController();
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure? All the data will be lost!'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Input your password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              // CANCEL button
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              // DELETE button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final password = passwordController.text.trim();
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter your password'),
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          await ref
                              .read(authServiceProvider)
                              .deleteUser(password: password);

                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Wrong password or network error',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          );
        },
      );
    },
  );
}
