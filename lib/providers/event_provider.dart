import 'package:event_scheduler/models/database_event_model.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupEventsProvider = FutureProvider.family<List<EventModel>, String>((
  ref,
  groupId,
) async {
  final eventService = ref.watch(eventServiceProvider);

  return eventService.getAllEvents(groupId);
});
