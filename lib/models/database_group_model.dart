import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/firebase_constants.dart';

class DatabaseGroup {
  final String name;
  final String ownerId;
  final String groupId;
  final List<String> members;
  final String recentMessage;
  final DateTime recentMessageTime;
  final String description;

  DatabaseGroup({
    required this.name,
    required this.ownerId,
    required this.groupId,
    required this.members,
    required this.recentMessage,
    required this.recentMessageTime,
    required this.description,
  });

  factory DatabaseGroup.fromMap(Map<String, dynamic> map) {
    return DatabaseGroup(
      name: map[FirebaseConstants.groupName] ?? '',
      ownerId: map[FirebaseConstants.groupOwnerId] ?? "",
      groupId: map[FirebaseConstants.groupId] ?? "",
      members: List<String>.from(map[FirebaseConstants.groupMembers] ?? []),
      recentMessage: map[FirebaseConstants.recentMessage] ?? "",
      recentMessageTime: map[FirebaseConstants.recentMessageTime] != null
          ? (map[FirebaseConstants.recentMessageTime] as Timestamp).toDate()
          : DateTime.now(), // Заглушка...
      description: map[FirebaseConstants.groupDescription] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.groupName: name,
      FirebaseConstants.groupOwnerId: ownerId,
      FirebaseConstants.groupId: groupId,
      FirebaseConstants.groupMembers: members,
      FirebaseConstants.recentMessage: recentMessage,
      FirebaseConstants.recentMessageTime: Timestamp.fromDate(
        recentMessageTime,
      ),
      FirebaseConstants.groupDescription: description,
    };
  }
}
