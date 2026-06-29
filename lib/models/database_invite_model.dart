import 'package:event_scheduler/other/firebase_constants.dart';

class DatabaseInvite {
  final String inviteId;
  final String groupId;
  final String groupName;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime statusChangeTime;

  DatabaseInvite({
    required this.inviteId,
    required this.groupId,
    required this.groupName,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.statusChangeTime,
  });

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.inviteId: inviteId,
      FirebaseConstants.inviteGroupId: groupId,
      FirebaseConstants.inviteGroupName: groupName,
      FirebaseConstants.inviteSenderId: senderId,
      FirebaseConstants.inviteReceiverId: receiverId,
      FirebaseConstants.inviteStatus: status,
      FirebaseConstants.inviteTimestamp: statusChangeTime,
    };
  }

  // factory DatabaseInvite.fromMap(Map<String, dynamic> map, )
}
