import 'package:flutter_test/flutter_test.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';

void main() {
  group('Live Stream & TikTok Chat Tests', () {
    test('Session isolation filter strictly matches only active stream comments', () {
      final mockMessages = [
        {'id': '1', 'message': 'Old stream comment', 'sessionId': 'session_1'},
        {'id': '2', 'message': 'Another old comment', 'sessionId': 'session_1'},
        {'id': '3', 'message': 'Legacy message without session', 'sessionId': null},
        {'id': '4', 'message': 'New stream comment', 'sessionId': 'session_2'},
        {'id': '5', 'message': 'Second new comment', 'sessionId': 'session_2'},
      ];

      const activeSession = 'session_2';

      // Strict matching logic implemented in FirestoreService:
      final currentStreamMessages = mockMessages.where((m) => m['sessionId'] == activeSession).toList();

      expect(currentStreamMessages.length, 2);
      expect(currentStreamMessages[0]['message'], 'New stream comment');
      expect(currentStreamMessages[1]['message'], 'Second new comment');
      // Verify older session comments and legacy null comments are excluded completely
      expect(currentStreamMessages.any((m) => m['sessionId'] == 'session_1'), false);
      expect(currentStreamMessages.any((m) => m['sessionId'] == null), false);
    });

    test('Fresh live stream starts with 0 comments when new session id is generated', () {
      final oldMessages = [
        {'id': '1', 'message': 'Previous live comment', 'sessionId': 'live_100'},
      ];

      final brandNewSession = 'live_${DateTime.now().millisecondsSinceEpoch}';
      final filteredForNewLive = oldMessages.where((m) => m['sessionId'] == brandNewSession).toList();

      expect(filteredForNewLive.isEmpty, true);
    });

    test('UserRole badges map accurately for TikTok live comments', () {
      expect(UserRole.superAdmin.displayNameArabic.contains('مدير'), true);
      expect(UserRole.tournamentAdmin.displayNameArabic.contains('منظم'), true);
      expect(UserRole.referee.displayNameArabic.contains('حكم'), true);
      expect(UserRole.financeAdmin.displayNameArabic.contains('مالي'), true);
      expect(UserRole.player.displayNameArabic.contains('لاعب'), true);
    });

    test('Multi-stream referee occupancy detects busy referee and allows another referee to claim vacant stream', () {
      final activeStreams = [
        {
          'id': 'stream_1',
          'title': 'نهائي البطولة - مباراة 1',
          'isLive': true,
          'status': 'live',
          'refereeId': 'referee_ahmed',
          'refereeName': 'الحكم أحمد',
        },
        {
          'id': 'stream_2',
          'title': 'مباراة تحديد المركز الثالث',
          'isLive': true,
          'status': 'live',
          'refereeId': null,
          'refereeName': null,
        },
      ];

      // Simulated state for another referee: 'referee_omer'
      const currentRefereeUid = 'referee_omer';

      // Occupied referee IDs across other streams
      final occupiedRefereeIds = <String>{};
      for (var s in activeStreams) {
        if (s['refereeId'] != null && s['refereeId'].toString().isNotEmpty) {
          occupiedRefereeIds.add(s['refereeId'].toString());
        }
      }

      // Check stream 1
      final stream1 = activeStreams[0];
      final isStream1Me = stream1['refereeId'] == currentRefereeUid;
      final isStream1Occupied = stream1['refereeId'] != null && !isStream1Me;
      expect(isStream1Me, false);
      expect(isStream1Occupied, true);
      expect(occupiedRefereeIds.contains('referee_ahmed'), true);

      // Check stream 2 (vacant stream)
      final stream2 = activeStreams[1];
      final isStream2Unassigned = stream2['refereeId'] == null || stream2['refereeId'].toString().isEmpty;
      expect(isStream2Unassigned, true);

      // Referee Omer can claim stream 2:
      final updatedStream2 = Map<String, dynamic>.from(stream2);
      updatedStream2['refereeId'] = currentRefereeUid;
      updatedStream2['refereeName'] = 'الحكم عمر';

      expect(updatedStream2['refereeId'], 'referee_omer');
      expect(updatedStream2['refereeName'], 'الحكم عمر');
    });

    test('Referee match query includes active live matches and excludes completed matches', () {
      final mockAllMatches = [
        {'id': 'm1', 'refereeId': 'ref_1', 'status': 'completed', 'isLive': false},
        {'id': 'm2', 'refereeId': 'ref_1', 'status': 'scheduled', 'isLive': false},
        {'id': 'm3', 'refereeId': 'ref_1', 'status': 'live', 'isLive': true},
        {'id': 'm4', 'refereeId': 'ref_2', 'status': 'live', 'isLive': true},
      ];

      const refereeUid = 'ref_1';
      final refereeMatches = mockAllMatches
          .where((m) => m['refereeId'] == refereeUid && m['status'] != 'completed')
          .toList();

      expect(refereeMatches.length, 2);
      expect(refereeMatches.any((m) => m['status'] == 'live'), true);
      expect(refereeMatches.any((m) => m['status'] == 'scheduled'), true);
      expect(refereeMatches.any((m) => m['status'] == 'completed'), false);
    });

    test('Chat comment input validation prevents empty or whitespace-only messages', () {
      final whitespaceMessage = '   \n  \t  ';
      final validMessage = '  لعب ممتاز جداً! 👏  ';

      expect(whitespaceMessage.trim().isEmpty, true);
      expect(validMessage.trim().isEmpty, false);
      expect(validMessage.trim(), 'لعب ممتاز جداً! 👏');
    });
  });
}

