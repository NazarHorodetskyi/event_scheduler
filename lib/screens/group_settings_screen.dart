import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/other/app_validators.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key, required this.group});

  final DatabaseGroup group;
  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.group.name;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Column(
        children: [
          TextFormField(
            validator: AppValidator.validateTitle,
            controller: nameController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            maxLines: 1,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(width: 40)),
            ),
          ),
          IconButton(
            onPressed: () async {
              try {
                final currentUser = ref.read(authServiceProvider).currentUser;
                if (currentUser == null) {
                  throw Exception("User not found");
                }

                final newName = nameController.text.trim();
                bool isChanged = false;
                if (newName != widget.group.name) {
                  final groupService = ref.read(groupServiceProvider);
                  await groupService.changeGroupName(
                    currentUserId: currentUser.uid,
                    groupOwnerId: widget.group.ownerId,
                    groupId: widget.group.groupId,
                    newName: newName,
                  );
                  isChanged = true;
                }

                if (context.mounted) {
                  Navigator.pop(context, isChanged);
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
            icon: Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}
