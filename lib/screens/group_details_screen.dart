import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:event_scheduler/screens/add_participants_screen.dart';
import 'package:event_scheduler/screens/event_wizard_screen.dart';
import 'package:event_scheduler/screens/group_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(groupDetailsProvider(widget.groupId).future),
      ref.refresh(groupEventsProvider(widget.groupId).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final groupData = ref.watch(groupDetailsProvider(widget.groupId));
    final eventsAsync = ref.watch(groupEventsProvider(widget.groupId));
    final currentUser = ref.watch(authServiceProvider).currentUser!;
    final participantsAsync = ref.watch(
      groupParticipantsProvider(widget.groupId),
    );

    bool isGroupOwner = currentUser.uid == groupData.value?.ownerId
        ? true
        : false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "You are in the group: ${groupData.value?.name ?? widget.groupName}",
        ),
      ),
      body: groupData.when(
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (group) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    children: [
                      FloatingActionButton(
                        heroTag: null,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddingScreen(group: group),
                            ),
                          );
                        },
                      ),
                      // Group settings
                      if (isGroupOwner) ...{
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    GroupSettingsScreen(group: group),
                              ),
                            );

                            if (result == true) {
                              ref.invalidate(groupDetailsProvider);
                              ref.invalidate(userEventsProvider);
                              ref.invalidate(userGroupsProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Changed!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.settings),
                        ),
                      },
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      top: 16.0,
                      bottom: 8.0,
                    ),
                    child: Text(
                      "Participants:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: participantsAsync.when(
                      data: (participants) {
                        if (participants.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text("No participants"),
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final participant = participants[index];
                            final participantId = participant.id;
                            final participantName = participant.nickname;

                            final isMe = participantId == currentUser.uid;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Chip(
                                label: Text(participantName),
                                backgroundColor: Colors.blue.shade100,
                                side: BorderSide.none,
                                onDeleted: (isGroupOwner && !isMe)
                                    ? () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text("Kick user?"),
                                            content: Text(
                                              "Are you sure you want to kick $participantName?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text(
                                                  "Kick",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          try {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Removing user...",
                                                  ),
                                                ),
                                              );
                                            }
                                            await ref
                                                .read(groupServiceProvider)
                                                .kickParticipant(
                                                  groupId: widget.groupId,
                                                  targetUserId: participantId,
                                                );

                                            ref.invalidate(
                                              groupParticipantsProvider(
                                                widget.groupId,
                                              ),
                                            );
                                            ref.invalidate(
                                              groupDetailsProvider(
                                                widget.groupId,
                                              ),
                                            );
                                            ref.invalidate(groupEventsProvider);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "$participantName was removed.",
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text("Error: $e"),
                      ),
                    ),
                  ),

                  const Divider(height: 30),
                  eventsAsync.when(
                    data: (events) {
                      if (events.isEmpty) {
                        return const Center(child: Text("No events yet"));
                      }

                      events.sort((a, b) {
                        if (a.isCompleted != b.isCompleted) {
                          return a.isCompleted ? 1 : -1;
                        }
                        if (a.isCompleted && b.isCompleted) {
                          return a.eventDate.compareTo(b.eventDate) * -1;
                        }
                        return a.eventDate.compareTo(b.eventDate);
                      });

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final isEventOwner =
                              ((currentUser.uid == event.creatorId) ||
                              (currentUser.uid == group.ownerId));
                          return Opacity(
                            opacity: event.isCompleted ? 0.6 : 1,
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(event.title),
                                  subtitle: Text(event.description),
                                  trailing: !event.isCompleted
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!event.participants.contains(
                                              currentUser.uid,
                                            )) ...{
                                              ElevatedButton(
                                                child: Text("Agree"),
                                                onPressed: () async {
                                                  try {
                                                    await ref
                                                        .read(
                                                          eventServiceProvider,
                                                        )
                                                        .agreeToEvent(
                                                          currentUser.uid,
                                                          event.eventId,
                                                        );

                                                    ref.invalidate(
                                                      eventServiceProvider,
                                                    );
                                                    ref.invalidate(
                                                      userEventsProvider,
                                                    );
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            e.toString(),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            },

                                            if (!event.decliners.contains(
                                              currentUser.uid,
                                            )) ...{
                                              ElevatedButton(
                                                child: Text("Decline"),
                                                onPressed: () async {
                                                  try {
                                                    await ref
                                                        .read(
                                                          eventServiceProvider,
                                                        )
                                                        .declineTheEvent(
                                                          currentUser.uid,
                                                          event.eventId,
                                                        );

                                                    ref.invalidate(
                                                      eventServiceProvider,
                                                    );
                                                    ref.invalidate(
                                                      userEventsProvider,
                                                    );
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            e.toString(),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            },

                                            // Delete button
                                            if (isEventOwner)
                                              Row(
                                                children: [
                                                  // Edit button
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.orange,
                                                    ),
                                                    onPressed: () async {
                                                      try {
                                                        final result =
                                                            await Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder: (context) => EventWizardScreen(
                                                                  groupId: widget
                                                                      .groupId,
                                                                  groupName:
                                                                      group
                                                                          .name,
                                                                  existingEvent:
                                                                      event,
                                                                  groupOwnerId:
                                                                      group
                                                                          .ownerId,
                                                                ),
                                                              ),
                                                            );

                                                        if (result == true) {
                                                          ref.invalidate(
                                                            groupEventsProvider(
                                                              event.groupId,
                                                            ),
                                                          );
                                                          ref.invalidate(
                                                            userEventsProvider,
                                                          );
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Event edited!',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                e.toString(),
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),

                                                  // Delete button
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () async {
                                                      try {
                                                        final eventService = ref
                                                            .read(
                                                              eventServiceProvider,
                                                            );
                                                        await eventService
                                                            .deleteEvent(
                                                              eventOwnerId: event
                                                                  .creatorId,
                                                              groupOwnerId:
                                                                  group.ownerId,
                                                              eventId:
                                                                  event.eventId,
                                                              currentUserId:
                                                                  currentUser
                                                                      .uid,
                                                            );

                                                        ref.invalidate(
                                                          groupEventsProvider(
                                                            event.groupId,
                                                          ),
                                                        );
                                                        ref.invalidate(
                                                          userEventsProvider,
                                                        );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Event deleted!',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                e.toString(),
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                          ],
                                        )
                                      : null,
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Participants: ${event.participants.length}",
                                        ),
                                        Text(
                                          "Decliners: ${event.decliners.length}",
                                        ),
                                        if (!event.isCompleted) ...{
                                          Text(
                                            "Group members ${group.members.length}",
                                          ),
                                        },
                                      ],
                                    ),
                                    Text(event.eventDate.toString()),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        Center(child: const CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Events loading error: $error')),
                  ),
                  Center(
                    child: FloatingActionButton(
                      heroTag: null,
                      child: Text("Create an event"),
                      onPressed: () async {
                        try {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EventWizardScreen(
                                groupId: group.groupId,
                                groupName: group.name,
                              ),
                            ),
                          );

                          if (result == true) {
                            ref.invalidate(groupEventsProvider(group.groupId));
                            ref.invalidate(userEventsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Event created!'),
                                  backgroundColor: Colors.green,
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
