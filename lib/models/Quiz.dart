import 'package:kvizz/models/Question.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final String creator;
  final String type;
  final String difficulty;
  final bool isActive;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.creator,
    required this.type,
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
      creator: json['creator'],
      type: json['type'],
      difficulty: json['difficulty'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
