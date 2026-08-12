export const FirebaseConstants = {
  // Collections
  usersCollection: "users",
  groupsCollection: "groups",
  eventsCollection: "events",
  invitesCollection: "invites",

  // User fields
  userId: "id",
  userGroups: "groupsId",
  email: "email",
  nickname: "nickname",

  // Group fields
  groupDescription: "description",
  groupId: "groupId",
  groupMembers: "members",
  groupName: "name",
  groupOwnerId: "ownerId",
  recentMessage: "recentMessage",
  recentMessageTime: "recentMessageTime",

  // Event fields
  eventGroupId: "eventGroupId",
  eventOwnerId: "creatorId",
  eventTitle: "title",
  eventDescription: "description",
  eventDate: "date",
  eventParticipants: "participants",
  eventDecliners: "decliners",
  eventEditTime: "editTime",
  eventGroupName: "eventGroupName",

  // invite fields
  inviteId: "inviteId",
  inviteGroupId: "groupId",
  inviteGroupName: "groupName",
  inviteSenderId: "senderId",
  inviteReceiverId: "receiverId",
  inviteStatus: "status",
  inviteTimestamp: "statusChangeTime",

  // Invite statuses
  inviteStatusPending: "pending",
  inviteStatusRejected: "rejected",
};


