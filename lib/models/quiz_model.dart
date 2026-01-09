import 'question_model.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final String difficulty;
  final String creator;
  final String? creatorId;
  final List<String> tags;
  final int? gameCode;
  final String? type; // Optional field for quiz type

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.difficulty,
    required this.creator,
    this.creatorId,
    required this.tags,
    this.gameCode,
    this.type
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
    id: json['_id'] ?? json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    questions: (json['questions'] as List?)
        ?.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList() ?? [],
    difficulty: json['difficulty'] ?? 'medium',
    creator: json['creator']['name']?.toString() ?? '',
    creatorId: json['creator']['_id']?.toString(),
    tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    type: json['type']?.toString() ?? 'manual',
  );

  Map<String, dynamic> toJson({bool forApi = false}) {
    final json = <String, dynamic>{
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson(forApi: forApi)).toList(),
      'difficulty': difficulty,
      'creator': creator,
      'tags': tags,
    };

    // Only include _id if it's not empty and not for API creation
    if (!forApi && id.isNotEmpty) {
      json['_id'] = id;
    }

    return json;
  }

  // Helper method to create a copy with updated fields
  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    List<QuestionModel>? questions,
    String? difficulty,
    String? creator,
    String? category,
    List<String>? tags,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      difficulty: difficulty ?? this.difficulty,
      creator: creator ?? this.creator,
      tags: tags ?? this.tags,
    );
  }
}
