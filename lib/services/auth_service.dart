import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/models/database_user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore db,
  }) : _firebaseAuth = firebaseAuth,
       _db = db;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _db;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<DatabaseUser> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;
    final docSnapshot = await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();

      return DatabaseUser.fromMap(data!, uid);
    } else {
      throw CouldNotFindUserInDatabase();
    }
  }

  Future<DatabaseUser> createUser({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    DatabaseUser newUser = DatabaseUser(
      uid: userCredential.user!.uid,
      email: email,
      nickname: "User",
      groupIds: [],
      acceptedEvents: [],
    );

    await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(newUser.uid)
        .set(newUser.toMap());

    return newUser;
  }

  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    return await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    return await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteUser({required String password}) async {
    try {
      final user = currentUser;
      if (user == null) return;

      AuthCredential credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credentials);

      final String userId = user.uid;

      DocumentSnapshot userDoc = await _db
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        List<String> userGroups = List<String>.from(
          userData?[FirebaseConstants.groupsCollection] ?? [],
        );

        WriteBatch batch = _db.batch();

        for (String groupId in userGroups) {
          DocumentReference groupRef = _db
              .collection(FirebaseConstants.groupsCollection)
              .doc(groupId);
          DocumentSnapshot groupSnapshot = await groupRef.get();

          if (groupSnapshot.exists) {
            final groupData = groupSnapshot.data() as Map<String, dynamic>?;
            List<String> members = List<String>.from(
              groupData?[FirebaseConstants.groupMembers] ?? [],
            );
            String ownerId = groupData?[FirebaseConstants.groupOwnerId] ?? '';

            if (members.length == 1 && members.contains(userId)) {
              batch.delete(groupRef);
            } else {
              batch.update(groupRef, {
                FirebaseConstants.groupMembers: FieldValue.arrayRemove([
                  userId,
                ]),
              });

              if (ownerId == userId) {
                String newOwner = members.firstWhere(
                  (id) => id != userId,
                  orElse: () => '',
                );
                if (newOwner.isNotEmpty) {
                  batch.update(groupRef, {
                    FirebaseConstants.groupOwnerId: newOwner,
                  });
                }
              }
            }
          }
        }

        DocumentReference userRef = _db
            .collection(FirebaseConstants.usersCollection)
            .doc(userId);
        batch.delete(userRef);
        await batch.commit();
        print("--- ✅ Дані користувача повністю вичищено з бази ---");
      }

      await user.delete();
      print("--- 🗑️ Акаунт успішно видалено назавжди ---");
    } catch (e) {
      print("--- ❌ Помилка видалення акаунту: $e ---");
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: currentUser!.email!,
      password: oldPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
    return;
  }
}
