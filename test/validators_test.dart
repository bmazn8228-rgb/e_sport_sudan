import 'package:flutter_test/flutter_test.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('accepts admin emails with non-gmail domains', () {
      expect(Validators.validateEmail('superadmin@esportsudan.sd'), isNull);
      expect(Validators.validateEmail('tournament@esportsudan.sd'), isNull);
      expect(Validators.validateEmail('referee@esportsudan.sd'), isNull);
      expect(Validators.validateEmail('finance@esportsudan.sd'), isNull);
      expect(Validators.validateEmail('admin@custom.org'), isNull);
      expect(Validators.validateEmail('admin@esport.online'), isNull);
      expect(Validators.validateEmail('admin@portal.esports'), isNull);
      expect(Validators.validateEmail('admin.lead@sub.domain.co'), isNull);
    });

    test('accepts standard gmail emails', () {
      expect(Validators.validateEmail('player@gmail.com'), isNull);
      expect(Validators.validateEmail('user.name+tag@gmail.com'), isNull);
    });

    test('handles leading and trailing whitespace properly', () {
      expect(Validators.validateEmail('  superadmin@esportsudan.sd  '), isNull);
    });

    test('rejects empty or malformed emails', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('not-an-email'), isNotNull);
      expect(Validators.validateEmail('@domain.com'), isNotNull);
      expect(Validators.validateEmail('admin@'), isNotNull);
      expect(Validators.validateEmail('admin@domain'), isNotNull);
    });
  });
}
