import 'package:flutter/material.dart';
import 'package:kvizz/models/Question.dart';

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
  List<String> options = [];

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.question.question);
    options = List<String>.from(widget.question.options);
  }

  void _addOption() {
    setState(() {
      options.add('');
    });
  }

  void _removeOption(int index) {
    setState(() {
      options.removeAt(index);
    });
  }

  void _updateCorrectAnswer() {
    // Save the current reordered options as correct order
    widget.question.options = List.from(options);
    widget.question.correctAnswer = options.join('|||'); // You can use comma too
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
        Text("Reorderable Choice Question",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8),
        TextField(
          controller: _questionController,
          decoration: InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.question.question = value;
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Options (Arrange the options in the desired order)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = options.removeAt(oldIndex);
              options.insert(newIndex, item);
            });
            _updateCorrectAnswer();
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
              key: ValueKey('$index-${options[index]}'),
              child: ListTile(
                leading: const Icon(Icons.drag_handle),
                title: TextFormField(
                  initialValue: options[index],
                  decoration:
                  InputDecoration(labelText: 'Option ${index + 1}'),
                  onChanged: (value) {
                    options[index] = value;
                    _updateCorrectAnswer();
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeOption(index),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add),
          label: const Text("Add Option"),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}
