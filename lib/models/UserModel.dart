// user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? mobile;
  final String? username;
  final String? photo;
  final DateTime createdAt;
  final DateTime? passwordChangedAt;
  final bool? active;
  final DateTime? deletedAt;
  final UserStats? stats;
  final List<String>? ownedQuizzes;
  final List<String>? playedQuiz;
  final UserSettings? settings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    this.username,
    this.photo,
    required this.createdAt,
    this.passwordChangedAt,
    this.active,
    this.deletedAt,
    this.stats,
    this.ownedQuizzes,
    this.playedQuiz,
    this.settings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? json['id'],
    name: json['name'],
    email: json['email'],
    mobile: json['mobile']?.toString(),
    username: json['username'],
    photo: json['photo'],
    createdAt: DateTime.parse(json['createdAt']),
    passwordChangedAt: json['passwordChangedAt'] != null
        ? DateTime.parse(json['passwordChangedAt'])
        : null,
    active: json['active'],
    deletedAt: json['deletedAt'] != null
        ? DateTime.parse(json['deletedAt'])
        : null,
    stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
    ownedQuizzes: (json['ownedQuizzes'] as List<dynamic>?)
        ?.map((e) => e.toString()).toList(),
    playedQuiz: (json['playedQuiz'] as List<dynamic>?)
        ?.map((e) => e.toString()).toList(),
    settings: json['settings'] != null
        ? UserSettings.fromJson(json['settings'])
        : null,
  );
}

class UserStats {
  final int totalScore;
  final double averageScore;
  final int gamesPlayed;
  UserStats({
    required this.totalScore,
    required this.averageScore,
    required this.gamesPlayed,
  });
  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalScore: json['totalScore'] ?? 0,
    averageScore: (json['averageScore'] ?? 0).toDouble(),
    gamesPlayed: json['gamesPlayed'] ?? 0,
  );
}

class UserSettings {
  final bool darkMode;
  UserSettings({required this.darkMode});
  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      UserSettings(darkMode: json['darkMode'] ?? false);
}