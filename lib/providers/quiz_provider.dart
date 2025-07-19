import 'package:flutter/cupertino.dart';
import '../models/Question.dart';
import '../models/Quiz.dart';

class QuizProvider with ChangeNotifier {
  final List<QuizModel> _quizzes = [];

  // Static list of demo questions so we don't call `QuizProvider()` again
  static final List<QuestionModel> demoQuestions = [
    QuestionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: "What is the capital of France?",
      options: ["Paris", "London", "Berlin", "Rome"],
      type: QuestionType.single,
      correctAnswer: ["Paris"],
    ),
    QuestionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: "Select the programming languages.",
      options: ["Python", "Flutter", "C++", "HTML"],
      type: QuestionType.multiple,
      correctAnswer: ["Python", "C++"],
    ),
    QuestionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: "Describe your experience with AI.",
      options: [],
      type: QuestionType.open,
      correctAnswer: ["good", "excellent", "Fabulous"],
    ),
    QuestionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: "Arrange the steps in priority.",
      options: ["Plan", "Code", "Design", "Test"],
      type: QuestionType.reorder,
      correctAnswer: ["Plan", "Design", "Code", "Test"],
    ),
  ];

  QuizProvider() {
    _quizzes.addAll([
      QuizModel(
        id: "1",
        title: "AI Basics",
        description: "Introduction to AI concepts.",
        questions: demoQuestions,
        type: "manual",
        timePerQuestion: 30,
        questionOrder: "fixed",
        pointsPerQuestion: 500,
        timesPlayed: 10,
        averageScore: 75,
        totalUserPlayed: 20,
        participantLimit: 10,
        difficulty: "medium",
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      QuizModel(
        id: "2",
        title: "Flutter Deep Dive",
        description: "Advanced concepts in Flutter.",
        questions: demoQuestions,
        type: "ai-generated",
        timePerQuestion: 45,
        questionOrder: "random",
        pointsPerQuestion: 1000,
        timesPlayed: 5,
        averageScore: 60,
        totalUserPlayed: 8,
        participantLimit: 20,
        difficulty: "hard",
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  List<QuizModel> get quizzes => _quizzes;

  void addQuiz(QuizModel quiz) {
    _quizzes.add(quiz);
    notifyListeners();
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
