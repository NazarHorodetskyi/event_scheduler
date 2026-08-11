import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {FirebaseConstants} from "./constants";

admin.initializeApp();
const db = admin.firestore();

export const kickUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Only authenticated users can perform this action."
    );
  }

  const currentUserId = request.auth.uid;
  const targetUserId = request.data?.targetUserId;
  const groupId = request.data?.groupId;

  if (!targetUserId || !groupId) {
    throw new HttpsError(
      "invalid-argument",
      "Both targetUserId and groupId must be provided."
    );
  }

  try {
    const groupRef = db.collection(FirebaseConstants.groupsCollection)
      .doc(groupId);
    const groupSnap = await groupRef.get();

    if (!groupSnap.exists) {
      throw new HttpsError("not-found", "Group not found.");
    }

    const groupData = groupSnap.data() as { [key: string]: any };
    const groupOwnerId = groupData[FirebaseConstants.groupOwnerId];

    if (groupOwnerId !== currentUserId) {
      throw new HttpsError(
        "permission-denied",
        "Only the group owner can kick members."
      );
    }

    // Initialize the batch
    const batch = db.batch();

    // 1. Remove user from the group
    batch.update(groupRef, {
      [FirebaseConstants.groupMembers]:
      admin.firestore.FieldValue.arrayRemove(targetUserId),
    });

    // 2. Remove group from the user's profile
    const targetUserRef = db.collection(FirebaseConstants.usersCollection)
      .doc(targetUserId);
    batch.update(targetUserRef, {
      [FirebaseConstants.userGroups]:
      admin.firestore.FieldValue.arrayRemove(groupId),
    });

    // 3. Cascade updates for all events in this group
    const eventsSnap = await db.collection(FirebaseConstants.eventsCollection)
      .where(FirebaseConstants.eventGroupId, "==", groupId)
      .get();

    eventsSnap.forEach((doc) => {
      const eventData = doc.data();
      let needsUpdate = false;
      const updateData: { [key: string]: any } = {};

      // Cnhange owner
      if (eventData[FirebaseConstants.eventOwnerId] === targetUserId) {
        updateData[FirebaseConstants.eventOwnerId] = groupOwnerId;
        needsUpdate = true;
      }

      // B: Check if the user is in the participants array
      const participants = eventData[FirebaseConstants.eventParticipants] || [];
      if (participants.includes(targetUserId)) {
        updateData[FirebaseConstants.eventParticipants] =
        admin.firestore.FieldValue.arrayRemove(targetUserId);
        needsUpdate = true;
      }

      // C: Check if the user is in the decliners array
      const decliners = eventData[FirebaseConstants.eventDecliners] || [];
      if (decliners.includes(targetUserId)) {
        updateData[FirebaseConstants.eventDecliners] =
        admin.firestore.FieldValue.arrayRemove(targetUserId);
        needsUpdate = true;
      }

      // Update if needed
      if (needsUpdate) {
        batch.update(doc.ref, updateData);
      }
    });

    await batch.commit();

    return {success: true, message:
        "User removed and events updated successfully."};
  } catch (error) {
    console.error("Error during kickUser execution:", error);
    throw new HttpsError(
      "internal",
      "An internal server error occurred while removing the user."
    );
  }
});
