import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseGroup {
  final String name;
  final String ownerId;
  final String groupId;
  final List<String> members;
  final String recentMessage;
  final DateTime? recentMessageTime;
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

  factory DatabaseGroup.fromMap(Map<String, dynamic> map, String id) {
    return DatabaseGroup(
      name: map["name"] ?? '',
      ownerId: map["ownerId"] ?? "",
      groupId: map["groupId"] ?? "",
      members: List<String>.from(map["members"] ?? []),
      recentMessage: map["recentMessage"] ?? "",
      recentMessageTime: map['recentMessageTime'] != null
          ? (map['recentMessageTime'] as Timestamp).toDate()
          : null,
      description: map["description"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "ownerId": ownerId,
      "groupId": groupId,
      "members": members,
      "recentMessage": recentMessage,
      "recentMessageTime": recentMessageTime,
      "description": description,
    };
  }
}
