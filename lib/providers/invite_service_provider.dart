import 'package:event_scheduler/models/database_invite_model.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/services/invite_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inviteServiceProvider = Provider<InviteService>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return InviteService(db: firestore);
});

final pendingInvitesProvider = StreamProvider.autoDispose
    .family<List<DatabaseInvite>, String>((ref, userId) {
      final authState = ref.watch(authStateProvider);
      final user = authState.value;

      if (user == null) {
        return Stream.empty();
      }

      final inviteService = ref.watch(inviteServiceProvider);

      return inviteService.getInvites(receiverId: user.uid);
    });
