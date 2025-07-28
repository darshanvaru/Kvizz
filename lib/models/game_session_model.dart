// game_session_model.dart

class QuizCreator {
  final String id;
  final String name;

  QuizCreator({
    required this.id,
    required this.name,
  });

  factory QuizCreator.fromJson(Map<String, dynamic> json) => QuizCreator(
    id: json['_id'] ?? json['id'],
    name: json['name'],
  );
}

class QuizQuestion {
  final String id;
  final List<String> options;
  final List<String> correctAnswer;
  final String type;
  final String question;

  QuizQuestion({
    required this.id,
    required this.options,
    required this.correctAnswer,
    required this.type,
    required this.question,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['_id'] ?? json['id'],
    options: List<String>.from(json['options']),
    correctAnswer: List<String>.from(json['correctAnswer']),
    type: json['type'],
    question: json['question'],
  );
}

class QuizData {
  final String id;
  final List<QuizQuestion> questions;
  final String title;
  final String description;
  final QuizCreator creator;
  final String category;

  QuizData({
    required this.id,
    required this.questions,
    required this.title,
    required this.description,
    required this.creator,
    required this.category,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) => QuizData(
    id: json['_id'] ?? json['id'],
    questions: (json['questions'] as List?)
        ?.map((q) => QuizQuestion.fromJson(q))
        .toList() ??
        [],
    title: json['title'],
    description: json['description'],
    creator: QuizCreator.fromJson(json['creator']),
    category: json['category'],
  );
}

class HostData {
  final String id;
  final String photo;
  final String name;

  HostData({
    required this.id,
    required this.photo,
    required this.name,
  });

  factory HostData.fromJson(Map<String, dynamic> json) => HostData(
    id: json['_id'] ?? json['id'],
    photo: json['photo'] ?? '',
    name: json['name'],
  );
}

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
  final String id;
  final String? userId;
  final String username;
  final bool isGuest;
  final int score;
  final bool isActive;
  final List<ParticipantAnswer> answers;
  final DateTime joinedAt;

  Participant({
    required this.id,
    this.userId,
    required this.username,
    required this.isGuest,
    required this.score,
    required this.isActive,
    required this.answers,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['_id'] ?? json['id'],
    userId: json['userId']?.toString(),
    username: json['username'],
    isGuest: json['isGuest'] ?? false,
    score: json['score'] ?? 0,
    isActive: json['isActive'] ?? true,
    answers: (json['answers'] as List?)
        ?.map((a) => ParticipantAnswer.fromJson(a))
        .toList() ??
        [],
    joinedAt: DateTime.parse(json['joinedAt']),
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
  final String id;
  final String? userId;
  final String username;
  final int rank;
  final int score;
  final int correctAnswers;
  final double avgResponseTime;

  LeaderboardEntry({
    required this.id,
    this.userId,
    required this.username,
    required this.rank,
    required this.score,
    required this.correctAnswers,
    required this.avgResponseTime,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        id: json['_id'] ?? json['id'],
        userId: json['userId']?.toString(),
        username: json['username'],
        rank: json['rank'],
        score: json['score'],
        correctAnswers: json['correctAnswers'],
        avgResponseTime: (json['avgResponseTime'] as num).toDouble(),
      );
}

class GameResults {
  final List<LeaderboardEntry> leaderboard;

  GameResults({
    required this.leaderboard,
  });

  factory GameResults.fromJson(Map<String, dynamic> json) => GameResults(
    leaderboard: (json['leaderboard'] as List?)
        ?.map((l) => LeaderboardEntry.fromJson(l))
        .toList() ??
        [],
  );
}

class GameSessionModel {
  final String id;
  final QuizData? quizData;
  final HostData? hostData;
  final int gameCode;
  final String? connectionId;
  final String status;
  final bool isActive;
  final CurrentQuestion? currentQuestion;
  final List<Participant> participants;
  final GameSettings? settings;
  final GameResults? results;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameSessionModel({
    required this.id,
    this.quizData,
    this.hostData,
    required this.gameCode,
    this.connectionId,
    required this.status,
    required this.isActive,
    this.currentQuestion,
    this.participants = const [],
    this.settings,
    this.results,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) =>
      GameSessionModel(
        id: json['_id'] ?? json['id'],
        quizData: json['quizId'] != null && json['quizId'] is Map
            ? QuizData.fromJson(json['quizId'])
            : null,
        hostData: json['hostId'] != null && json['hostId'] is Map
            ? HostData.fromJson(json['hostId'])
            : null,
        gameCode: json['gameCode'],
        connectionId: json['connectionId'],
        status: json['status'],
        isActive: json['isActive'],
        currentQuestion: json['currentQuestion'] != null
            ? CurrentQuestion.fromJson(json['currentQuestion'])
            : null,
        participants: (json['participants'] as List?)
            ?.map((p) => Participant.fromJson(p))
            .toList() ??
            [],
        settings: json['settings'] != null
            ? GameSettings.fromJson(json['settings'])
            : null,
        results: json['results'] != null
            ? GameResults.fromJson(json['results'])
            : null,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'])
            : null,
        finishedAt: json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  // Helper methods
  bool get isWaiting => status == 'waiting';
  bool get isStarted => status == 'started' || status == 'in-progress';
  bool get isFinished => status == 'finished' || status == 'completed';

  int get participantCount => participants.length;

  List<LeaderboardEntry> get leaderboard => results?.leaderboard ?? [];

  Participant? getParticipantById(String participantId) {
    try {
      return participants.firstWhere((p) => p.id == participantId);
    } catch (e) {
      return null;
    }
  }

  Participant? getParticipantByUserId(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }
}
