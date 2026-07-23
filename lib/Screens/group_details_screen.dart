import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:event_scheduler/screens/add_participants_screen.dart';
import 'package:event_scheduler/screens/event_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({super.key, required this.group});

  final DatabaseGroup group;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(groupEventsProvider(widget.group.groupId));
    final currentUser = ref.watch(authServiceProvider).currentUser!;
    final participantsAsync = ref.watch(
      groupParticipantsProvider(widget.group.groupId),
    );

    return Scaffold(
      appBar: AppBar(title: Text("You are in the group: ${widget.group.name}")),
      body: Column(
        children: [
          FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddingScreen(group: widget.group),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              "Participants:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 40,
            child: participantsAsync.when(
              data: (names) {
                if (names.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text("No participants"),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(
                        label: Text(names[index]),
                        backgroundColor: Colors.blue.shade100,
                        side: BorderSide.none,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("Error: $e"),
              ),
            ),
          ),

          const Divider(height: 30),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(child: Text("No events yet"));
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isOwner = currentUser.uid == event.creatorId;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(event.title),
                          subtitle: Text(event.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(event.eventDate.toString().substring(0, 16)),

                              if (!event.participants.contains(
                                currentUser.uid,
                              )) ...{
                                ElevatedButton(
                                  child: Text("Agree"),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(eventServiceProvider)
                                          .agreeToEvent(
                                            currentUser.uid,
                                            event.eventId,
                                          );

                                      ref.invalidate(eventServiceProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
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
                                          .read(eventServiceProvider)
                                          .declineTheEvent(
                                            currentUser.uid,
                                            event.eventId,
                                          );

                                      ref.invalidate(eventServiceProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                                ),
                              },

                              // Delete button
                              if (isOwner)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final eventService = ref.read(
                                        eventServiceProvider,
                                      );
                                      await eventService.deleteEvent(
                                        eventId: event.eventId,
                                        currentUserId: currentUser.uid,
                                      );

                                      ref.invalidate(
                                        groupEventsProvider(event.groupId),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Event deleted!'),
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
                                  },
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text("Participants: ${event.participants.length}"),
                            Text("Decliners: ${event.decliners.length}"),
                            Text(
                              "Group members ${widget.group.members.length}",
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => Center(child: const CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Events loading error: $error')),
            ),
          ),
          Center(
            child: FloatingActionButton(
              heroTag: null,
              child: Text("Create an event"),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        EventWizardScreen(groupId: widget.group.groupId),
                  ),
                );

                ref.invalidate(groupEventsProvider);
              },
            ),
          ),
        ],
      ),
    );
  }
}
