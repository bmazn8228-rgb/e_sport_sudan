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

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      final usersCount = await _db.collection('users').count().get();
      final teamsCount = await _db.collection('teams').count().get();
      final tournamentsCount = await _db.collection('tournaments').count().get();
      
      // For sum, if `aggregate` is not natively supported by the older SDK version, 
      // we can do a client-side sum for this specific query, or maintain a running total in a metadata doc.
      // Since this is just an admin dashboard, a client-side sum over deposits is acceptable for now.
      final txSnapshot = await _db.collection('transactions')
          .where('type', isEqualTo: 'deposit')
          .where('status', isEqualTo: 'approved')
          .get();
          
      double totalFees = 0;
      for (var doc in txSnapshot.docs) {
        totalFees += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'usersCount': usersCount.count ?? 0,
        'teamsCount': teamsCount.count ?? 0,
        'tournamentsCount': tournamentsCount.count ?? 0,
        'totalFees': totalFees,
      };
    } catch (e) {
      return {
        'usersCount': 0,
        'teamsCount': 0,
        'tournamentsCount': 0,
        'totalFees': 0.0,
      };
    }
  }

  Stream<List<Map<String, dynamic>>> getUsersByRoleStream(String role) {
    return _db.collection('users').where('role', isEqualTo: role).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
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

  Future<void> deleteTournament(String tournamentId) async {
    await _db.collection('tournaments').doc(tournamentId).delete();
  }


  // =========================================================================
  // 5. Wallet & Transactions
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getPendingDepositRequestsStream() {
    return _db.collection('transactions')
        .where('type', isEqualTo: 'deposit')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<void> updateDepositRequestStatus(String docId, String status, double amount, String userId) async {
    await _db.runTransaction((transaction) async {
      final docRef = _db.collection('transactions').doc(docId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      if (snapshot.data()?['status'] != 'pending') return; // Already processed

      transaction.update(docRef, {'status': status});
      
      if (status == 'approved') {
        final userRef = _db.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);
        if (userSnapshot.exists) {
          final currentBalance = (userSnapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
          transaction.update(userRef, {'walletBalance': currentBalance + amount});
        }
      }
    });
  }

  // =========================================================================
  // 6. Leaderboards (التصنيفات)
  // =========================================================================
  Future<String> createTeam(Map<String, dynamic> teamData, String creatorUid) async {
    final docRef = await _db.collection('teams').add(teamData);
    await _db.collection('users').doc(creatorUid).update({'teamId': docRef.id});
    return docRef.id;
  }

  Future<void> joinTeam(String teamId, String uid, Map<String, dynamic> playerRosterData) async {
    // Add user to team roster array
    await _db.collection('teams').doc(teamId).update({
      'roster': FieldValue.arrayUnion([playerRosterData])
    });
    // Update user doc
    await _db.collection('users').doc(uid).update({'teamId': teamId});
  }

  Future<void> leaveTeam(String teamId, String uid, Map<String, dynamic> playerRosterData) async {
    // Remove user from team roster array
    await _db.collection('teams').doc(teamId).update({
      'roster': FieldValue.arrayRemove([playerRosterData])
    });
    // Update user doc
    await _db.collection('users').doc(uid).update({'teamId': FieldValue.delete()});
  }

  Future<void> registerTeam(Map<String, dynamic> teamData) async {
    await _db.collection('teams').add(teamData);
  }

  Future<Map<String, dynamic>?> getTeam(String teamId) async {
    final doc = await _db.collection('teams').doc(teamId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    data?['id'] = doc.id;
    return data;
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

  Stream<List<Map<String, dynamic>>> getAllTeamsStream() {
    return _db.collection('teams').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  Future<void> deleteTeam(String teamId) async {
    await _db.collection('teams').doc(teamId).delete();
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

  Future<void> updateLiveStream({
    required String youtubeVideoId,
    required String title,
    required bool isLive,
  }) async {
    final data = {
      'id': 'sample_live_match',
      'youtubeVideoId': youtubeVideoId,
      'title': title,
      'isLive': isLive,
      'status': isLive ? 'live' : 'offline',
      'teamA': 'بث مباشر',
      'teamB': 'E-Sport Sudan',
      'scoreA': 0,
      'scoreB': 0,
      'time': isLive ? 'مباشر الآن' : 'متوقف',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('matches').doc('sample_live_match').set(data, SetOptions(merge: true));
    await _db.collection('settings').doc('live_stream').set(data, SetOptions(merge: true));
  }

  Future<void> stopLiveStream() async {
    await _db.collection('matches').doc('sample_live_match').set({
      'isLive': false,
      'status': 'offline',
      'youtubeVideoId': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _db.collection('settings').doc('live_stream').set({
      'isLive': false,
      'youtubeVideoId': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getGlobalLiveStream() {
    return _db.collection('matches').doc('sample_live_match').snapshots();
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

  Stream<List<Map<String, dynamic>>> getTournamentMatchesStream(String tournamentId) {
    return _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
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

  Stream<List<Map<String, dynamic>>> getTeamMatchesStream(String teamId) {
    // Note: Since Firestore doesn't support logical OR in simple where clauses natively across fields without composite indexes,
    // we fetch matches where the team is either teamAId or teamBId on the client for this demo, or we can just fetch all matches and filter,
    // or use a more robust backend logic. Here we just fetch all and filter for simplicity since it's a small dataset.
    return _db
        .collection('matches')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).where((m) => m['teamAId'] == teamId || m['teamBId'] == teamId || m['teamA'] == teamId || m['teamB'] == teamId).toList());
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

  Stream<List<Map<String, dynamic>>> getTransactionsStream(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
  // =========================================================================
  // 7. Data Seeding / تهيئة الجداول والبيانات الأولية والصلاحيات
  // =========================================================================
  Future<void> seedInitialData() async {
    // Initial data seeding logic removed to avoid dummy data.
  }

  // =========================================================================
  // 8. Complaints (الشكاوى والاعتراضات)
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getComplaintsStream() {
    return _db.collection('complaints').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    await _db.collection('complaints').doc(complaintId).update({'status': newStatus});
  }

  Future<void> addComplaint(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('complaints').add(data);
  }

  Future<void> deleteComplaint(String complaintId) async {
    await _db.collection('complaints').doc(complaintId).delete();
  }

  // =========================================================================
  // 9. Wallet Balance Stream
  // =========================================================================
  Stream<double> getUserWalletStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      return (doc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
    });
  }

  // =========================================================================
  // 10. Referee — Match Management
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getMatchesForRefereeStream(String refereeUid) {
    return _db.collection('matches')
        .where('refereeId', isEqualTo: refereeUid)
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> submitMatchResult({
    required String matchId,
    required int scoreA,
    required int scoreB,
    required String screenshotUrl,
    required String refereeId,
  }) async {
    await _db.collection('matches').doc(matchId).update({
      'scoreA': scoreA,
      'scoreB': scoreB,
      'screenshotUrl': screenshotUrl,
      'status': 'completed',
      'refereeId': refereeId,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================================
  // 11. Tournament Registrations
  // =========================================================================
  Stream<List<Map<String, dynamic>>> getTournamentRegistrationsStream(String tournamentId) {
    return _db.collection('tournaments').doc(tournamentId)
        .collection('registrations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // =========================================================================
  // 12. Players Search
  // =========================================================================
  Stream<List<Map<String, dynamic>>> searchPlayersStream(String query) {
    if (query.isEmpty) return const Stream.empty();
    return _db.collection('users')
        .where('role', isEqualTo: 'player')
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> searchAllUsersStream(String query) {
    if (query.isEmpty) return const Stream.empty();
    return _db.collection('users')
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateUserRole(String userId, String roleValue) async {
    await _db.collection('users').doc(userId).update({'role': roleValue});
  }
}

