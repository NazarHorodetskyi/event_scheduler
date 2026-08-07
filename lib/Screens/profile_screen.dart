import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/user_profie_provider.dart';
import 'package:event_scheduler/screens/profile_editing_screen.dart';
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
          // Log out button
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
            child: Text("Log out"),
          ),
        ],
      ),
    );
  }
}
