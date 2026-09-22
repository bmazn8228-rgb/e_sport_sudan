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
}

class UserSettings {
  final bool isDarkMode;
  final bool dataSaver;
  final bool tournamentNotifs;
  final bool matchReminders;
  final bool teamInvites;
  final String language;

  UserSettings({
    this.isDarkMode = true,
    this.dataSaver = true,
    this.tournamentNotifs = true,
    this.matchReminders = true,
    this.teamInvites = true,
    this.language = 'العربية',
  });

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'dataSaver': dataSaver,
      'tournamentNotifs': tournamentNotifs,
      'matchReminders': matchReminders,
      'teamInvites': teamInvites,
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
  final UserRole role;
  final String? teamId;
  final UserSettings settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.ign,
    required this.phone,
    this.photoUrl,
    this.gameId,
    this.role = UserRole.player,
    this.teamId,
    UserSettings? settings,
  }) : settings = settings ?? UserSettings();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'ign': ign,
      'phone': phone,
      'photoUrl': photoUrl,
      'gameId': gameId,
      'role': role.toValue(),
      'teamId': teamId,
      'settings': settings.toMap(),
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
      role: UserRole.fromValue(map['role']),
      teamId: map['teamId'],
      settings: UserSettings.fromMap(map['settings'] as Map<String, dynamic>?),
    );
  }
}
