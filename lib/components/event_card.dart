import 'package:event_scheduler/models/database_event_model.dart';
import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:event_scheduler/screens/event_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventCard extends ConsumerWidget {
  final EventModel event;
  final DatabaseGroup? group;
  final bool isAbleToDelete;
  final bool isHistory;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isAbleToDelete,
    this.isHistory = false,
    this.group,
    this.onTap,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authServiceProvider).currentUser!;
    final needToManage = (group != null);

    return Opacity(
      opacity: isHistory ? 0.6 : 1,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            title: group != null
                ? Text(event.title)
                : Text("${event.title} from group ${event.groupName}"),
            subtitle: Text(event.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (needToManage &&
                    !isHistory &&
                    !event.participants.contains(currentUser.uid)) ...{
                  ElevatedButton(
                    child: Text("Agree"),
                    onPressed: () async {
                      try {
                        await ref
                            .read(eventServiceProvider)
                            .agreeToEvent(currentUser.uid, event.eventId);

                        ref.invalidate(eventServiceProvider);
                        ref.invalidate(activeUserEventsProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                  ),
                },

                if (needToManage &&
                    !isHistory &&
                    !event.decliners.contains(currentUser.uid)) ...{
                  ElevatedButton(
                    child: Text("Decline"),
                    onPressed: () async {
                      try {
                        await ref
                            .read(eventServiceProvider)
                            .declineTheEvent(currentUser.uid, event.eventId);

                        ref.invalidate(eventServiceProvider);
                        ref.invalidate(activeUserEventsProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                  ),
                },

                // Buttons
                Row(
                  children: [
                    // Edit button
                    if (!isHistory && needToManage && isAbleToDelete) ...{
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          try {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EventWizardScreen(
                                  groupId: group!.groupId,
                                  groupName: group!.name,
                                  existingEvent: event,
                                  groupOwnerId: group!.ownerId,
                                ),
                              ),
                            );

                            if (result == true) {
                              ref.invalidate(
                                activeGroupEventsProvider(event.groupId),
                              );
                              ref.invalidate(activeUserEventsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Event edited!'),
                                  ),
                                );
                              }
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
                    // Delete button
                    if (isAbleToDelete && needToManage) ...{
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try {
                            final eventService = ref.read(eventServiceProvider);
                            await eventService.deleteEvent(
                              eventOwnerId: event.creatorId,
                              groupOwnerId: group!.ownerId,
                              eventId: event.eventId,
                              currentUserId: currentUser.uid,
                            );

                            ref.invalidate(
                              activeGroupEventsProvider(event.groupId),
                            );
                            ref.invalidate(activeUserEventsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Event deleted!')),
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
              ],
            ),
          ),
          Column(
            children: [
              if (needToManage) ...{
                Row(
                  children: [
                    Text("Participants: ${event.participants.length}"),
                    Text("Decliners: ${event.decliners.length}"),
                    if (!isHistory) ...{
                      Text("Group members ${group!.members.length}"),
                    },
                  ],
                ),
              },

              Text(event.eventDate.toString()),
            ],
          ),
        ],
      ),
    );
  }
}
