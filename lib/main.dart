import 'package:flutter/material.dart';

void main() {
  runApp(const EventScheduler());
}

class EventScheduler extends StatelessWidget {
  const EventScheduler({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center)),
    );
  }
}
