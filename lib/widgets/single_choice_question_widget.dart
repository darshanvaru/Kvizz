import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';

class SingleChoiceQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const SingleChoiceQuestionWidget({
    super.key,
    required this.question,
    this.onDelete,
  });

  @override
  State<SingleChoiceQuestionWidget> createState() =>
      _SingleChoiceQuestionWidgetState();
}

class _SingleChoiceQuestionWidgetState
    extends State<SingleChoiceQuestionWidget> {
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController> _optionControllers = [];

  int? _correctAnswerIndex;

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.question.question;

    _optionControllers = widget.question.options
        .map((opt) => TextEditingController(text: opt))
        .toList();

    if (widget.question.correctAnswer.isNotEmpty) {
      _correctAnswerIndex = widget.question.correctAnswer.first;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index);
      if (_correctAnswerIndex == index) {
        _correctAnswerIndex = null;
      } else if (_correctAnswerIndex != null && _correctAnswerIndex! > index) {
        _correctAnswerIndex = _correctAnswerIndex! - 1;
      }
    });
  }

  void _updateModel() {
    widget.question.question = _questionController.text;
    widget.question.options =
        _optionControllers.map((c) => c.text.trim()).toList();
    widget.question.correctAnswer = _correctAnswerIndex != null
        ? [_correctAnswerIndex!]
        : [];
  }

  @override
  Widget build(BuildContext context) {
    _updateModel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Single Choice Question",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8),
        TextField(
          controller: _questionController,
          onChanged: (_) => _updateModel(),
          decoration: InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Options',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...List.generate(_optionControllers.length, (index) {
          final isCorrect = _correctAnswerIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCorrect ? Colors.teal : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Radio<int>(
                value: index,
                groupValue: _correctAnswerIndex,
                onChanged: (val) {
                  setState(() {
                    _correctAnswerIndex = val;
                  });
                },
              ),
              title: TextField(
                controller: _optionControllers[index],
                onChanged: (_) => _updateModel(),
                decoration: InputDecoration(
                  fillColor: Colors.grey.shade100,
                  hintText: 'Option ${index + 1}',
                  border: InputBorder.none,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeOption(index),
              ),
            ),
          );
        }),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _optionControllers.length >= 4? null : _addOption,
          icon: Icon(Icons.add),
          label: Text('Add Option'),
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: Icon(Icons.delete_forever, color: Colors.red),
            label: Text('Delete Question', style: TextStyle(color: Colors.red)),
            onPressed: widget.onDelete,
          ),
        )
      ],
    );
  }
}
