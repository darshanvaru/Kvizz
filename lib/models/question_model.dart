import '../enums/enums.dart';

class QuestionModel {
  final String id;
  final QuestionType type;
  String question;
  List<String> options;
  List<String> correctAnswer;
  final String? funFact;
  final String? media;
  final MediaType? mediaType;
  final DateTime? createdAt;

  QuestionModel({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.funFact,
    this.media,
    this.mediaType,
    this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
    id: json['_id'] ?? json['id'] ?? '',
    type: _typeFromString(json['type']),
    question: json['question'] ?? '',
    options: (json['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    correctAnswer: (json['correctAnswer'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    funFact: json['funFact'],
    media: json['media'],
    mediaType: _mediaTypeFromString(json['mediaType']),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
  );

  Map<String, dynamic> toJson({bool forApi = false}) {
    final json = <String, dynamic>{
      'type': type.name,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'funFact': funFact,
      'media': media,
      'mediaType': mediaType?.name,
    };

    // Only include _id if it's not empty and not for API creation
    if (!forApi && id.isNotEmpty) {
      json['_id'] = id;
    }

    // Only include createdAt if it's not null and not for API creation
    if (!forApi && createdAt != null) {
      json['createdAt'] = createdAt!.toIso8601String();
    }

    return json;
  }


  QuestionModel copyWith({
    String? id,
    QuestionType? type,
    String? question,
    List<String>? options,
    List<String>? correctAnswer,
    String? funFact,
    String? media,
    MediaType? mediaType,
    DateTime? createdAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      funFact: funFact ?? this.funFact,
      media: media ?? this.media,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods for safe enum parsing
  static QuestionType _typeFromString(String? raw) {
    return QuestionType.values.firstWhere(
          (e) => e.name == raw,
      orElse: () => QuestionType.multiple,
    );
  }

  static MediaType? _mediaTypeFromString(String? raw) {
    if (raw == null) return null;
    return MediaType.values.firstWhere(
          (e) => e.name == raw,
      orElse: () => MediaType.image,
    );
  }
}
