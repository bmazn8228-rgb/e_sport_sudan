class PlayerStats {
  final int elo;
  final String tier; // Bronze, Silver, Gold, Diamond, Challenger
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int kills;
  final int mvpCount;
  final int tournamentsWon;

  PlayerStats({
    this.elo = 1000,
    this.tier = 'Bronze',
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.kills = 0,
    this.mvpCount = 0,
    this.tournamentsWon = 0,
  });

  double get winRate => matchesPlayed > 0 ? (wins / matchesPlayed) * 100 : 0.0;
  double get killsPerMatch => matchesPlayed > 0 ? (kills / matchesPlayed) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'elo': elo,
      'tier': tier,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'kills': kills,
      'mvpCount': mvpCount,
      'tournamentsWon': tournamentsWon,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PlayerStats();
    return PlayerStats(
      elo: map['elo'] ?? 1000,
      tier: map['tier'] ?? 'Bronze',
      matchesPlayed: map['matchesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      kills: map['kills'] ?? 0,
      mvpCount: map['mvpCount'] ?? 0,
      tournamentsWon: map['tournamentsWon'] ?? 0,
    );
  }
}

class TeamStats {
  final int elo;
  final String tier;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int totalPoints;
  final int tournamentsWon;
  final int totalKills;

  TeamStats({
    this.elo = 1000,
    this.tier = 'Bronze',
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalPoints = 0,
    this.tournamentsWon = 0,
    this.totalKills = 0,
  });

  double get winRate => matchesPlayed > 0 ? (wins / matchesPlayed) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'elo': elo,
      'tier': tier,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'totalPoints': totalPoints,
      'tournamentsWon': tournamentsWon,
      'totalKills': totalKills,
    };
  }

  factory TeamStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return TeamStats();
    return TeamStats(
      elo: map['elo'] ?? 1000,
      tier: map['tier'] ?? 'Bronze',
      matchesPlayed: map['matchesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      tournamentsWon: map['tournamentsWon'] ?? 0,
      totalKills: map['totalKills'] ?? 0,
    );
  }
}

// Function to calculate tier from Elo
String calculateTier(int elo) {
  if (elo < 1000) return 'Bronze';
  if (elo < 1500) return 'Silver';
  if (elo < 2000) return 'Gold';
  if (elo < 2500) return 'Diamond';
  return 'Challenger';
}
