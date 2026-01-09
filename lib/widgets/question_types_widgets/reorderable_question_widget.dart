import 'package:flutter/material.dart';
import 'package:kvizz/models/question_model.dart';

class ReorderableQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onDelete;

  const ReorderableQuestionWidget({
    super.key,
    required this.question,
    required this.onDelete,
  });

  @override
  State<ReorderableQuestionWidget> createState() =>
      _ReorderableQuestionWidgetState();
}

class _ReorderableQuestionWidgetState
    extends State<ReorderableQuestionWidget> {
  late TextEditingController _questionController;
  List<TextEditingController> _optionControllers = []; // FIXED: Added proper typing

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.question.question);

    // FIXED: Create controllers from existing options
    _optionControllers = widget.question.options
        .map((option) => TextEditingController(text: option))
        .toList();

    // FIXED: Ensure minimum 3 options for reorderable questions
    if (_optionControllers.length < 3) {
      while (_optionControllers.length < 3) {
        _optionControllers.add(TextEditingController());
      }
    }

    _updateModel();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    // FIXED: Prevent removing options if less than 3 remain
    if (_optionControllers.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reorderable questions need at least 3 options')),
      );
      return;
    }

    setState(() {
      _optionControllers[index].dispose(); // FIXED: Dispose controller before removing
      _optionControllers.removeAt(index);
      _updateModel(); // FIXED: Update model after removing option
    });
  }

  void _updateModel() {
    widget.question.question = _questionController.text.trim();

    // Get current values from controllers
    List<String> currentOptions = _optionControllers
        .map((controller) => controller.text.trim())
        .toList();

    widget.question.options = currentOptions;

    // Save the current order as indices (as strings)
    widget.question.correctAnswer = List.generate(currentOptions.length, (index) => index.toString());
    // widget.question.correctAnswer = List.from(currentOptions);
  }

  @override
  void dispose() {
    _questionController.dispose();
    // FIXED: Dispose all option controllers
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Reorderable Question",
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _questionController,
          decoration: const InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _updateModel(); // FIXED: Update model on change
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Options (Arrange in the correct order)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        // FIXED: Better visual indication for reorderable items
        Text(
          'Drag and drop to reorder the options',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _optionControllers.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final controller = _optionControllers.removeAt(oldIndex);
              _optionControllers.insert(newIndex, controller);
              _updateModel(); // FIXED: Update model after reordering
            });
          },
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              key: ValueKey('option_$index'), // FIXED: Better key generation
              child: ListTile(
                leading: const Icon(Icons.drag_handle, color: Colors.grey),
                title: TextField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1}',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _updateModel(); // FIXED: Update model when text changes
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeOption(index),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _optionControllers.length >= 8 ? null : _addOption, // FIXED: Set reasonable limit
          icon: const Icon(Icons.add),
          label: const Text("Add Option"),
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
