import 'package:flutter/material.dart';
import 'package:kvizz/screens/quiz_screen.dart';

import '../models/Question.dart';
import '../providers/dummy_data.dart' as dummy_data;
import '../widgets/question_types_widgets/multiple_choice_question_widget.dart';
import '../widgets/question_types_widgets/open_ended_question_widget.dart';
import '../widgets/question_types_widgets/reorderable_question_widget.dart';
import '../widgets/question_types_widgets/single_choice_question_widget.dart';
import '../widgets/question_types_widgets/true_false_question_widget.dart';

class QuizCreationScreen extends StatefulWidget {
  @override
  _QuizCreationScreenState createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  List<QuestionModel> questions = [];

  void _addQuestion(QuestionType type) {
    final newQuestion = QuestionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
          if (!q.options.contains(q.options[q.correctAnswer.first])) {
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
          if (q.correctAnswer.isEmpty || q.correctAnswer.trim().isEmpty) {
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
          // List<String> correctOrder = q.correctAnswer
          //     .split(',')
          //     .map((e) => e.trim())
          //     .where((e) => e.isNotEmpty)
          //     .toList();
          //
          // if (correctOrder.length != q.options.length) {
          //   _showError(
          //     'Reorder question "${q.question}" must have correct order matching all options.',
          //   );
          //   return;
          // }
          // if (!Set.from(q.options).containsAll(correctOrder)) {
          //   _showError(
          //     'Correct order does not match options in question "${q.question}".',
          //   );
          //   return;
          // }
          print("Reorder question log");
          print("Reorder question options: ${q.options}");
          print("Reorder question correct answer: ${q.correctAnswer}");
          print("Reorder question correct answer index: ${q.correctAnswer.runtimeType}");
          break;

        case QuestionType.trueFalse:
          print("Correct answer type: ${q.correctAnswer.runtimeType}");
          if (!(q.correctAnswer == 'True' || q.correctAnswer == 'False')) {
            _showError(
              'True/False question "${q.question}" must have a correct answer selected.',
            );
            return;
          }
          break;
      }
    }
    print("___out of switch");

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Create Quiz'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).buttonTheme.colorScheme?.primary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Save"),
                    SizedBox(width: 5),
                    Icon(Icons.save),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => QuizScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Give Quiz"),
                    SizedBox(width: 5),
                    Icon(Icons.save),
                  ],
                ),
              ),

              SizedBox(width: 5),
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
                    buildDefaultDragHandles: true,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = questions.removeAt(oldIndex);
                        questions.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        key: ValueKey(questions[index].id),
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
                                color: Colors.grey.withOpacity(0.8),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.drag_handle, color: Colors.grey),
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
