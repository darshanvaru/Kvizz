class GameSessionModel {
  final String id;
  final String quizId;
  final String hostId;
  final int gameCode;
  final String? connectionId;
  final String status; // waiting, playing, finished
  final bool isActive;
  final CurrentQuestion? currentQuestion;

  GameSessionModel({
    required this.id,
    required this.quizId,
    required this.hostId,
    required this.gameCode,
    this.connectionId,
    required this.status,
    required this.isActive,
    this.currentQuestion,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
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
    );
  }
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

  factory CurrentQuestion.fromJson(Map<String, dynamic> json) {
    return CurrentQuestion(
      questionId: json['questionId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}
