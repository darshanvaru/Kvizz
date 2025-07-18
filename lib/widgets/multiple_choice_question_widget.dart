import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';

class MultipleChoiceQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.question,
    required this.onDelete,
  });

  @override
  State<MultipleChoiceQuestionWidget> createState() =>
      _MultipleChoiceQuestionWidgetState();
}

class _MultipleChoiceQuestionWidgetState
    extends State<MultipleChoiceQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
