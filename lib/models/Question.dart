enum QuestionType { multiple, single, open, reorder, trueFalse}

class QuestionModel {
  String id;
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
}