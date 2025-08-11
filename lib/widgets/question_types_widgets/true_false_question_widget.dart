import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';

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

    // FIXED: Better initialization logic for correct answer
    if (widget.question.correctAnswer.isNotEmpty) {
      String answer = widget.question.correctAnswer.first.toLowerCase();
      if (answer == 'true' || answer == '1') {
        _correctAnswer = 'True';
      } else if (answer == 'false' || answer == '0') {
        _correctAnswer = 'False';
      } else {
        _correctAnswer = 'True'; // Default fallback
      }
    } else {
      _correctAnswer = 'True'; // Default to 'True' if empty
    }

    // FIXED: Set initial options for True/False
    widget.question.options = ['True', 'False'];
    _updateModel();
  }

  void _setCorrectAnswer(String value) {
    setState(() {
      _correctAnswer = value;
      _updateModel(); // FIXED: Update model when answer changes
    });
  }

  // FIXED: Added method to update the model
  void _updateModel() {
    widget.question.question = _questionController.text.trim();
    widget.question.options = ['True', 'False']; // Always set these options
    widget.question.correctAnswer = [_correctAnswer]; // Store as List
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
        TextField( // FIXED: Changed from TextFormField to TextField for consistency
          controller: _questionController,
          onChanged: (val) {
            _updateModel(); // FIXED: Update model on change
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
            style: Theme.of(context).textTheme.titleMedium), // FIXED: Use theme style
        const SizedBox(height: 8),
        // FIXED: Better layout for radio buttons
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
                // FIXED: Add visual indicator for selected answer
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
