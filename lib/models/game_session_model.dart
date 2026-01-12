import 'package:kvizz/models/question_model.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class QuizData {
  final String id;
  final List<QuestionModel> questions;
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
        ?.map((q) => QuestionModel.fromJson(q))
        .toList() ??
        [],
    title: json['title'],
    description: json['description'],
    creator: QuizCreator.fromJson(json['creator']),
    category: json['category']??'Unknown',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'questions': questions.map((q) => q.toJson()).toList(),
    'title': title,
    'description': description,
    'creator': creator.toJson(),
    'category': category,
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'photo': photo,
    'name': name,
  };
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

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
  };
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

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'answer': answer,
    'isCorrect': isCorrect,
    'timeTaken': timeTaken,
    'points': points,
  };
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

  // In game_session_model.dart - Update Participant.fromJson()
  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['_id'] ?? json['id'] ?? '',
    userId: json['userId']?.toString(),
    username: json['username'] ?? 'Unknown User',
    isGuest: json['isGuest'] ?? true, // Default to guest if not specified
    score: json['score'] ?? 0,
    isActive: json['isActive'] ?? true,
    answers: (json['answers'] as List?)
        ?.map((a) => ParticipantAnswer.fromJson(a))
        .toList() ??
        [],
    joinedAt: json['joinedAt'] != null
        ? DateTime.parse(json['joinedAt'])
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'isGuest': isGuest,
    'score': score,
    'isActive': isActive,
    'answers': answers.map((a) => a.toJson()).toList(),
    'joinedAt': joinedAt.toIso8601String(),
  };
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

  Map<String, dynamic> toJson() => {
    'maxParticipants': maxParticipants,
    'timePerQuestion': timePerQuestion,
    'maxPointsPerQuestion': maxPointsPerQuestion,
    'isPublic': isPublic,
  };
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
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId']?.toString(),
        username: json['username'] ?? 'Unknown User',
        rank: json['rank'] ?? 0,
        score: json['score'] ?? 0,
        correctAnswers: json['correctAnswers'] ?? 0,
        avgResponseTime: (json['avgResponseTime'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'rank': rank,
    'score': score,
    'correctAnswers': correctAnswers,
    'avgResponseTime': avgResponseTime,
  };
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

  Map<String, dynamic> toJson() => {
    'leaderboard': leaderboard.map((l) => l.toJson()).toList(),
  };
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

  // In your GameSessionModel.fromJson method, replace it with this:
  factory GameSessionModel.fromJson(Map<String, dynamic> json) =>
      GameSessionModel(
        id: json['_id'] ?? json['id'] ?? '',
        quizData: json['quizId'] != null && json['quizId'] is Map
            ? QuizData.fromJson(json['quizId'])
            : null,
        hostData: HostData.fromJson(json['hostId']),
        gameCode: json['gameCode'] ?? 0,
        connectionId: json['connectionId'],
        status: json['status'] ?? 'waiting',
        isActive: json['isActive'] ?? true,
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
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'quizId': quizData?.toJson(),
    'hostId': hostData?.toJson(),
    'gameCode': gameCode,
    'connectionId': connectionId,
    'status': status,
    'isActive': isActive,
    'currentQuestion': currentQuestion?.toJson(),
    'participants': participants.map((p) => p.toJson()).toList(),
    'settings': settings?.toJson(),
    'results': results?.toJson(),
    'startedAt': startedAt?.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // Helper methods
  bool get isWaiting => status == 'waiting';
  bool get isStarted => status == 'playing';
  bool get isFinished => status == 'finished';

  int get participantCount => participants.length;

  List<LeaderboardEntry> get leaderboard => results?.leaderboard ?? [];
}
