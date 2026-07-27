import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/services/group_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return GroupService(db: firestore);
});

final userGroupsProvider = FutureProvider<List<DatabaseGroup>>((ref) async {
  final groupService = ref.watch(groupServiceProvider);
  final auth = ref.watch(firebaseAuthProvider);

  final userId = auth.currentUser?.uid;
  if (userId == null) return [];

  return groupService.getAllGroups(userId);
});

final groupParticipantsProvider = FutureProvider.family<List<String>, String>((
  ref,
  groupId,
) async {
  final service = await ref.watch(groupDetailsProvider(groupId).future);

  if (service.members.isEmpty) {
    return [];
  }

  try {
    return await ref.read(authServiceProvider).getNamesByIds(service.members);
  } catch (e) {
    return [];
  }
});

final groupDetailsProvider = FutureProvider.autoDispose
    .family<DatabaseGroup, String>((ref, groupId) {
      final groupService = ref.watch(groupServiceProvider);
      return groupService.getGroupById(groupId: groupId);
    });
