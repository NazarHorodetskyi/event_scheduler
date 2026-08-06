import 'package:event_scheduler/models/database_user_model.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserProfileProvider = StreamProvider<DatabaseUser?>((ref) {
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
    if (snapshot.exists && snapshot.data() != null) {
      return DatabaseUser.fromMap(snapshot.data()!);
    }

    return null;
  });
});
