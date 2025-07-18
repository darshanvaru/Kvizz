import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';

class ReorderableQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const ReorderableQuestionWidget({
    super.key,
    required this.question,
    required this.onDelete,
  });

  @override
  State<ReorderableQuestionWidget> createState() =>
      _ReorderableQuestionWidgetState();
}

class _ReorderableQuestionWidgetState
    extends State<ReorderableQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
