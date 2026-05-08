import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/services/group_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return GroupService(db: firestore);
});
