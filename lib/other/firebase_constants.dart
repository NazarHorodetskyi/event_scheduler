class FirebaseConstants {
  // collection names
  static const String usersCollection = "users";
  static const String groupsCollection = "groups";
  static const String eventsCollection = "events";
  static const String invitesCollection = "invites";

  // user fields
  static const String userId = "id";
  static const String userGroups = "groupIds";
  static const String email = "email";
  static const String nickname = "nickname";
  static const String acceptedEvents = 'acceptedEvents';

  // group fields
  static const String groupDescription = "description";
  static const String groupId = "groupId";
  static const String groupMembers = "members";
  static const String groupName = "name";
  static const String groupOwnerId = "ownerId";
  static const String recentMessage = "recentMessage";
  static const String recentMessageTime = "recentMessageTime";

  // event fields
  static const String eventId = "eventId";
  static const String eventGroupId = "eventGroupId";
  static const String eventOwnerId = "creatorId";
  static const String eventTitle = "title";
  static const String eventDescription = "description";
  static const String eventDate = "date";
  static const String eventParticipants = "participants";
  static const String eventDecliners = "decliners";
  static const String eventEditTime = "editTime";

  // invite fields
  static const String inviteId = "inviteId";
  static const String inviteGroupId = "groupId";
  static const String inviteGroupName = "groupName";
  static const String inviteSenderId = "senderId";
  static const String inviteReceiverId = "receiverId";
  static const String inviteStatus = "status";
  static const String inviteTimestamp = "timestamp";

  // Invite statuses
  static const String inviteStatusPending = "pending";
  static const String inviteStatusRejected = "rejected";
}
