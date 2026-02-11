import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/database_group_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    DocumentReference userDocRef = _db.collection("users").doc(ownerId);
    batch.update(userDocRef, {
      "groupIds": FieldValue.arrayUnion([groupDocRef.id]),
    });

    await batch.commit();
  }
}
