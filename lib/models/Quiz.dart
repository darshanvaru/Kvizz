import 'package:kvizz/models/Question.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
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

  QuizModel({
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

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList(),
      type: json['type'],
      timePerQuestion: json['timePerQuestion'],
      questionOrder: json['questionOrder'],
      pointsPerQuestion: json['pointsPerQuestion'],
      timesPlayed: json['stats']?['timesPlayed'] ?? 0,
      averageScore: json['stats']?['averageScore'] ?? 0,
      totalUserPlayed: json['stats']?['totalUserPlayed'] ?? 0,
      participantLimit: json['participantLimit'] ?? 10,
      difficulty: json['difficulty'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
