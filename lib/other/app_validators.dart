class AppValidator {
  static String? validateNickname(String? nickname) {
    if (nickname == null || nickname.isEmpty) {
      return "Nickname cant be empty";
    }

    if (nickname.contains(" ")) {
      return "Nickname cant contain spaces";
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
}
