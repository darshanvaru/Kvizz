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

class _SingleChoiceQuestionWidgetState extends State<SingleChoiceQuestionWidget> {
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

    // FIXED: Ensure minimum 2 options for single choice
    if (_optionControllers.length < 2) {
      while (_optionControllers.length < 2) {
        _optionControllers.add(TextEditingController());
      }
    }

    if (widget.question.correctAnswer.isNotEmpty) {
      final correctText = widget.question.correctAnswer.first;
      _correctAnswerIndex = widget.question.options.indexOf(correctText);
      // FIXED: Handle case where correct answer is not found in options
      if (_correctAnswerIndex == -1) {
        _correctAnswerIndex = null;
      }
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
    // FIXED: Prevent removing options if less than 2 remain
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Single choice questions need at least 2 options')),
      );
      return;
    }

    setState(() {
      _optionControllers[index].dispose(); // FIXED: Dispose controller before removing
      _optionControllers.removeAt(index);
      if (_correctAnswerIndex == index) {
        _correctAnswerIndex = null;
      } else if (_correctAnswerIndex != null && _correctAnswerIndex! > index) {
        _correctAnswerIndex = _correctAnswerIndex! - 1;
      }
      _updateModel(); // FIXED: Update model after removing option
    });
  }

  void _updateModel() {
    widget.question.question = _questionController.text.trim();
    widget.question.options =
        _optionControllers.map((c) => c.text.trim()).toList();

    // FIXED: Better validation for correct answer
    if (_correctAnswerIndex != null &&
        _correctAnswerIndex! < widget.question.options.length &&
        widget.question.options[_correctAnswerIndex!].isNotEmpty) {
      final correctText = widget.question.options[_correctAnswerIndex!];
      // widget.question.correctAnswer = [correctText];
      widget.question.correctAnswer = [_correctAnswerIndex!.toString()];
    } else {
      widget.question.correctAnswer = [];
    }
  }

  // FIXED: Added method to handle option text changes
  void _onOptionTextChanged(int index) {
    _updateModel();
    // If this was the selected correct answer and now it's empty, clear selection
    if (_correctAnswerIndex == index && _optionControllers[index].text.trim().isEmpty) {
      setState(() {
        _correctAnswerIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Single Choice Question",
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _questionController,
          onChanged: (_) => _updateModel(),
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Options (Select single correct)',
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
                  // FIXED: Don't allow empty options to be selected as correct
                  if (_optionControllers[index].text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter option text first')),
                    );
                    return;
                  }
                  setState(() {
                    _correctAnswerIndex = val;
                    _updateModel();
                  });
                },
              ),
              title: TextField(
                controller: _optionControllers[index],
                onChanged: (_) => _onOptionTextChanged(index), // FIXED: Use dedicated method
                decoration: InputDecoration(
                  fillColor: Colors.grey.shade100,
                  hintText: 'Option ${index + 1}',
                  border: InputBorder.none,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeOption(index),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _optionControllers.length >= 6 ? null : _addOption, // FIXED: Increased limit to 6
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Delete Question',
                style: TextStyle(color: Colors.red)),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}
