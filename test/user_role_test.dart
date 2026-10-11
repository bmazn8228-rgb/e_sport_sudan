import 'package:flutter_test/flutter_test.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';

void main() {
  group('UserRole & Promotion Permissions', () {
    test('Super Admin has highest rank (100) and can promote users', () {
      expect(UserRole.superAdmin.rank, 100);
      expect(UserRole.superAdmin.canPromoteUser(UserRole.player), isTrue);
      expect(UserRole.superAdmin.canPromoteUser(UserRole.referee), isTrue);
      expect(UserRole.superAdmin.canPromoteUser(UserRole.tournamentAdmin), isTrue);
      expect(UserRole.superAdmin.canPromoteUser(UserRole.financeAdmin), isTrue);
      expect(UserRole.superAdmin.canPromoteUser(UserRole.superAdmin), isTrue);
    });

    test('Super Admin can assign any role', () {
      for (final role in UserRole.values) {
        expect(UserRole.superAdmin.canAssignRole(role), isTrue);
      }
      expect(UserRole.superAdmin.availableRolesToAssign.length, UserRole.values.length);
    });

    test('Non-superAdmin roles cannot promote users or assign roles', () {
      final nonSuperRoles = [
        UserRole.tournamentAdmin,
        UserRole.financeAdmin,
        UserRole.referee,
        UserRole.player,
      ];

      for (final role in nonSuperRoles) {
        expect(role.canPromoteUser(UserRole.player), isFalse);
        expect(role.canAssignRole(UserRole.referee), isFalse);
        expect(role.availableRolesToAssign, isEmpty);
      }
    });

    test('UserRole serialization and deserialization works correctly', () {
      expect(UserRole.fromValue('super_admin'), UserRole.superAdmin);
      expect(UserRole.fromValue('tournament_admin'), UserRole.tournamentAdmin);
      expect(UserRole.fromValue('finance_admin'), UserRole.financeAdmin);
      expect(UserRole.fromValue('referee'), UserRole.referee);
      expect(UserRole.fromValue('player'), UserRole.player);
      expect(UserRole.fromValue('unknown'), UserRole.player);
      expect(UserRole.fromValue(null), UserRole.player);

      expect(UserRole.superAdmin.toValue(), 'super_admin');
      expect(UserRole.tournamentAdmin.toValue(), 'tournament_admin');
      expect(UserRole.financeAdmin.toValue(), 'finance_admin');
      expect(UserRole.referee.toValue(), 'referee');
      expect(UserRole.player.toValue(), 'player');
    });
  });
}
