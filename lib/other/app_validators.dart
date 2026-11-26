class AppValidator {
  static String? validateNickname(String? nickname) {
    if (nickname == null || nickname.isEmpty) {
      return "Nickname cant be empty";
    }

    if (nickname.contains(" ")) {
      return "Nickname cant contain spaces";
    }

    if (nickname.contains('\n') || nickname.contains('\r')) {
      return "Name cant contain line breaks";
    }

    if (nickname.length < 5) {
      return "Nickname must be at least 5 symbols long";
    }

    if (nickname.length > 20) {
      return "Maximum nickname length is 20 symbols";
    }

    final regex = RegExp(r'^[a-zA-Z0-9_]+$');

    if (!regex.hasMatch(nickname)) {
      return "Only english characters, numbers and _";
    }

    return null;
  }

  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return "Title cant be empty";
    }

    if (title.contains('\n') || title.contains('\r')) {
      return "Name cant contain line breaks";
    }

    title = title.trim();

    if (title.length < 5) {
      return "Minimum 5 characters";
    }

    if (title.length > 20) {
      return "Maximum 20 characters";
    }

    return null;
  }

  static String? validateGroupDescription(String? groupDescription) {
    if (groupDescription == null || groupDescription.trim().isEmpty) {
      return null;
    }

    groupDescription = groupDescription.trim();

    if (groupDescription.length > 100) {
      return "Maximum 100 characters";
    }

    return null;
  }

  static String? validateEventDescription(String? eventDescription) {
    if (eventDescription == null || eventDescription.trim().isEmpty) {
      return null;
    }

    eventDescription = eventDescription.trim();

    if (eventDescription.length > 400) {
      return "Maximum 400 characters";
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return "Password cant be empty";
    }

    if (password.contains(' ')) {
      return "Password cant contain spaces";
    }

    if (password.contains('\n') || password.contains('\r')) {
      return "Password cant contain line breaks";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters long";
    }

    return null;
  }
}
