import 'package:flutter/material.dart';
import 'package:kvizz/models/question_model.dart';

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

  void _updateModel() {
    widget.question.question = _questionController.text.trim();
    widget.question.correctAnswer = _answerController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Open-Ended Question",
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _questionController,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _updateModel();
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _answerController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Correct Answers',
            border: OutlineInputBorder(),
            hintText: "Enter comma-separated possible answers (e.g., Paris, paris, PARIS)",
            helperText: "Multiple acceptable answers can be separated by commas",
            helperMaxLines: 2
          ),
          onChanged: (value) {
            _updateModel();
          },
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Delete Question', style: TextStyle(color: Colors.red)),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}
