import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:event_scheduler/providers/invite_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({super.key});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(authServiceProvider).currentUser!;
    final userInvites = ref.watch(pendingInvitesProvider(currentUser.uid));
    return Scaffold(
      appBar: AppBar(),
      body: userInvites.when(
        data: (invites) {
          if (invites.isEmpty) {
            return Center(child: Text("You have no messages"));
          }

          return ListView.builder(
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];

              return ListTile(
                title: Text("Invitation to ${invite.groupName}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cancel
                    IconButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(inviteServiceProvider)
                              .rejectInvite(inviteId: invite.inviteId);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.cancel_outlined, color: Colors.red),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(inviteServiceProvider)
                              .acceptInvite(
                                inviteId: invite.inviteId,
                                receiverId: invite.receiverId,
                                groupId: invite.groupId,
                              );

                          ref.invalidate(userGroupsProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.check, color: Colors.green),
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text("Error $error")),
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
