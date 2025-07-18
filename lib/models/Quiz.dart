import 'package:kvizz/models/Question.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  List<QuestionModel> questions;
  final String type;
  final int timePerQuestion;
  final String questionOrder;
  final int pointsPerQuestion;
  final int timesPlayed;
  final int averageScore;
  final int totalUserPlayed;
  final int participantLimit;
  final String difficulty;
  final bool isActive;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.type,
    required this.timePerQuestion,
    required this.questionOrder,
    required this.pointsPerQuestion,
    required this.timesPlayed,
    required this.averageScore,
    required this.totalUserPlayed,
    required this.participantLimit,
    required this.difficulty,
    required this.isActive,
    required this.createdAt,
  });
}