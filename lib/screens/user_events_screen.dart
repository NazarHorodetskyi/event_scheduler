import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:event_scheduler/screens/group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserEventsScreen extends ConsumerWidget {
  const UserEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() async {
      await Future.wait([ref.refresh(userEventsProvider.future)]);
    }

    final userEvents = ref.watch(userEventsProvider);
    return Scaffold(
      appBar: AppBar(title: Text("Your events")),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: userEvents.when(
            error: (error, stackTrace) => Center(child: Text("Error: $error")),

            loading: () => Center(child: CircularProgressIndicator()),
            data: (events) {
              if (events.isEmpty) {
                return Center(child: Text("You have no events"));
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
                physics: NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];

                  return Opacity(
                    opacity: event.isCompleted ? 0.6 : 1,
                    child: Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        onTap: event.isCompleted
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupDetailsScreen(
                                      groupId: event.groupId,
                                      groupName: event.groupName,
                                    ),
                                  ),
                                );
                              },
                        title: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(events[index].title),
                            ),
                            Text("from group ${event.groupName}"),
                          ],
                        ),
                        trailing: Text(event.eventDate.toString()),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
