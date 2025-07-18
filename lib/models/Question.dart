enum QuestionType { multiple, single, open, reorder, trueFalse}

class QuestionModel {
  String id;
  QuestionType type;
  String question;
  List<String> options;
  dynamic correctAnswer;
  /*
    Empty for open ended,
    single item for single and vica versa for multiple,
    correct order list for reorder,
    2 for true anf false
  */

  QuestionModel({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}