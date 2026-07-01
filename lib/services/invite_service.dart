import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/models/database_invite_model.dart';
import 'package:event_scheduler/other/firebase_constants.dart';

class InviteService {
  InviteService({required FirebaseFirestore db}) : _db = db;
  final FirebaseFirestore _db;

  // TODO Get invites and store in memory (status pending)

  Future<void> sendInvite({
    required String groupId,
    required String groupName,
    required String senderId,
    required String receiverId,
  }) async {
    final String inviteId = '${groupId}_$receiverId';

    final inviteSnapshot = await _db
        .collection(FirebaseConstants.invitesCollection)
        .doc(inviteId)
        .get();

    //  if invite alredy sent
    if (inviteSnapshot.exists) {
      final inviteData = inviteSnapshot.data()!;
      // User not responded
      if (inviteData[FirebaseConstants.inviteStatus] ==
          FirebaseConstants.inviteStatusPending) {
        throw Exception("User alreedy have your invite");
      }

      // If exist and rejected
      if (inviteData[FirebaseConstants.inviteStatus] ==
          FirebaseConstants.inviteStatusRejected) {
        // recentle denied
        if (DateTime.now()
                .difference(
                  (inviteData[FirebaseConstants.inviteTimestamp] as Timestamp)
                      .toDate(),
                )
                .inHours <
            2) {
          throw Exception(
            "User recently rejected your invite, try again later",
          );
        } else {
          // more than 2 hours - can send an invite again
          await inviteSnapshot.reference.update({
            FirebaseConstants.inviteStatus:
                FirebaseConstants.inviteStatusPending,
            FirebaseConstants.inviteTimestamp: DateTime.now(),
          });
          return;
        }
      }
    }

    final newInvite = DatabaseInvite(
      inviteId: inviteId,
      groupId: groupId,
      groupName: groupName,
      senderId: senderId,
      receiverId: receiverId,
      status: FirebaseConstants.inviteStatusPending,
      statusChangeTime: DateTime.now(),
    );

    await _db
        .collection(FirebaseConstants.invitesCollection)
        .doc(inviteId)
        .set(newInvite.toMap());
  }

  Future<void> acceptInvite({
    required String inviteId,
    required String receiverId,
    required String groupId,
  }) async {
    try {
      // Existence check
      final groupSnapshot = await _db
          .collection(FirebaseConstants.groupsCollection)
          .doc(groupId)
          .get();

      if (!groupSnapshot.exists) {
        throw Exception("Group does not exist");
      }

      WriteBatch batch = _db.batch();

      // Add to the group members
      batch.update(groupSnapshot.reference, {
        FirebaseConstants.groupMembers: FieldValue.arrayUnion([receiverId]),
      });

      // Add group to user groups
      final userDocRef = _db
          .collection(FirebaseConstants.usersCollection)
          .doc(receiverId);
      batch.update(userDocRef, {
        FirebaseConstants.userGroups: FieldValue.arrayUnion([groupId]),
      });

      // Delete invite doc
      final inviteDocRef = _db
          .collection(FirebaseConstants.invitesCollection)
          .doc(inviteId);
      batch.delete(inviteDocRef);

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectInvite({required String inviteId}) async {
    try {
      final inviteDocRef = _db
          .collection(FirebaseConstants.invitesCollection)
          .doc(inviteId);
      await inviteDocRef.update({
        FirebaseConstants.inviteStatus: FirebaseConstants.inviteStatusRejected,
        FirebaseConstants.inviteTimestamp: DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
