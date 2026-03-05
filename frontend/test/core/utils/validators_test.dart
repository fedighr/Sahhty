// test/core/utils/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sahhty/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns null for valid email', () {
      expect(Validators.validateEmail('ahmed@test.tn'), isNull);
      expect(Validators.validateEmail('user.name+tag@domain.co'), isNull);
    });

    test('returns error for empty', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('returns error for invalid format', () {
      expect(Validators.validateEmail('notanemail'), isNotNull);
      expect(Validators.validateEmail('@nodomain.com'), isNotNull);
      expect(Validators.validateEmail('no@'), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns null for strong password', () {
      expect(Validators.validatePassword('Password1!'), isNull);
    });

    test('returns error for too short', () {
      expect(Validators.validatePassword('Pass1!'), isNotNull);
    });

    test('returns error for no uppercase', () {
      expect(Validators.validatePassword('password1!'), isNotNull);
    });

    test('returns error for no digit', () {
      expect(Validators.validatePassword('Password!!'), isNotNull);
    });

    test('returns error for no special char', () {
      expect(Validators.validatePassword('Password1'), isNotNull);
    });
  });

  group('Validators.validatePhone', () {
    test('returns null for valid Tunisian number', () {
      expect(Validators.validatePhone('22345678'), isNull);
      expect(Validators.validatePhone('+21622345678'), isNull);
    });

    test('returns error for invalid number', () {
      expect(Validators.validatePhone('12345'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns null when passwords match', () {
      expect(
        Validators.validateConfirmPassword('Password1!', 'Password1!'),
        isNull,
      );
    });

    test('returns error when passwords differ', () {
      expect(
        Validators.validateConfirmPassword('Password1!', 'DifferentPass1!'),
        isNotNull,
      );
    });
  });
}
