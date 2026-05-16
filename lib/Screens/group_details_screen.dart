import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/screens/event_wizard_screen.dart';
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
      body: Center(
        child: FloatingActionButton(
          child: Text("Create an event"),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    EventWizardScreen(groupId: widget.group.groupId),
              ),
            );
          },
        ),
      ),
    );
  }
}
