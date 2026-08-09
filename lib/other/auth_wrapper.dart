import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/screens/auth_screen.dart';
import 'package:event_scheduler/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainScreen();
        }
        return const AuthScreen();
      },
      error: (e, trace) => Scaffold(body: Center(child: Text('Auth error $e'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
