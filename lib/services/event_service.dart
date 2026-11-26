import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/app_limits.dart';
import 'package:event_scheduler/other/app_validators.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/models/database_event_model.dart';

class EventService {
  EventService({required FirebaseFirestore db}) : _db = db;
  final FirebaseFirestore _db;

  Future<void> createEvent({
    required String groupId,
    required String groupName,
    required String creatorId,
    required String title,
    required String description,
    required DateTime eventDate,
  }) async {
    groupName = groupName.trim();
    title = title.trim();
    description = description.trim();

    final titleError = AppValidator.validateTitle(title);
    final descriptionError = AppValidator.validateEventDescription(description);

    if (titleError != null) {
      throw Exception(titleError);
    }

    if (descriptionError != null) {
      throw Exception(descriptionError);
    }

    final AggregateQuerySnapshot countSnapshot = await _db
        .collection(FirebaseConstants.eventsCollection)
        .where(FirebaseConstants.eventGroupId, isEqualTo: groupId)
        .where(FirebaseConstants.eventDate, isGreaterThan: Timestamp.now())
        .count()
        .get();

    final int activeCount = countSnapshot.count ?? 0;

    if (activeCount >= AppLimits.maxGroupActiveEvents) {
      throw Exception("This group reached maximum ammount of active events!");
    }

    DocumentReference eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc();

    EventModel newEvent = EventModel(
      eventId: eventDocRef.id,
      groupId: groupId,
      groupName: groupName,
      creatorId: creatorId,
      title: title,
      description: description,
      eventDate: eventDate,
      participants: [creatorId],
      decliners: [],
    );

    await eventDocRef
        .set(newEvent.toMap())
        .timeout(
          Duration(seconds: 10),
          onTimeout: () => throw ConnectionErrorException(),
        );
  }

  Future<void> updateEvent({
    required String currentUserId,
    required String groupOwnerId,
    required String eventOwnerId,
    required String eventId,
    required Map<String, dynamic> newEventData,
  }) async {
    if (currentUserId != groupOwnerId && currentUserId != eventOwnerId) {
      throw Exception("You do not have enough rights for this operation");
    }

    final titleError = AppValidator.validateTitle(
      newEventData[FirebaseConstants.eventTitle],
    );
    final descriptionError = AppValidator.validateEventDescription(
      newEventData[FirebaseConstants.eventDescription],
    );

    if (titleError != null) {
      throw Exception(titleError);
    }

    if (descriptionError != null) {
      throw Exception(descriptionError);
    }

    Map<String, dynamic> updates = {
      ...newEventData,
      FirebaseConstants.eventEditTime: FieldValue.serverTimestamp(),
    };

    await _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId)
        .update(updates);
  }

  Future<List<EventModel>> getGroupEvents({
    required String groupId,
    required bool isActive,
  }) async {
    try {
      Query query = _db
          .collection(FirebaseConstants.eventsCollection)
          .where(FirebaseConstants.eventGroupId, isEqualTo: groupId);

      if (isActive) {
        query = query
            .where(FirebaseConstants.eventDate, isGreaterThan: Timestamp.now())
            .orderBy(FirebaseConstants.eventDate)
            .limit(20);
      } else {
        query = query
            .where(FirebaseConstants.eventDate, isLessThan: Timestamp.now())
            .orderBy(FirebaseConstants.eventDate, descending: true)
            .limit(20);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // TODO Limits
  Future<List<EventModel>> getUserEvents(
    List<String> groupsId,
    bool isActive,
  ) async {
    if (groupsId.isEmpty) {
      return [];
    }

    try {
      Query query = _db
          .collection(FirebaseConstants.eventsCollection)
          .where(FirebaseConstants.eventGroupId, whereIn: groupsId);

      if (isActive) {
        query = query
            .where(FirebaseConstants.eventDate, isGreaterThan: Timestamp.now())
            .orderBy(FirebaseConstants.eventDate)
            .limit(20);
      } else {
        query = query
            .where(FirebaseConstants.eventDate, isLessThan: Timestamp.now())
            .orderBy(FirebaseConstants.eventDate, descending: true)
            .limit(20);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent({
    required String currentUserId,
    required String eventOwnerId,
    required String groupOwnerId,
    required String eventId,
  }) async {
    try {
      if (currentUserId != eventOwnerId && currentUserId != groupOwnerId) {
        throw Exception("Only owner can delete an event!");
      }

      final eventRef = _db
          .collection(FirebaseConstants.eventsCollection)
          .doc(eventId);
      final eventDoc = await eventRef.get();

      if (!eventDoc.exists) {
        throw Exception("Event not found");
      }

      await eventRef.delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> agreeToEvent(String userId, String eventId) async {
    final eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId);

    await eventDocRef.update({
      FirebaseConstants.eventParticipants: FieldValue.arrayUnion([userId]),
      FirebaseConstants.eventDecliners: FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> declineTheEvent(String userId, String eventId) async {
    final eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId);

    await eventDocRef.update({
      FirebaseConstants.eventParticipants: FieldValue.arrayRemove([userId]),
      FirebaseConstants.eventDecliners: FieldValue.arrayUnion([userId]),
    });
  }
}
