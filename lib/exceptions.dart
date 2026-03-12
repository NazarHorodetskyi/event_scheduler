class CouldNotFindUserInDatabase implements Exception {
  final String message = "Couldnt find this user";
  final String code = "not-in-database";
}

class ConnectionErrorException implements Exception {
  final String message = "Connection error occured";

  @override
  String toString() {
    return message;
  }
}

class UserNotAuthenticatedException implements Exception {
  final String message = "User not authenticated";

  @override
  String toString() {
    return message;
  }
}

class GroupNotExistsException implements Exception {
  final String message = "This group does not exist";

  @override
  String toString() {
    return message;
  }
}
