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
    _correctAnswer = (widget.question.correctAnswer != null && widget.question.correctAnswer!.isNotEmpty)
        ? widget.question.correctAnswer!.first
        : 'True';
  }

  void _setCorrectAnswer(String value) {
    setState(() {
      _correctAnswer = value;
      widget.question.correctAnswer = [value];
    });
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
        SizedBox(height: 8),
        // Question Field
        TextFormField(
          controller: _questionController,
          onChanged: (val) => widget.question.question = val,
          decoration: InputDecoration(
            labelText: 'True/False Question',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        const SizedBox(height: 16),

        // True/False Selection
        Text("Select the correct answer:", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: ['True', 'False'].map((value) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(value),
                value: value,
                groupValue: _correctAnswer,
                onChanged: (val) {
                  if (val != null) _setCorrectAnswer(val);
                },
              ),
            );
          }).toList(),
        ),

        // Delete Button
        if (widget.onDelete != null)
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: widget.onDelete,
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }
}
