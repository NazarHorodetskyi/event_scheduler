class FirebaseConstants {
  // collection names
  static const String usersCollection = "users";
  static const String groupsCollection = "groups";
  static const String eventsCollection = "events";

  // user fields
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
  static const String eventCreatorId = "creatorId";
  static const String eventTitle = "title";
  static const String eventDescription = "description";
  static const String eventDate = "date";
  static const String eventParticipants = "participants";
}
