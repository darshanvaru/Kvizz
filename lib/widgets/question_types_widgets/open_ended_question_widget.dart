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

    // Join list into a single comma-separated string
    _answerController = TextEditingController(
      text: widget.question.correctAnswer.join(', '),
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
        Text("Textual Question", style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _questionController,
          decoration: const InputDecoration(
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
          decoration: const InputDecoration(
            labelText: 'Correct Answers',
            border: OutlineInputBorder(),
            hintText: "Comma-separated answers",
          ),
          onChanged: (value) {
            // Split input by comma and trim whitespace
            widget.question.correctAnswer = value
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}
