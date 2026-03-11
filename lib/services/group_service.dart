import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/database_group_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DatabaseGroup>> getAllGroups(String userId) async {
    try {
      final snapshot = await _db
          .collection('groups')
          .where('members', arrayContains: userId)
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

  Future<void> createGroup(
    String ownerId,
    String userName,
    String groupName,
  ) async {
    DocumentReference groupDocRef = _db.collection("groups").doc();
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

    DocumentReference userDocRef = _db.collection('users').doc(ownerId);
    batch.set(userDocRef, {
      'groupIds': FieldValue.arrayUnion([groupDocRef.id]),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final String userId = user.uid;

      DocumentReference groupRef = _db.collection("groups").doc(groupId);
      DocumentSnapshot groupSnapshot = await groupRef.get();

      if (!groupSnapshot.exists) return;

      final groupData = groupSnapshot.data() as Map<String, dynamic>?;
      List<String> members = List<String>.from(groupData?["members"] ?? []);

      String ownerId = groupData?["ownerId"] ?? "";

      WriteBatch batch = _db.batch();

      DocumentReference userRef = _db.collection("users").doc(userId);
      batch.update(userRef, {
        "groupIds": FieldValue.arrayRemove([groupId]),
      });

      if (members.length == 1 && members.contains(userId)) {
        batch.delete(groupRef);
      } else {
        batch.update(groupRef, {
          "members": FieldValue.arrayRemove([userId]),
        });

        if (userId == ownerId) {
          final newOwner = members.firstWhere(
            (id) => id != userId,
            orElse: () => "",
          );

          if (newOwner.isNotEmpty) {
            batch.update(groupRef, {"ownerId": newOwner});
          }
        }
      }

      await batch.commit();
    } catch (e) {
      print("Помилка $e");
    }
  }
}
