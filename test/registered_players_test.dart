import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

void main() {
  testWidgets('Verify user card renders promote/demote button without infinite width error', (tester) async {
    final user = {
      'uid': 'user123',
      'displayName': 'أحمد محمد',
      'email': 'ahmed@gmail.com',
      'ign': 'AhmedPro',
      'phone': '+249912345678',
      'playerId': 'user123',
      'role': 'player',
    };

    final userRole = UserRole.fromValue(user['role']);

    // Build the user card UI under darkTheme (which has elevatedButtonTheme with infinite width default)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مستوى الرتبة: ${userRole.rank}'),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.swap_vert_rounded, size: 16),
                  label: const Text('ترقية / تخفيض الرتبة ⚡'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('ترقية / تخفيض الرتبة ⚡'), findsOneWidget);
    expect(find.text('مستوى الرتبة: 10'), findsOneWidget);
  });
}
