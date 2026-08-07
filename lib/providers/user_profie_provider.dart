import 'package:event_scheduler/models/database_user_model.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserDataProvider = StreamProvider<DatabaseUser>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;

  if (user == null) {
    return const Stream.empty();
  }

  final userSnapshots = ref
      .watch(fireStoreProvider)
      .collection(FirebaseConstants.usersCollection)
      .doc(user.uid)
      .snapshots();

  return userSnapshots.map((snapshot) {
    return DatabaseUser.fromMap(snapshot.data()!);
  });
});

final userProfileProvider = Provider<({String nickname, String email})>((ref) {
  final profileData = ref.watch(
    currentUserDataProvider.select(
      (user) => (
        nickname: user.value?.nickname ?? "Loading",
        email: user.value?.email ?? "Unknown",
      ),
    ),
  );

  return profileData;
});
