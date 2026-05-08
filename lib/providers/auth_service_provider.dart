import 'package:event_scheduler/providers/firebase_providers.dart';
import 'package:event_scheduler/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(fireStoreProvider);

  return AuthService(firebaseAuth: firebaseAuth, db: firestore);
});
