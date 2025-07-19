enum QuestionType { single, multiple, open, reorder, trueFalse }

class QuestionModel {
  final String id;
  QuestionType type;
  String question;
  List<String> options;
  List<String> correctAnswer;

  QuestionModel({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['_id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: List<String>.from(json['correctAnswer']),
      type: QuestionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => QuestionType.single,
      ),
    );
  }
}
