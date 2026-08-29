import 'package:event_scheduler/components/event_card.dart';
import 'package:event_scheduler/models/database_group_model.dart';
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
  int _selectedTabIndex = 0;

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(groupDetailsProvider(widget.groupId).future),
      ref.refresh(activeGroupEventsProvider(widget.groupId).future),
      ref.refresh(pastGroupEventsProvider(widget.groupId).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final groupData = ref.watch(groupDetailsProvider(widget.groupId));
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
                              ref.invalidate(activeUserEventsProvider);
                              ref.invalidate(pastUserEventsProvider);
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
                                            ref.invalidate(
                                              activeGroupEventsProvider,
                                            );
                                            ref.invalidate(
                                              pastGroupEventsProvider,
                                            );

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
                  // TABS CHOICE
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Active Events'),
                        selected: _selectedTabIndex == 0,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedTabIndex = 0);
                        },
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('History'),
                        selected: _selectedTabIndex == 1,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedTabIndex = 1);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _selectedTabIndex == 0
                      ? ActiveGroupEventsList(group: group)
                      : PastGroupEventsList(group: group),

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
                            ref.invalidate(
                              activeGroupEventsProvider(group.groupId),
                            );
                            ref.invalidate(activeUserEventsProvider);
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

class ActiveGroupEventsList extends ConsumerWidget {
  final DatabaseGroup group;

  const ActiveGroupEventsList({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activeGroupEventsProvider(group.groupId));
    final currentUser = ref.watch(authServiceProvider).currentUser!;

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text("No events yet"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isAbleToDelete =
                ((currentUser.uid == event.creatorId) ||
                (currentUser.uid == group.ownerId));
            return EventCard(
              event: event,
              isAbleToDelete: isAbleToDelete,
              isHistory: false,
              group: group,
            );
          },
        );
      },
      loading: () => Center(child: const CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Events loading error: $error')),
    );
  }
}

class PastGroupEventsList extends ConsumerWidget {
  final DatabaseGroup group;

  const PastGroupEventsList({super.key, required this.group});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(pastGroupEventsProvider(group.groupId));
    final currentUser = ref.watch(authServiceProvider).currentUser!;

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text("History is empty!"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isAbleToDelete =
                ((currentUser.uid == event.creatorId) ||
                (currentUser.uid == group.ownerId));
            return EventCard(
              event: event,
              isAbleToDelete: isAbleToDelete,
              isHistory: true,
              group: group,
            );
          },
        );
      },
      loading: () => Center(child: const CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Events loading error: $error')),
    );
  }
}
