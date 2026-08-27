import 'package:event_scheduler/models/database_event_model.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/providers/group_service_provider.dart';
import 'package:event_scheduler/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return EventService(db: firestore);
});

// Active events
final activeGroupEventsProvider =
    FutureProvider.family<List<EventModel>, String>((ref, groupId) async {
      final eventService = ref.watch(eventServiceProvider);

      return eventService.getGroupEvents(groupId: groupId, isActive: true);
    });

// History
final pastGroupEventsProvider = FutureProvider.family<List<EventModel>, String>(
  (ref, groupId) async {
    final eventService = ref.watch(eventServiceProvider);

    return eventService.getGroupEvents(groupId: groupId, isActive: false);
  },
);

final activeUserEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final userGroups = await ref.watch(userGroupsProvider.future);
  final groupsId = userGroups.map((group) => group.groupId).toList();

  final eventService = ref.watch(eventServiceProvider);
  return eventService.getUserEvents(groupsId, true);
});

final pastUserEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final userGroups = await ref.watch(userGroupsProvider.future);
  final groupsId = userGroups.map((group) => group.groupId).toList();

  final eventService = ref.watch(eventServiceProvider);
  return eventService.getUserEvents(groupsId, false);
});
