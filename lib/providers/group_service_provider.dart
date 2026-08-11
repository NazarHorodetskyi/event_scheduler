import 'package:event_scheduler/models/database_group_model.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/providers/user_profie_provider.dart';
import 'package:event_scheduler/services/group_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return GroupService(db: firestore);
});

final userGroupsProvider = FutureProvider<List<DatabaseGroup>>((ref) async {
  final groupIds = ref.watch(
    currentUserDataProvider.select((user) => user.value?.groupsId ?? []),
  );

  if (groupIds.isEmpty) {
    return [];
  }

  final firestore = ref.watch(fireStoreProvider);
  final groupsSnapshot = await firestore
      .collection(FirebaseConstants.groupsCollection)
      .where(FirebaseConstants.groupId, whereIn: groupIds)
      .get();

  return groupsSnapshot.docs
      .map((doc) => DatabaseGroup.fromMap(doc.data()))
      .toList();
});

final groupDetailsProvider = FutureProvider.autoDispose
    .family<DatabaseGroup, String>((ref, groupId) {
      final groupService = ref.watch(groupServiceProvider);
      return groupService.getGroupById(groupId: groupId);
    });

final groupParticipantsProvider =
    FutureProvider.family<List<({String id, String nickname})>, String>((
      ref,
      groupId,
    ) async {
      final service = await ref.watch(groupDetailsProvider(groupId).future);

      if (service.members.isEmpty) {
        return [];
      }

      try {
        return await ref
            .read(authServiceProvider)
            .getNamesByIds(service.members);
      } catch (e) {
        return [];
      }
    });
