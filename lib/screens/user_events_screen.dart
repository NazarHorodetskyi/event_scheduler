import 'package:event_scheduler/components/event_card.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:event_scheduler/screens/group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserEventsScreen extends ConsumerStatefulWidget {
  const UserEventsScreen({super.key});

  @override
  ConsumerState<UserEventsScreen> createState() => _UserEventsScreenState();
}

class _UserEventsScreenState extends ConsumerState<UserEventsScreen> {
  int _selectedTabIndex = 0;
  @override
  Widget build(BuildContext context) {
    Future<void> refresh() async {
      await Future.wait([
        ref.refresh(activeUserEventsProvider.future),
        ref.refresh(pastUserEventsProvider.future),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Your events")),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              _selectedTabIndex == 0 ? ActiveUserEvents() : PastUserEvents(),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveUserEvents extends ConsumerWidget {
  const ActiveUserEvents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEvents = ref.watch(activeUserEventsProvider);
    return userEvents.when(
      error: (error, stackTrace) => Center(child: Text("Error: $error")),

      loading: () => Center(child: CircularProgressIndicator()),
      data: (events) {
        if (events.isEmpty) {
          return Center(child: Text("You have no events"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];

            return EventCard(
              event: event,
              isAbleToDelete: false,
              isHistory: false,
              onTap: () async {
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
            );
          },
        );
      },
    );
  }
}

class PastUserEvents extends ConsumerWidget {
  const PastUserEvents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEvents = ref.watch(pastUserEventsProvider);
    return userEvents.when(
      error: (error, stackTrace) => Center(child: Text("Error: $error")),

      loading: () => Center(child: CircularProgressIndicator()),
      data: (events) {
        if (events.isEmpty) {
          return Center(child: Text("You have no history"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];

            return EventCard(
              event: event,
              isAbleToDelete: false,
              isHistory: true,
              onTap: () async {
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
            );
          },
        );
      },
    );
  }
}
