import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';


class MultipleChoiceQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.question,
    this.onDelete,
  });

  @override
  State<MultipleChoiceQuestionWidget> createState() =>
      _MultipleChoiceQuestionWidgetState();
}

class _MultipleChoiceQuestionWidgetState
    extends State<MultipleChoiceQuestionWidget> {
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController> _optionControllers = [];
  Set<dynamic> _correctAnswerIndices = {};

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.question.question;

    _optionControllers = widget.question.options
        .map((opt) => TextEditingController(text: opt))
        .toList();

    _correctAnswerIndices = widget.question.correctAnswer.toSet();
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
      _correctAnswerIndices =
          _correctAnswerIndices.where((i) => i != index).map((i) {
            // Shift indices after removed option
            return i > index ? i - 1 : i;
          }).toSet();
    });
  }

  void _toggleCorrectAnswer(int index) {
    setState(() {
      if (_correctAnswerIndices.contains(index)) {
        _correctAnswerIndices.remove(index);
      } else {
        _correctAnswerIndices.add(index);
      }
    });
  }

  void _updateModel() {
    widget.question.question = _questionController.text.trim();
    widget.question.options =
        _optionControllers.map((c) => c.text.trim()).toList();
    widget.question.correctAnswer = _correctAnswerIndices.toList();
  }

  @override
  Widget build(BuildContext context) {
    _updateModel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Multiple Choice Question",
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
          'Options (Select multiple correct)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...List.generate(_optionControllers.length, (index) {
          final isCorrect = _correctAnswerIndices.contains(index);

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
              leading: Checkbox(
                value: isCorrect,
                onChanged: (_) => _toggleCorrectAnswer(index),
              ),
              title: TextField(
                controller: _optionControllers[index],
                onChanged: (_) => _updateModel(),
                decoration: InputDecoration(
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
