import 'package:event_scheduler/providers/firebase.providers.dart';
import 'package:event_scheduler/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return EventService(db: firestore);
});
