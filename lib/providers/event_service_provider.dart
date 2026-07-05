import 'package:event_scheduler/models/database_event_model.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return EventService(db: firestore);
});

final groupEventsProvider = FutureProvider.family<List<EventModel>, String>((
  ref,
  groupId,
) async {
  final eventService = ref.watch(eventServiceProvider);

  return eventService.getAllEvents(groupId: groupId);
});
