import 'package:flutter/material.dart';

import '../models/Question.dart';
import '../widgets/multiple_choice_question_widget.dart';
import '../widgets/open_ended_question_widget.dart';
import '../widgets/reorderable_question_widget.dart';
import '../widgets/single_choice_question_widget.dart';

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
        return Placeholder();
      // return TrueFalseQuestionWidget(
      //   question: question,
      //   onDelete: () => _removeQuestion(question.id),
      // );
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
      appBar: AppBar(title: Text('Create Quiz')),
      body: questions.isEmpty
          ? Center(child: Text('No questions yet. Tap + to add.'))
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
                    color: Colors.grey.withValues(alpha: 0.8),
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
      )
      ,
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuestionTypePicker,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
    );
  }
}
