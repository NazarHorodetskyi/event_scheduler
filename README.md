# Event Scheduler

A mobile app for planning events within groups. Users create groups, invite members, schedule events, and respond with accept or decline. Each group shows its upcoming events and event history.

**Stack:** Flutter (Dart), Riverpod, Firebase Auth, Cloud Firestore, Cloud Functions (TypeScript)

## Data quality and integrity

- **Multi-layer validation.** Input is checked in UI forms, again in the service layer before every write, and limits are also enforced in Firestore security rules. See [`lib/other/app_validators.dart`](lib/other/app_validators.dart).
- **Documented constraints.** Field rules (length, allowed characters, required/optional) are in [`lib/Restrictions.txt`](lib/Restrictions.txt), and business limits (groups per user, members per group, active events per group) are in [`lib/other/app_limits.dart`](lib/other/app_limits.dart).
- **Referential integrity.** Cascading changes use atomic batch writes. Removing a member updates the group, the user profile and every related event in one batch ([`functions/src/index.ts`](functions/src/index.ts)). Deleting a group also removes its events and invites.
- **Unit tests** cover the validators: boundary values, equivalence classes and invalid characters ([`test/app_validators_test.dart`](test/app_validators_test.dart)).

## Project structure

```
lib/
  models/      Firestore document models (user, group, event, invite)
  services/    Data access and business rules
  providers/   Riverpod providers
  screens/     UI
  other/       Validators, limits, constants, exceptions
functions/     Cloud Functions (server-side operations, e.g. kickUser)
test/          Unit tests
```

## Running

```bash
flutter pub get
flutter test
flutter run
```

The app needs its own Firebase project; configure one with `flutterfire configure`.

## Status

This is a pet project and work in progress. Planned next: pagination, more tests (services, with a Firestore emulator), and stricter role checks in security rules.
