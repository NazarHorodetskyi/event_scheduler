import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/models/database_group_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:event_scheduler/other/firebase_constants.dart";
import 'package:event_scheduler/other/exceptions.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GroupService {
  GroupService({required FirebaseFirestore db}) : _db = db;

  final FirebaseFirestore _db;

  Future<DatabaseGroup> getGroupById({required String groupId}) async {
    try {
      final snapshot = await _db
          .collection(FirebaseConstants.groupsCollection)
          .doc(groupId)
          .get();
      final data = snapshot.data();

      if (data != null) {
        return DatabaseGroup.fromMap(data);
      } else {
        throw Exception("Group doesnt exist");
      }
    } catch (e) {
      rethrow;
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
    Map<String, dynamic> groupData = newGroup.toMap();
    groupData[FirebaseConstants.recentMessageTime] =
        FieldValue.serverTimestamp();

    batch.set(groupDocRef, groupData);

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

    // Group events
    final groupEvents = await _db
        .collection(FirebaseConstants.eventsCollection)
        .where(FirebaseConstants.eventGroupId, isEqualTo: groupId)
        .get();

    String ownerId = groupData?[FirebaseConstants.groupOwnerId] ?? "";
    bool deleteGroup = (members.length == 1) && members.contains(userId);

    WriteBatch batch = _db.batch();
    // New owner
    if (userId == ownerId && !deleteGroup) {
      ownerId = members.firstWhere((id) => id != userId, orElse: () => "");

      batch.update(groupRef, {FirebaseConstants.groupOwnerId: ownerId});
    }

    // Delete group from user
    DocumentReference userRef = _db
        .collection(FirebaseConstants.usersCollection)
        .doc(userId);
    batch.update(userRef, {
      FirebaseConstants.userGroups: FieldValue.arrayRemove([groupId]),
    });

    // Delete user from group
    if (deleteGroup) {
      batch.delete(groupRef);
      // Delete group events
      for (var doc in groupEvents.docs) {
        batch.delete(doc.reference);
      }
      // Delete invites to this group
      final invitesSnapshot = await _db
          .collection(FirebaseConstants.invitesCollection)
          .where(FirebaseConstants.inviteGroupId, isEqualTo: groupId)
          .get();

      for (var doc in invitesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw ConnectionErrorException(),
      );

      return;
    } else {
      batch.update(groupRef, {
        FirebaseConstants.groupMembers: FieldValue.arrayRemove([userId]),
      });
    }

    // Remove user from any events
    for (var doc in groupEvents.docs) {
      final eventData = doc.data();

      // Standart update
      Map<String, dynamic> eventUpdates = {
        FirebaseConstants.eventParticipants: FieldValue.arrayRemove([userId]),
        FirebaseConstants.eventDecliners: FieldValue.arrayRemove([userId]),
      };
      // If user is owner
      if (eventData[FirebaseConstants.eventOwnerId] == userId) {
        eventUpdates[FirebaseConstants.eventOwnerId] = ownerId;
      }
      batch.update(doc.reference, eventUpdates);
    }

    await batch.commit().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ConnectionErrorException(),
    );
  }

  Future<List<String>> getGroupMembers(String groupId) async {
    try {
      final groupSnapshot = await _db
          .collection(FirebaseConstants.groupsCollection)
          .doc(groupId)
          .get();

      if (!groupSnapshot.exists) return [];

      List<String> participantsId = List<String>.from(
        groupSnapshot.data()?[FirebaseConstants.groupMembers] ?? [],
      );

      if (participantsId.isEmpty) {
        return [];
      }

      final userFutures = participantsId.map(
        (String id) =>
            _db.collection(FirebaseConstants.usersCollection).doc(id).get(),
      );

      final userSnapshots = await Future.wait(userFutures);

      return userSnapshots
          .where((doc) => doc.exists)
          .map(
            (doc) =>
                doc.data()?[FirebaseConstants.nickname]?.toString() ??
                'Unknown',
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> changeGroupName({
    required String currentUserId,
    required String groupOwnerId,
    required String groupId,
    required String newName,
  }) async {
    final trimmedName = newName.trim();

    if (currentUserId != groupOwnerId) {
      throw Exception("You do not have enough rights for this information");
    }

    if (trimmedName.length < 5) {
      throw Exception("Name should be at least 5 symbols long");
    }

    final groupSnapshot = await _db
        .collection(FirebaseConstants.groupsCollection)
        .doc(groupId)
        .get();

    if (!groupSnapshot.exists) {
      throw Exception("Group doesnt exist");
    }

    final groupEvents = await _db
        .collection(FirebaseConstants.eventsCollection)
        .where(FirebaseConstants.eventGroupId, isEqualTo: groupId)
        .get();

    WriteBatch batch = _db.batch();
    // New name for group
    batch.update(groupSnapshot.reference, {
      FirebaseConstants.groupName: newName,
    });

    // New groupName for events in group
    for (var doc in groupEvents.docs) {
      if (doc.exists) {
        batch.update(doc.reference, {
          FirebaseConstants.eventGroupName: trimmedName,
        });
      }
    }

    await batch.commit();
  }

  Future<void> kickParticipant({
    required String groupId,
    required String targetUserId,
  }) async {
    try {
      // 1. Initialize the callable function with the EXACT name from index.ts
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'kickUser',
      );

      await callable.call({'groupId': groupId, 'targetUserId': targetUserId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception("Backend error: ${e.message} ");
    } catch (e) {
      throw Exception("Failed to kick user");
    }
  }
}
