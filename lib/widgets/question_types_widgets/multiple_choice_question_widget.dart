import 'package:flutter/material.dart';
import 'package:kvizz/models/question_model.dart';

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
  Set<String> _correctAnswerValues = {};

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.question.question;
    _optionControllers = widget.question.options
        .map((opt) => TextEditingController(text: opt))
        .toList();
    _correctAnswerValues = widget.question.correctAnswer.toSet();

    // FIXED: Ensure minimum 2 options for multiple choice
    if (_optionControllers.length < 2) {
      while (_optionControllers.length < 2) {
        _optionControllers.add(TextEditingController());
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
        const SnackBar(content: Text('Multiple choice questions need at least 2 options')),
      );
      return;
    }

    setState(() {
      String removedValue = _optionControllers[index].text.trim();
      _optionControllers[index].dispose(); // FIXED: Dispose controller before removing
      _optionControllers.removeAt(index);
      _correctAnswerValues.remove(removedValue);
      _updateModel(); // FIXED: Update model after removing option
    });
  }

  void _toggleCorrectAnswer(int index) {
    String value = _optionControllers[index].text.trim();
    // FIXED: Don't allow empty options to be marked as correct
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter option text first')),
      );
      return;
    }

    setState(() {
      if (_correctAnswerValues.contains(value)) {
        _correctAnswerValues.remove(value);
      } else {
        _correctAnswerValues.add(value);
      }
      _updateModel(); // FIXED: Update model when toggling correct answer
    });
  }

  void _updateModel() {
    widget.question.question = _questionController.text.trim();
    widget.question.options = _optionControllers.map((c) => c.text.trim()).toList();
    // FIXED: Update correct answers only if they exist in current options
    // Save indices of correct answers as strings
    List<String> correctIndices = [];
    for (int i = 0; i < widget.question.options.length; i++) {
      final value = widget.question.options[i];
      if (_correctAnswerValues.contains(value) && value.isNotEmpty) {
        correctIndices.add(i.toString());
      }
    }
    widget.question.correctAnswer = correctIndices;
    // widget.question.correctAnswer = _correctAnswerValues
    //     .where((ans) => widget.question.options.contains(ans) && ans.isNotEmpty)
    //     .toList();
  }

  // FIXED: Added method to handle option text changes
  void _onOptionTextChanged(int index) {
    String oldValue = widget.question.options.length > index ? widget.question.options[index] : '';
    String newValue = _optionControllers[index].text.trim();

    // Update correct answers if this option was marked as correct
    if (_correctAnswerValues.contains(oldValue) && newValue != oldValue) {
      _correctAnswerValues.remove(oldValue);
      if (newValue.isNotEmpty) {
        _correctAnswerValues.add(newValue);
      }
    }
    _updateModel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Multiple Choice Question",
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
          'Options (Select multiple correct)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...List.generate(_optionControllers.length, (index) {
          final text = _optionControllers[index].text.trim();
          final isCorrect = _correctAnswerValues.contains(text);

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
                onChanged: (_) => _onOptionTextChanged(index), // FIXED: Use dedicated method
                decoration: InputDecoration(
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
          onPressed: _optionControllers.length >= 4 ? null : _addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
        const SizedBox(height: 12),
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
