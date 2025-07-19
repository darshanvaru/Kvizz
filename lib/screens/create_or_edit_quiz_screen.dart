import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/Question.dart';
import '../models/Quiz.dart';
import '../providers/quiz_provider.dart';
import '../widgets/question_types_widgets/multiple_choice_question_widget.dart';
import '../widgets/question_types_widgets/open_ended_question_widget.dart';
import '../widgets/question_types_widgets/reorderable_question_widget.dart';
import '../widgets/question_types_widgets/single_choice_question_widget.dart';
import '../widgets/question_types_widgets/true_false_question_widget.dart';

class CreateOrEditQuizScreen extends StatefulWidget {
  final List<QuestionModel>? questions;
  final QuizModel? editingQuiz;

  const CreateOrEditQuizScreen({super.key, this.questions, this.editingQuiz});

  @override
  _CreateOrEditQuizScreenState createState() => _CreateOrEditQuizScreenState();
}

class _CreateOrEditQuizScreenState extends State<CreateOrEditQuizScreen> {
  late List<QuestionModel> questions;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timePerQuestionController = TextEditingController();
  final _pointsPerQuestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    questions = widget.questions ?? widget.editingQuiz?.questions ?? [];

    _titleController.text = widget.editingQuiz?.title ?? '';
    _descController.text = widget.editingQuiz?.description ?? '';
    _timePerQuestionController.text = widget.editingQuiz?.timePerQuestion.toString() ?? '30';
    _pointsPerQuestionController.text = widget.editingQuiz?.pointsPerQuestion.toString() ?? '100';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timePerQuestionController.dispose();
    _pointsPerQuestionController.dispose();
    super.dispose();
  }

  void _addQuestion(QuestionType type) {
    final newQuestion = QuestionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}*${Random().nextInt(100000)}',
      question: '',
      options: [],
      correctAnswer: [],
      type: type,
    );
    setState(() => questions.add(newQuestion));
  }

  void _removeQuestion(String id) {
    setState(() => questions.removeWhere((q) => q.id == id));
  }

  void _saveQuestions() {
    if (_titleController.text.trim().isEmpty) {
      return _showError("Title can't be empty.");
    }
    if (_timePerQuestionController.text.trim().isEmpty ||
        int.tryParse(_timePerQuestionController.text.trim()) == null) {
      return _showError("Enter valid time per question (in seconds).");
    }
    if (_pointsPerQuestionController.text.trim().isEmpty ||
        int.tryParse(_pointsPerQuestionController.text.trim()) == null) {
      return _showError("Enter valid points per question.");
    }

    for (var q in questions) {
      if (q.question.trim().isEmpty) {
        return _showError('Each question must have text.');
      }

      switch (q.type) {
        case QuestionType.single:
        case QuestionType.multiple:
          if (q.options.length < 2 ||
              q.options.any((o) => o.trim().isEmpty) ||
              q.correctAnswer.isEmpty) {
            return _showError('Fix options for "${q.question}".');
          }
          break;
        case QuestionType.open:
          if (q.correctAnswer.isEmpty) {
            return _showError('Open-ended question "${q.question}" needs answers.');
          }
          break;
        case QuestionType.reorder:
          if (q.options.length < 3) {
            return _showError('Reorder question "${q.question}" needs at least 3 options.');
          }
          break;
        case QuestionType.trueFalse:
          if (!(q.correctAnswer.first == 'True' || q.correctAnswer.first == 'False')) {
            return _showError('True/False question "${q.question}" needs valid answer.');
          }
          break;
      }
    }

    for (var q in questions) {
      if (q.type == QuestionType.reorder) {
        q.options.shuffle();
        while (q.options.join() == q.correctAnswer.join()) {
          q.options.shuffle();
        }
      }
    }

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final quiz = QuizModel(
      id: widget.editingQuiz?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      questions: questions,
      type: 'manual',
      timePerQuestion: int.parse(_timePerQuestionController.text.trim()),
      pointsPerQuestion: int.parse(_pointsPerQuestionController.text.trim()),
      questionOrder: 'fixed',
      timesPlayed: 0,
      averageScore: 0,
      totalUserPlayed: 0,
      participantLimit: 10,
      difficulty: 'medium',
      isActive: true,
      createdAt: DateTime.now(),
    );

    if (widget.editingQuiz != null) {
      quizProvider.updateQuiz(quiz);
    } else {
      quizProvider.addQuiz(quiz);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.editingQuiz != null ? 'Quiz updated!' : 'Quiz created!')),
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildQuestionWidget(QuestionModel question) {
    switch (question.type) {
      case QuestionType.single:
        return SingleChoiceQuestionWidget(question: question, onDelete: () => _removeQuestion(question.id));
      case QuestionType.multiple:
        return MultipleChoiceQuestionWidget(question: question, onDelete: () => _removeQuestion(question.id));
      case QuestionType.open:
        return OpenEndedQuestionWidget(question: question, onDelete: () => _removeQuestion(question.id));
      case QuestionType.trueFalse:
        return TrueFalseQuestionWidget(question: question, onDelete: () => _removeQuestion(question.id));
      case QuestionType.reorder:
        return ReorderableQuestionWidget(question: question, onDelete: () => _removeQuestion(question.id));
    }
  }

  void _showQuestionTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: QuestionType.values.map((type) {
          return ListTile(
            title: Text(type.toString().split('.').last),
            onTap: () {
              Navigator.pop(context);
              _addQuestion(type);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingQuiz != null ? 'Edit Quiz' : 'Create Quiz'),
        actions: [
          ElevatedButton(
            onPressed: questions.isEmpty ? () => _showError('Add at least one question') : _saveQuestions,
            child: const Row(children: [Text("Save"), SizedBox(width: 5), Icon(Icons.save)]),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Quiz Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _timePerQuestionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Seconds per question",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _pointsPerQuestionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Points per question",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('Add Question'),
              onTap: _showQuestionTypePicker,
            ),
          ),
          Expanded(
            child: questions.isEmpty
                ? const Center(child: Text('No questions yet. Tap + to add.'))
                : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = questions.removeAt(oldIndex);
                  questions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  key: Key('${questions[index].id}_$index'),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        _buildQuestionWidget(questions[index]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
