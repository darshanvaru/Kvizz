// game_session_model.dart
class CurrentQuestion {
  final String questionId;
  final DateTime startTime;
  final DateTime endTime;
  CurrentQuestion({
    required this.questionId,
    required this.startTime,
    required this.endTime,
  });
  factory CurrentQuestion.fromJson(Map<String, dynamic> json) =>
    CurrentQuestion(
      questionId: json['questionId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
}

class ParticipantAnswer {
  final String questionId;
  final String answer;
  final bool isCorrect;
  final int timeTaken;
  final int points;
  ParticipantAnswer({
    required this.questionId,
    required this.answer,
    required this.isCorrect,
    required this.timeTaken,
    required this.points,
  });
  factory ParticipantAnswer.fromJson(Map<String, dynamic> json) =>
    ParticipantAnswer(
      questionId: json['questionId'],
      answer: json['answer'],
      isCorrect: json['isCorrect'],
      timeTaken: json['timeTaken'],
      points: json['points'],
    );
}

class Participant {
  final String? userId;
  final String username;
  final bool isGuest;
  final int score;
  final List<ParticipantAnswer> answers;
  Participant({
    this.userId,
    required this.username,
    required this.isGuest,
    required this.score,
    required this.answers,
  });
  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    userId: json['userId']?.toString(),
    username: json['username'],
    isGuest: json['isGuest'] ?? false,
    score: json['score'] ?? 0,
    answers: (json['answers'] as List<dynamic>?)
      ?.map((a) => ParticipantAnswer.fromJson(a))
      .toList() ?? [],
  );
}

class GameSettings {
  final int maxParticipants;
  final int timePerQuestion;
  final int maxPointsPerQuestion;
  final bool isPublic;
  GameSettings({
    required this.maxParticipants,
    required this.timePerQuestion,
    required this.maxPointsPerQuestion,
    required this.isPublic,
  });
  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    maxParticipants: json['maxParticipants'] ?? 50,
    timePerQuestion: json['timePerQuestion'] ?? 30,
    maxPointsPerQuestion: json['maxPointsPerQuestion'] ?? 100,
    isPublic: json['isPublic'] ?? true,
  );
}

class LeaderboardEntry {
  final String? userId;
  final String username;
  final int rank;
  final int score;
  final int correctAnswers;
  final double avgResponseTime;
  LeaderboardEntry({
    this.userId,
    required this.username,
    required this.rank,
    required this.score,
    required this.correctAnswers,
    required this.avgResponseTime,
  });
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      userId: json['userId']?.toString(),
      username: json['username'],
      rank: json['rank'],
      score: json['score'],
      correctAnswers: json['correctAnswers'],
      avgResponseTime: (json['avgResponseTime'] as num).toDouble(),
    );
}

class GameSessionModel {
  final String id;
  final String quizId;
  final String hostId;
  final int gameCode;
  final String? connectionId;
  final String status;
  final bool isActive;
  final CurrentQuestion? currentQuestion;
  final List<Participant>? participants;
  final GameSettings? settings;
  final List<LeaderboardEntry>? leaderboard;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  GameSessionModel({
    required this.id,
    required this.quizId,
    required this.hostId,
    required this.gameCode,
    this.connectionId,
    required this.status,
    required this.isActive,
    this.currentQuestion,
    this.participants,
    this.settings,
    this.leaderboard,
    this.startedAt,
    this.finishedAt,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) => GameSessionModel(
    id: json['_id'],
    quizId: json['quizId'],
    hostId: json['hostId'],
    gameCode: json['gameCode'],
    connectionId: json['connectionId'],
    status: json['status'],
    isActive: json['isActive'],
    currentQuestion: json['currentQuestion'] != null
      ? CurrentQuestion.fromJson(json['currentQuestion'])
      : null,
    participants: (json['participants'] as List<dynamic>?)
      ?.map((p) => Participant.fromJson(p))
      .toList(),
    settings: json['settings'] != null
      ? GameSettings.fromJson(json['settings'])
      : null,
    leaderboard: (json['results']?['leaderboard'] as List<dynamic>?)
      ?.map((l) => LeaderboardEntry.fromJson(l))
      .toList(),
    startedAt: json['startedAt'] != null
      ? DateTime.parse(json['startedAt'])
      : null,
    finishedAt: json['finishedAt'] != null
      ? DateTime.parse(json['finishedAt'])
      : null,
  );
}