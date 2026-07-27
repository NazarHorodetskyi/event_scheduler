import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'other/firebase_options.dart';
import 'package:event_scheduler/screens/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: EventScheduler()));
}

class EventScheduler extends StatelessWidget {
  const EventScheduler({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen?',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
      home: SignInScreen(),
    );
  }
}
