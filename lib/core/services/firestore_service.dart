import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // =========================================================================
  // 1. Users & Admin Roles
  // =========================================================================
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserSettings(String uid, UserSettings settings) async {
    await _db.collection('users').doc(uid).set({'settings': settings.toMap()}, SetOptions(merge: true));
  }

  // =========================================================================
  // 2. Tournaments (البطولات)
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getTournamentsStream({String? game}) {
    Query query = _db.collection('tournaments').orderBy('startDate', descending: true);
    if (game != null && game.isNotEmpty) {
      query = query.where('game', isEqualTo: game);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<void> createTournament(Map<String, dynamic> tournamentData) async {
    await _db.collection('tournaments').add(tournamentData);
  }

  Future<void> updateTournamentStatus(String tournamentId, String newStatus) async {
    await _db.collection('tournaments').doc(tournamentId).update({'status': newStatus});
  }

  // =========================================================================
  // 3. Teams (الفرق)
  // =========================================================================
  Future<void> registerTeam(Map<String, dynamic> teamData) async {
    await _db.collection('teams').add(teamData);
  }

  Stream<List<Map<String, dynamic>>> getTeamsStream({required String game}) {
    return _db
        .collection('teams')
        .where('game', isEqualTo: game)
        .orderBy('points', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // =========================================================================
  // 4. Rankings & Game Stats (التصنيفات وإحصائيات الألعاب)
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getRankingsStream({
    required String game,
    required String type, // 'teams' or 'players'
    String season = 'Season 1',
  }) {
    return _db
        .collection('rankings')
        .where('game', isEqualTo: game)
        .where('type', isEqualTo: type)
        .where('season', isEqualTo: season)
        .orderBy('mmr', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      // Calculate rank locally based on order
      for (int i = 0; i < list.length; i++) {
        list[i]['rank'] = i + 1;
      }
      return list;
    });
  }

  Future<void> updateTeamMMR(String docId, int mmrChange, bool isWin) async {
    final docRef = _db.collection('rankings').doc(docId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final currentMmr = snapshot.data()?['mmr'] as int? ?? 1000;
      final currentWins = snapshot.data()?['wins'] as int? ?? 0;
      final currentLosses = snapshot.data()?['losses'] as int? ?? 0;
      
      int newMmr = currentMmr + mmrChange;
      if (newMmr < 0) newMmr = 0; // Don't go below 0
      
      transaction.update(docRef, {
        'mmr': newMmr,
        'wins': isWin ? currentWins + 1 : currentWins,
        'losses': !isWin ? currentLosses + 1 : currentLosses,
      });
    });
  }

  Future<Map<String, dynamic>?> getGameStats(String game) async {
    try {
      final doc = await _db.collection('game_stats').doc(game.toLowerCase().replaceAll(' ', '_')).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // =========================================================================
  // 5. Live Match & Chat (البث الحي والمحادثة الفورية)
  // =========================================================================

  Future<void> createMatch(Map<String, dynamic> matchData) async {
    await _db.collection('matches').add(matchData);
  }

  Future<void> updateMatchScore(String matchId, int scoreA, int scoreB, String timeText) async {
    await _db.collection('matches').doc(matchId).update({
      'scoreA': scoreA,
      'scoreB': scoreB,
      'time': timeText,
    });
  }

  Future<void> updateMatchStreamUrl(String matchId, String youtubeVideoId) async {
    await _db.collection('matches').doc(matchId).update({
      'youtubeVideoId': youtubeVideoId,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getLiveMatchStream(String matchId) {
    return _db.collection('matches').doc(matchId).snapshots();
  }

  Stream<List<Map<String, dynamic>>> getAllMatchesStream() {
    return _db.collection('matches').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> getMatchChatStream(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendChatMessage({
    required String matchId,
    required String senderId,
    required String senderName,
    required String message,
    bool isModerator = false,
  }) async {
    await _db.collection('matches').doc(matchId).collection('chat_messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isModerator': isModerator,
    });
  }

  // =========================================================================
  // 6. Wallet & Deposits (المحفظة والتحويلات)
  // =========================================================================
  Future<void> submitDepositRequest({
    required String userId,
    required double amount,
    required String bankAccountName,
    required String receiptImageUrl,
    required String transactionRef,
  }) async {
    await _db.collection('transactions').add({
      'userId': userId,
      'amount': amount,
      'type': 'deposit',
      'bankAccountName': bankAccountName,
      'receiptImageUrl': receiptImageUrl,
      'transactionRef': transactionRef,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  // =========================================================================
  // 7. Data Seeding / تهيئة الجداول والبيانات الأولية والصلاحيات
  // =========================================================================
  Future<void> seedInitialData() async {
    final batch = _db.batch();

    // 1. حسابات الأدمن الأولية (Admin Roles)
    final admins = [
      {
        'uid': 'admin_super_01',
        'displayName': 'مدير النظام العام',
        'email': 'superadmin@esportsudan.sd',
        'phone': '+249912345678',
        'role': 'super_admin',
      },
      {
        'uid': 'admin_tourney_01',
        'displayName': 'منظم بطولات السودان',
        'email': 'tournament@esportsudan.sd',
        'phone': '+249911122233',
        'role': 'tournament_admin',
      },
      {
        'uid': 'admin_referee_01',
        'displayName': 'حكم المباريات الرسمي',
        'email': 'referee@esportsudan.sd',
        'phone': '+249999888777',
        'role': 'referee',
      },
      {
        'uid': 'admin_finance_01',
        'displayName': 'المسؤول المالي (بنكك/فوري)',
        'email': 'finance@esportsudan.sd',
        'phone': '+249123456789',
        'role': 'finance_admin',
      },
    ];

    for (var admin in admins) {
      final ref = _db.collection('users').doc(admin['uid'] as String);
      batch.set(ref, admin, SetOptions(merge: true));
    }

    // 2. إحصائيات الألعاب (Game Stats)
    final pubgStatsRef = _db.collection('game_stats').doc('pubg_mobile');
    batch.set(pubgStatsRef, {
      'game': 'PUBG Mobile',
      'total_matches': '1,240',
      'total_players': '8,500',
      'top_weapon': 'M416',
      'highest_kills': 'Falcon (22 Kills)',
    });

    final eafcStatsRef = _db.collection('game_stats').doc('ea_fc_25');
    batch.set(eafcStatsRef, {
      'game': 'EA FC 25',
      'total_matches': '3,100',
      'total_players': '12,000',
      'top_weapon': 'N/A (Football)',
      'highest_kills': 'Mo_SD (8 Goals)',
    });

    // 3. تصنيفات الفرق واللاعبين (Rankings)
    final rankings = [
      {'game': 'PUBG Mobile', 'season': 'Season 1', 'type': 'teams', 'name': 'صقور النيل', 'city': 'الخرطوم', 'mmr': 2100, 'wins': 28, 'losses': 5},
      {'game': 'PUBG Mobile', 'season': 'Season 1', 'type': 'teams', 'name': 'فرسان المقرن', 'city': 'بحري', 'mmr': 1850, 'wins': 25, 'losses': 10},
      {'game': 'PUBG Mobile', 'season': 'Season 1', 'type': 'teams', 'name': 'أسود توتي', 'city': 'أم درمان', 'mmr': 1150, 'wins': 22, 'losses': 18},
      {'game': 'PUBG Mobile', 'season': 'Season 1', 'type': 'teams', 'name': 'الجزيرة روكتس', 'city': 'ود مدني', 'mmr': 950, 'wins': 10, 'losses': 22},
      {'game': 'EA FC 25', 'season': 'Season 1', 'type': 'teams', 'name': 'أبطال مدني', 'city': 'الجزيرة', 'mmr': 2400, 'wins': 40, 'losses': 2},
      {'game': 'EA FC 25', 'season': 'Season 1', 'type': 'teams', 'name': 'ذئاب بورتسودان', 'city': 'البحر الأحمر', 'mmr': 1950, 'wins': 35, 'losses': 8},
      {'game': 'EA FC 25', 'season': 'Season 1', 'type': 'teams', 'name': 'شباب كوستي', 'city': 'النيل الأبيض', 'mmr': 1400, 'wins': 20, 'losses': 15},
    ];

    for (var r in rankings) {
      final ref = _db.collection('rankings').doc();
      batch.set(ref, r);
    }

    // 4. بطولات تجريبية (Sample Tournaments)
    final tourneyRef = _db.collection('tournaments').doc('pubg_championship_2025');
    batch.set(tourneyRef, {
      'title': 'بطولة درع السودان الكبرى - PUBG Mobile',
      'game': 'PUBG Mobile',
      'prizePool': '500,000 SDG',
      'entryFee': 10000,
      'status': 'upcoming',
      'maxTeams': 32,
      'registeredTeamsCount': 18,
      'startDate': '2025-10-01',
    });

    // 5. مباراة تجريبية للبث المباشر (Sample Match)
    final matchRef = _db.collection('matches').doc('sample_live_match');
    batch.set(matchRef, {
      'title': 'صقور النيل vs فرسان المقرن',
      'teamA': 'صقور النيل',
      'teamB': 'فرسان المقرن',
      'scoreA': 2,
      'scoreB': 1,
      'time': "78' مباشر",
      'status': 'live',
      'youtubeVideoId': 'jfKfPfyJRdk',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
