import 'package:event_scheduler/models/database_group_model.dart';
import 'package:flutter/material.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key, required this.group});

  final DatabaseGroup group;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ти у групі ${widget.group.name}")),
      body: Column(
        children: [
          FloatingActionButton(
            onPressed: () {
              // EVENT CREATION MODAL
            },
          ),
        ],
      ),
    );
  }
}
