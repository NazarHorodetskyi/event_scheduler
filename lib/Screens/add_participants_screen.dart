import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/models/database_user_model.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/invite_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddingScreen extends ConsumerStatefulWidget {
  const AddingScreen({super.key, required this.group});

  final DatabaseGroup group;
  @override
  ConsumerState<AddingScreen> createState() => _AddingScreenState();
}

class _AddingScreenState extends ConsumerState<AddingScreen> {
  List<DatabaseUser> selectedUsers = [];
  TextEditingController searchController = TextEditingController();
  bool isUserFound = false;
  DatabaseUser? currentSearchUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TextField(controller: searchController),
          ElevatedButton(
            child: Text("Search"),
            onPressed: () async {
              String nickname = searchController.text.trim();
              final authService = ref.read(authServiceProvider);
              currentSearchUser = await authService.getUserByNickname(
                nickname: nickname,
              );

              if (currentSearchUser != null) {
                // Self-invite check
                if (currentSearchUser!.uid ==
                    ref.read(authServiceProvider).currentUser?.uid) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cant add yourself in a group)!"),
                      ),
                    );
                  }
                  return;
                }

                // Already selected check
                if (selectedUsers.any((u) => u.uid == currentSearchUser!.uid)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User already selected!")),
                    );
                  }
                  return;
                }

                setState(() {
                  isUserFound = true;
                });
              } else {
                setState(() {
                  isUserFound = false;
                });
              }
            },
          ),

          if (isUserFound == false && searchController.text.isNotEmpty) ...{
            Text("User not found"),
          } else if (isUserFound && currentSearchUser != null) ...{
            GestureDetector(
              onTap: () {
                // User already in group
                if (widget.group.members.contains(currentSearchUser!.uid)) {
                  setState(() {
                    isUserFound = false;
                    currentSearchUser = null;
                    searchController.clear();
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("User already in group!"),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }

                  return;
                }

                setState(() {
                  selectedUsers.add(currentSearchUser!);
                  currentSearchUser = null;
                  isUserFound = false;
                  searchController.clear();
                });
              },
              child: Card(child: Text(currentSearchUser!.nickname)),
            ),
          },

          if (selectedUsers.isNotEmpty) ...{
            SizedBox(height: 20),

            // Already selected users
            Expanded(
              child: ListView.builder(
                itemCount: selectedUsers.length,
                itemBuilder: (context, index) {
                  final currentUser = selectedUsers[index];
                  return ListTile(
                    title: Text(currentUser.nickname),
                    trailing: Icon(Icons.check),
                    onTap: () {
                      setState(() {
                        selectedUsers.remove(currentUser);
                      });
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 10),
            // Add button
            FloatingActionButton(
              heroTag: null,
              child: Text("Add"),
              onPressed: () async {
                final senderId = ref.read(authServiceProvider).currentUser!.uid;
                final sendingFutures = selectedUsers.map(
                  (user) => ref
                      .read(inviteServiceProvider)
                      .sendInvite(
                        groupId: widget.group.groupId,
                        groupName: widget.group.name,
                        senderId: senderId,
                        receiverId: user.uid,
                      ),
                );

                try {
                  await Future.wait(sendingFutures);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Invites sent!"),
                        duration: Duration(seconds: 3),
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
            ),
          },
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
