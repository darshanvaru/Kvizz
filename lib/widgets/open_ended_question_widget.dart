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

class _OpenEndedQuestionWidgetState extends State<OpenEndedQuestionWidget> {
  late TextEditingController _questionController;
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.question.question);
    final correctAnswer = widget.question.correctAnswer;
    _answerController = TextEditingController(
      text: correctAnswer is String
          ? correctAnswer
          : (correctAnswer is List ? correctAnswer.join(', ') : ''),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Textual Question",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8),
        TextField(
          controller: _questionController,
          decoration: InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.question.question = value;
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            labelText: 'Correct Answers',
            border: OutlineInputBorder(),
            hintText: "Comma-separated answers",
          ),
          onChanged: (value) {
            widget.question.correctAnswer = value;
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}
