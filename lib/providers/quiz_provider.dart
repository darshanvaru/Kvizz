import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Quiz.dart';

class QuizProvider with ChangeNotifier {
  late List<QuizModel> _quizzes = [];

  // Static list of demo questions so we don't call `QuizProvider()` again
  // static final List<QuestionModel> demoQuestions = [
  //   QuestionModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     question: "What is the capital of France?",
  //     options: ["Paris", "London", "Berlin", "Rome"],
  //     type: QuestionType.single,
  //     correctAnswer: ["Paris"],
  //   ),
  //   QuestionModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     question: "Select the programming languages.",
  //     options: ["Python", "Flutter", "C++", "HTML"],
  //     type: QuestionType.multiple,
  //     correctAnswer: ["Python", "C++"],
  //   ),
  //   QuestionModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     question: "Describe your experience with AI.",
  //     options: [],
  //     type: QuestionType.open,
  //     correctAnswer: ["good", "excellent", "Fabulous"],
  //   ),
  //   QuestionModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     question: "Arrange the steps in priority.",
  //     options: ["Plan", "Code", "Design", "Test"],
  //     type: QuestionType.reorder,
  //     correctAnswer: ["Plan", "Design", "Code", "Test"],
  //   ),
  // ];

  // QuizProvider() {
  //   _quizzes.addAll([
  //     QuizModel(
  //       id: "1",
  //       title: "AI Basics",
  //       description: "Introduction to AI concepts.",
  //       questions: demoQuestions,
  //       type: "manual",
  //       creator: ,
  //       difficulty: "medium",
  //       isActive: true,
  //       createdAt: DateTime.now().subtract(const Duration(days: 2)),
  //     ),
  //     QuizModel(
  //       id: "2",
  //       title: "Flutter Deep Dive",
  //       description: "Advanced concepts in Flutter.",
  //       questions: demoQuestions,
  //       type: "ai-generated",
  //       difficulty: "hard",
  //       isActive: true,
  //       createdAt: DateTime.now().subtract(const Duration(days: 1)),
  //       creator: '',
  //     ),
  //   ]);
  // }

  List<QuizModel> get quizzes => _quizzes;

  void addQuiz(QuizModel quiz) {
    _quizzes.add(quiz);
    notifyListeners();
  }

  Future<void> fetchMyQuizzes(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final url = Uri.parse("http://10.20.51.115:8000/api/v1/quizzes/of/$userId");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final List<dynamic> quizList = jsonBody['data']['doc'];
        _quizzes = quizList.map((e) => QuizModel.fromJson(e)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load quizzes');
      }
    } catch (e, stack) {
      print("Error: $e");
      print("Stack: $stack");
      throw Exception('Error: $e');
    }
  }


  void updateQuiz(QuizModel updatedQuiz) {
    final index = _quizzes.indexWhere((q) => q.id == updatedQuiz.id);
    if (index != -1) {
      _quizzes[index] = updatedQuiz;
      notifyListeners();
    }
  }

  void deleteQuizById(String quizId) {
    _quizzes.removeWhere((q) => q.id == quizId);
    notifyListeners();
  }

  void clearAll() {
    _quizzes.clear();
    notifyListeners();
  }
}
