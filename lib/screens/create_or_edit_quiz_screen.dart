import 'dart:math';

import 'package:flutter/material.dart';

import '../models/Question.dart';
import '../providers/dummy_data.dart' as dummy_data;
import '../widgets/question_types_widgets/multiple_choice_question_widget.dart';
import '../widgets/question_types_widgets/open_ended_question_widget.dart';
import '../widgets/question_types_widgets/reorderable_question_widget.dart';
import '../widgets/question_types_widgets/single_choice_question_widget.dart';
import '../widgets/question_types_widgets/true_false_question_widget.dart';

class QuizCreationOrEditScreen extends StatefulWidget {
  final List<QuestionModel>? questions;

  QuizCreationOrEditScreen({Key? key, this.questions}) : super(key: key);

  @override
  _QuizCreationOrEditScreenState createState() => _QuizCreationOrEditScreenState();
}

class _QuizCreationOrEditScreenState extends State<QuizCreationOrEditScreen> {
  late List<QuestionModel> questions;

  @override
  void initState() {
    super.initState();
    questions = widget.questions ?? [];
  }

  void _addQuestion(QuestionType type) {
    final newQuestion = QuestionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}*${Random().nextInt(100000)}',
      question: '',
      options: [],
      correctAnswer: [],
      type: type,
    );
    setState(() {
      questions.add(newQuestion);
    });
  }

  void _removeQuestion(String id) {
    setState(() {
      questions.removeWhere((q) => q.id == id);
    });
  }

  void _saveQuestions() {
    for (var q in questions) {
      // General validation: Question text should not be empty
      if (q.question.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All questions must have a question text.')),
        );
        return;
      }

      // Specific validation based on question type
      switch (q.type) {
        ///Single choice question
        case QuestionType.single:
          if (q.options.length < 2) {
            _showError(
              'Single choice question "${q.question}" must have at least 2 options.',
            );
            return;
          }
          for (var option in q.options) {
            if (option.trim().isEmpty) {
              _showError(
                'Multiple choice question "${q.question}" has empty options.',
              );
              return;
            }
          }
          if (!q.options.contains(q.correctAnswer.first)) {
            _showError(
              'Single choice question "${q.question}" must have a correct answer selected.',
            );
            return;
          }
          break;

        case QuestionType.multiple:
          if (q.options.length < 2) {
            _showError(
              'Multiple choice question "${q.question}" must have at least 2 options.',
            );
            return;
          }
          for (var option in q.options) {
            if (option.trim().isEmpty) {
              _showError(
                'Multiple choice question "${q.question}" has empty options.',
              );
              return;
            }
          }
          if (q.correctAnswer.isEmpty) {
            _showError(
              'Multiple choice question "${q.question}" must have at least one correct option selected.',
            );
            return;
          }
          break;

        case QuestionType.open:
          print("Correct answer type: ${q.correctAnswer.runtimeType}");
          print("Correct answer list: ${q.correctAnswer}");
          // q.correctAnswer.every((answer) => print({answer.trim()}));?
          if (q.correctAnswer.isEmpty) {
            _showError(
              'Open-ended question "${q.question}" must have a correct answer.',
            );
            return;
          }
          break;

        case QuestionType.reorder:
          if (q.options.length < 3) {
            _showError(
              'Reorder question "${q.question}" must have at least 3 options.',
            );
            return;
          }
          print("Reorder question log");
          print("Reorder question options: ${q.options}");
          print("Reorder question correct answer: ${q.correctAnswer}");
          print(
            "Reorder question correct answer index: ${q.correctAnswer.runtimeType}",
          );
          break;

        case QuestionType.trueFalse:
          print("Correct answer type: ${q.correctAnswer.runtimeType}");
          if (!(q.correctAnswer.first == 'True' ||
              q.correctAnswer.first == 'False')) {
            _showError(
              'True/False question "${q.question}" must have a correct answer selected.',
            );
            return;
          }
          break;
      }
    }
    print("___out of Validation switch");

    // Reorder question shuffling (don’t change correctAnswer!)
    for (var q in questions) {
      if (q.type == QuestionType.reorder) {
        q.options.shuffle(); //Randomizing quiz
        while (q.options == q.correctAnswer) {
          q.options.shuffle();
        }
      }
    }

    // Save to dummy data
    dummy_data.clearDummyData(); // Clear existing questions
    dummy_data.questions.addAll(questions);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Questions saved successfully!')));

    setState(() {
      questions.clear();
    });
  }

  // Helper to show error snack bars
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildQuestionWidget(QuestionModel question) {
    switch (question.type) {
      case QuestionType.single:
        return SingleChoiceQuestionWidget(
          question: question,
          onDelete: () => _removeQuestion(question.id),
        );
      case QuestionType.multiple:
        return MultipleChoiceQuestionWidget(
          question: question,
          onDelete: () => _removeQuestion(question.id),
        );
      case QuestionType.open:
        return OpenEndedQuestionWidget(
          question: question,
          onDelete: () => _removeQuestion(question.id),
        );
      case QuestionType.trueFalse:
        return TrueFalseQuestionWidget(
          question: question,
          onDelete: () => _removeQuestion(question.id),
        );
      case QuestionType.reorder:
        return ReorderableQuestionWidget(
          question: question,
          onDelete: () => _removeQuestion(question.id),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Create Quiz')],
          ),
        ),
        actions: [
          Row(
            children: [
              //Save Button
              ElevatedButton(
                onPressed: questions.isEmpty
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            elevation: 8,
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Add a question to save the quiz.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    : _saveQuestions,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Save"),
                    SizedBox(width: 5),
                    Icon(Icons.save),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(Icons.add, color: Colors.green),
              title: Text('Add Question'),
              onTap: _showQuestionTypePicker,
            ),
          ),
          Expanded(
            child: questions.isEmpty
                ? Center(
                    child: Text(
                      'No questions yet. Tap + to add.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: questions.length,
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = questions.removeAt(oldIndex);
                        questions.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      print("Ids: ${questions[index].id}");
                      return Container(
                        key: Key('${questions[index].id}_$index'),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 10,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.8),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 10),
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
