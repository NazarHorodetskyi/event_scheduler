import 'package:event_scheduler/other/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateNickname', () {
    test('accepts valid nicknames on the boundaries', () {
      expect(AppValidator.validateNickname('abcde'), isNull); // min 5
      expect(AppValidator.validateNickname('a' * 20), isNull); // max 20
      expect(AppValidator.validateNickname('user_123'), isNull);
    });

    test('rejects empty, null and out-of-range lengths', () {
      expect(AppValidator.validateNickname(null), isNotNull);
      expect(AppValidator.validateNickname(''), isNotNull);
      expect(AppValidator.validateNickname('abcd'), isNotNull); // 4
      expect(AppValidator.validateNickname('a' * 21), isNotNull); // 21
    });

    test('rejects spaces, line breaks and non-latin characters', () {
      expect(AppValidator.validateNickname('user name'), isNotNull);
      expect(AppValidator.validateNickname('user\nname'), isNotNull);
      expect(AppValidator.validateNickname('користувач'), isNotNull);
      expect(AppValidator.validateNickname('user-name'), isNotNull);
    });
  });

  group('validateTitle', () {
    test('accepts titles on the boundaries after trimming', () {
      expect(AppValidator.validateTitle('abcde'), isNull);
      expect(AppValidator.validateTitle('a' * 20), isNull);
      expect(AppValidator.validateTitle('  abcde  '), isNull);
    });

    test('rejects empty, whitespace-only and out-of-range titles', () {
      expect(AppValidator.validateTitle(null), isNotNull);
      expect(AppValidator.validateTitle('   '), isNotNull);
      expect(AppValidator.validateTitle('abcd'), isNotNull);
      expect(AppValidator.validateTitle('a' * 21), isNotNull);
      expect(AppValidator.validateTitle('  abcd  '), isNotNull);
    });

    test('rejects line breaks', () {
      expect(AppValidator.validateTitle('title\nnext'), isNotNull);
    });
  });

  group('validateGroupDescription', () {
    test('description is optional', () {
      expect(AppValidator.validateGroupDescription(null), isNull);
      expect(AppValidator.validateGroupDescription(''), isNull);
    });

    test('enforces 100 character limit', () {
      expect(AppValidator.validateGroupDescription('a' * 100), isNull);
      expect(AppValidator.validateGroupDescription('a' * 101), isNotNull);
    });
  });

  group('validateEventDescription', () {
    test('description is optional', () {
      expect(AppValidator.validateEventDescription(null), isNull);
      expect(AppValidator.validateEventDescription('   '), isNull);
    });

    test('enforces 400 character limit with matching message', () {
      expect(AppValidator.validateEventDescription('a' * 400), isNull);
      expect(
        AppValidator.validateEventDescription('a' * 401),
        'Maximum 400 characters',
      );
    });
  });

  group('validatePassword', () {
    test('accepts password of minimum length', () {
      expect(AppValidator.validatePassword('abc123'), isNull);
    });

    test('rejects empty, short and whitespace-containing passwords', () {
      expect(AppValidator.validatePassword(null), isNotNull);
      expect(AppValidator.validatePassword(''), isNotNull);
      expect(AppValidator.validatePassword('abc12'), isNotNull);
      expect(AppValidator.validatePassword('abc 123'), isNotNull);
    });
  });
}
