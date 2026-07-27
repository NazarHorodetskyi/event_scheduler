import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:event_scheduler/providers/invite_service_provider.dart';
import 'package:event_scheduler/screens/group_details_screen.dart';
import 'package:event_scheduler/screens/messages_screen.dart';
import 'package:event_scheduler/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  Future<void> refresh() async {
    await Future.wait([ref.refresh(userGroupsProvider.future)]);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(userGroupsProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    final invites = currentUser != null
        ? ref.watch(pendingInvitesProvider(currentUser.uid))
        : const AsyncValue.loading();

    final hasUnreadNotifications = invites.maybeWhen(
      data: (invitesList) => invitesList.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: Text("Something here")),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Row(
                children: [
                  Text("Succesfuly logged in"),
                  FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      }
                    },
                    child: Text("Вийти"),
                  ),
                  Badge(
                    backgroundColor: Colors.red,
                    isLabelVisible: hasUnreadNotifications,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MessageScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.message_outlined),
                    ),
                  ),
                ],
              ),
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  _showCreateGroupDialog(context);
                },
                child: Icon(Icons.add_box_rounded),
              ),
              groups.when(
                data: (groupsToView) {
                  if (groupsToView.isEmpty) {
                    return const Center(child: Text("You have no groups"));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: groupsToView.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GroupDetailsScreen(
                                  groupId: groupsToView[index].groupId,
                                  groupName: groupsToView[index].name,
                                ),
                              ),
                            );
                          },
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
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Additional functions
  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New group'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Group name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = nameController.text.trim();
                if (groupName.isEmpty) return;

                try {
                  final groupService = ref.read(groupServiceProvider);
                  final authService = ref.read(firebaseAuthProvider);

                  final currentAuthUser = authService.currentUser;
                  if (currentAuthUser == null) {
                    throw UserNotAuthenticatedException();
                  }

                  await groupService.createGroup(
                    currentAuthUser.uid,
                    groupName,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(userGroupsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group "$groupName" created!'),
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
              child: const Text('Create'),
            ),
          ],
        );
      },
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
                  final groupService = ref.read(groupServiceProvider);

                  await groupService.leaveGroup(groupId);
                  if (context.mounted) Navigator.pop(dialogContext);

                  ref.invalidate(userGroupsProvider);

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
