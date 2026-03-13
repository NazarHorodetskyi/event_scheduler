import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/models/database_group_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:event_scheduler/firebase_constants.dart";
import 'package:event_scheduler/exceptions.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DatabaseGroup>> getAllGroups(String userId) async {
    try {
      final snapshot = await _db
          .collection(FirebaseConstants.groupsCollection)
          .where(FirebaseConstants.groupMembers, arrayContains: userId)
          .get();

      List<DatabaseGroup> groups = snapshot.docs.map((doc) {
        return DatabaseGroup.fromMap(doc.data(), doc.id);
      }).toList();

      return groups;
    } catch (e) {
      print("Помилка завантаження груп: $e");
      return [];
    }
  }

  Future<void> createGroup(String ownerId, String groupName) async {
    DocumentReference groupDocRef = _db
        .collection(FirebaseConstants.groupsCollection)
        .doc();
    DatabaseGroup newGroup = DatabaseGroup(
      name: groupName,
      ownerId: ownerId,
      groupId: groupDocRef.id,
      members: [ownerId],
      recentMessage: "Group created",
      recentMessageTime: DateTime.now(),
      description: "",
    );

    WriteBatch batch = _db.batch();
    batch.set(groupDocRef, newGroup.toMap());

    DocumentReference userDocRef = _db
        .collection(FirebaseConstants.usersCollection)
        .doc(ownerId);
    batch.set(userDocRef, {
      FirebaseConstants.userGroups: FieldValue.arrayUnion([groupDocRef.id]),
    }, SetOptions(merge: true));
    await batch.commit().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ConnectionErrorException(),
    );
  }

  Future<void> leaveGroup(String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw UserNotAuthenticatedException();
    final String userId = user.uid;

    DocumentReference groupRef = _db
        .collection(FirebaseConstants.groupsCollection)
        .doc(groupId);
    DocumentSnapshot groupSnapshot = await groupRef.get().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ConnectionErrorException(),
    );

    if (!groupSnapshot.exists) throw GroupNotExistsException();

    final groupData = groupSnapshot.data() as Map<String, dynamic>?;
    List<String> members = List<String>.from(
      groupData?[FirebaseConstants.groupMembers] ?? [],
    );

    String ownerId = groupData?[FirebaseConstants.groupOwnerId] ?? "";

    WriteBatch batch = _db.batch();

    DocumentReference userRef = _db
        .collection(FirebaseConstants.usersCollection)
        .doc(userId);
    batch.update(userRef, {
      FirebaseConstants.userGroups: FieldValue.arrayRemove([groupId]),
    });

    if (members.length == 1 && members.contains(userId)) {
      batch.delete(groupRef);
    } else {
      batch.update(groupRef, {
        FirebaseConstants.groupMembers: FieldValue.arrayRemove([userId]),
      });

      if (userId == ownerId) {
        final newOwner = members.firstWhere(
          (id) => id != userId,
          orElse: () => "",
        );

        if (newOwner.isNotEmpty) {
          batch.update(groupRef, {FirebaseConstants.groupOwnerId: newOwner});
        }
      }
    }

    await batch.commit().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ConnectionErrorException(),
    );
  }
}
