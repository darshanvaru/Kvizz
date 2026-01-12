import 'package:flutter/material.dart';
import 'package:kvizz/models/question_model.dart';

class TrueFalseQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const TrueFalseQuestionWidget({
    super.key,
    required this.question,
    required this.onDelete,
  });

  @override
  State<TrueFalseQuestionWidget> createState() =>
      _TrueFalseQuestionWidgetState();
}

class _TrueFalseQuestionWidgetState extends State<TrueFalseQuestionWidget> {
  late TextEditingController _questionController;
  late String _correctAnswer;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.question);

    if (widget.question.correctAnswer.isNotEmpty) {
      String answer = widget.question.correctAnswer.first.toLowerCase();
      if (answer == 'true' || answer == '1') {
        _correctAnswer = 'True';
      } else if (answer == 'false' || answer == '0') {
        _correctAnswer = 'False';
      } else {
        _correctAnswer = 'True';
      }
    } else {
      _correctAnswer = 'True';
    }

    widget.question.options = ['True', 'False'];
    _updateModel();
  }

  void _setCorrectAnswer(String value) {
    setState(() {
      _correctAnswer = value;
      _updateModel();
    });
  }

  void _updateModel() {
    widget.question.question = _questionController.text.trim();
    widget.question.options = ['True', 'False'];
    if (_correctAnswer.toLowerCase() == 'true') {
      widget.question.correctAnswer = ['0'];
    } else {
      widget.question.correctAnswer = ['1'];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("True or False Question",
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),

        // Question Field
        TextField(
          controller: _questionController,
          onChanged: (val) {
            _updateModel();
          },
          decoration: const InputDecoration(
            labelText: 'True/False Question',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        const SizedBox(height: 16),

        // True/False Selection
        Text("Select the correct answer:",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('True'),
                value: 'True',
                groupValue: _correctAnswer,
                onChanged: (val) {
                  if (val != null) _setCorrectAnswer(val);
                },
                activeColor: Colors.green,
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('False'),
                value: 'False',
                groupValue: _correctAnswer,
                onChanged: (val) {
                  if (val != null) _setCorrectAnswer(val);
                },
                activeColor: Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delete Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Delete Question', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
