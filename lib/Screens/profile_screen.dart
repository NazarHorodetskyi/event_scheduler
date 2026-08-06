import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PROFILE!!!")),
      body: Column(
        children: [
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
