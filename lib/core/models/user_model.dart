import 'stats_models.dart';

enum UserRole {
  superAdmin,
  tournamentAdmin,
  referee,
  financeAdmin,
  player;

  String toValue() {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.tournamentAdmin:
        return 'tournament_admin';
      case UserRole.referee:
        return 'referee';
      case UserRole.financeAdmin:
        return 'finance_admin';
      case UserRole.player:
        return 'player';
    }
  }

  static UserRole fromValue(String? value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'tournament_admin':
        return UserRole.tournamentAdmin;
      case 'referee':
        return UserRole.referee;
      case 'finance_admin':
        return UserRole.financeAdmin;
      default:
        return UserRole.player;
    }
  }

  int get rank {
    switch (this) {
      case UserRole.superAdmin:
        return 100;
      case UserRole.tournamentAdmin:
        return 80;
      case UserRole.financeAdmin:
        return 60;
      case UserRole.referee:
        return 40;
      case UserRole.player:
        return 10;
    }
  }

  String get displayNameArabic {
    switch (this) {
      case UserRole.superAdmin:
        return 'مدير النظام العام 👑';
      case UserRole.tournamentAdmin:
        return 'منظم بطولات 🏆';
      case UserRole.referee:
        return 'حكم مباريات ⚖️';
      case UserRole.financeAdmin:
        return 'مسؤول مالي 💳';
      case UserRole.player:
        return 'لاعب / قائد فريق 🎮';
    }
  }

  String get roleTitleArabic {
    switch (this) {
      case UserRole.superAdmin:
        return 'مدير نظام أعلى (Super Admin)';
      case UserRole.tournamentAdmin:
        return 'منظم بطولات (Tournament Admin)';
      case UserRole.financeAdmin:
        return 'مسؤول مالي (Finance Admin)';
      case UserRole.referee:
        return 'حكم معتمد (Referee)';
      case UserRole.player:
        return 'لاعب عادي (Player)';
    }
  }

  /// Whether this role has higher rank than [targetUserRole]
  /// Strict rule: Only the Super Admin can promote or modify roles.
  bool canPromoteUser(UserRole targetUserRole) {
    return this == UserRole.superAdmin;
  }

  /// Whether this role is authorized to assign [candidateRole]
  /// Strict rule: Only the Super Admin can assign roles.
  bool canAssignRole(UserRole candidateRole) {
    return this == UserRole.superAdmin;
  }

  /// Returns the list of roles that this admin is authorized to assign
  List<UserRole> get availableRolesToAssign {
    return UserRole.values.where((r) => canAssignRole(r)).toList();
  }
}

class UserSettings {
  final bool isDarkMode;
  final bool dataSaver;
  final bool tournamentNotifs;
  final bool matchReminders;
  final bool teamInvites;
  final bool hideStatistics;
  final String language;

  UserSettings({
    this.isDarkMode = true,
    this.dataSaver = true,
    this.tournamentNotifs = true,
    this.matchReminders = true,
    this.teamInvites = true,
    this.hideStatistics = false,
    this.language = 'العربية',
  });

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'dataSaver': dataSaver,
      'tournamentNotifs': tournamentNotifs,
      'matchReminders': matchReminders,
      'teamInvites': teamInvites,
      'hideStatistics': hideStatistics,
      'language': language,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserSettings();
    return UserSettings(
      isDarkMode: map['isDarkMode'] ?? true,
      dataSaver: map['dataSaver'] ?? true,
      tournamentNotifs: map['tournamentNotifs'] ?? true,
      matchReminders: map['matchReminders'] ?? true,
      teamInvites: map['teamInvites'] ?? true,
      hideStatistics: map['hideStatistics'] ?? false,
      language: map['language'] ?? 'العربية',
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? ign;
  final String phone;
  final String? photoUrl;
  final String? gameId;
  final String? playerId; // Short numeric ID
  final UserRole role;
  final String? teamId;
  final UserSettings settings;
  final PlayerStats stats;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.ign,
    this.phone = '',
    this.photoUrl,
    this.gameId,
    this.playerId,
    this.role = UserRole.player,
    this.teamId,
    UserSettings? settings,
    PlayerStats? stats,
  }) : settings = settings ?? UserSettings(),
       stats = stats ?? PlayerStats();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'ign': ign,
      'phone': phone,
      'photoUrl': photoUrl,
      'gameId': gameId,
      'playerId': playerId,
      'role': role.toValue(),
      'teamId': teamId,
      'settings': settings.toMap(),
      'stats': stats.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      ign: map['ign'],
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      gameId: map['gameId'],
      playerId: map['playerId'],
      role: UserRole.fromValue(map['role']),
      teamId: map['teamId'],
      settings: UserSettings.fromMap(map['settings'] as Map<String, dynamic>?),
      stats: PlayerStats.fromMap(map['stats'] as Map<String, dynamic>?),
    );
  }
}
