import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/event_provider.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text("You are in the group: ${widget.group.name}")),
      body: Column(
        children: [
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
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(event.eventDate.toString().substring(0, 16)),

                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Event deleted!'),
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
                        ],
                      ),
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
