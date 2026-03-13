import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/screens/sign_in_screen.dart';
import 'package:event_scheduler/services/auth_service.dart';
import 'package:event_scheduler/services/group_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  GroupService groupService = GroupService();
  late Future<List<DatabaseGroup>> groups;

  @override
  void initState() {
    groups = groupService.getAllGroups(FirebaseAuth.instance.currentUser!.uid);
    super.initState();
  }

  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Нова група'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Назва (напр. Футбол)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = nameController.text.trim();
                if (groupName.isEmpty) return;

                try {
                  final currentAuthUser = FirebaseAuth.instance.currentUser;
                  if (currentAuthUser == null) {
                    throw UserNotAuthenticatedException();
                  }

                  final String userId = currentAuthUser.uid;

                  await groupService.createGroup(userId, groupName);

                  if (context.mounted) {
                    Navigator.pop(context);

                    setState(() {
                      groups = groupService.getAllGroups(userId);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Групу "$groupName" успішно створено!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);

                    final errorMessage = e.toString();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Створити'),
            ),
          ],
        );
      },
    );
  }

  Future<void> signOutButtonClick() async {
    await authService.value.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Something here")),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                Text("Succesfuly logged in"),
                FloatingActionButton(
                  onPressed: () async {
                    await authService.value.signOut();
                  },
                  child: Text("Вийти"),
                ),
              ],
            ),
            FloatingActionButton(
              onPressed: () {
                _showCreateGroupDialog(context);
              },
              child: Icon(Icons.add_box_rounded),
            ),
            Expanded(
              child: FutureBuilder(
                future: groups,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    List<DatabaseGroup> groupsToView = snapshot.data!;
                    if (groupsToView.isEmpty) {
                      return Center(
                        child: Text("У вас ще немає створених грууп"),
                      );
                    }
                    return ListView.builder(
                      itemCount: groupsToView.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(groupsToView[index].name),
                            trailing: IconButton(
                              icon: Icon(Icons.exit_to_app, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(
                                  context: context,
                                  groupId: groupsToView[index].groupId,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog({
    required BuildContext context,
    required String groupId,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("You want to leave this group?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  final currentAuthUser =
                      FirebaseAuth.instance.currentUser!.uid;
                  await groupService.leaveGroup(groupId);

                  if (context.mounted) Navigator.pop(dialogContext);

                  setState(() {
                    groups = groupService.getAllGroups(currentAuthUser);
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Success'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    String errorMessage = e.toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Yes, leave"),
            ),
          ],
        );
      },
    );
  }
}
