import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';

class OpenEndedQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const OpenEndedQuestionWidget({
    super.key,
    required this.question,
    required this.onDelete,
  });

  @override
  State<OpenEndedQuestionWidget> createState() =>
      _OpenEndedQuestionWidgetState();
}

class _OpenEndedQuestionWidgetState
    extends State<OpenEndedQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
