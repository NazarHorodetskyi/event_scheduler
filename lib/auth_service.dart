import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:event_scheduler/database_user_model.dart";

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<DatabaseUser> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;
    final docSnapshot = await _db.collection("users").doc(uid).get();

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
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    DatabaseUser newUser = DatabaseUser(
      uid: userCredential.user!.uid,
      email: email,
      nickname: "User",
      groupIds: [],
    );

    await _db.collection("users").doc(newUser.uid).set(newUser.toMap());

    return newUser;
  }

  Future<void> signOut() async {
    return await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    return await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    return await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteUser({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
    return;
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
