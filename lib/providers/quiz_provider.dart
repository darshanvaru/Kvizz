import 'package:flutter/material.dart';
import '../models/Quiz.dart';

class QuizProvider with ChangeNotifier {
  List<QuizModel> _userQuizzes = [];
  List<QuizModel> _allQuizzes = [];
  QuizModel? _selectedQuiz;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<QuizModel> get userQuizzes => _userQuizzes;
  List<QuizModel> get allQuizzes => _allQuizzes;
  QuizModel? get selectedQuiz => _selectedQuiz;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Select a quiz
  void setSelectedQuiz(QuizModel? quiz) {
    _selectedQuiz = quiz;
    notifyListeners();
  }

  // Update quiz stats
  void updateQuizStats(String quizId, int timesPlayed, double averageScore, int totalUserPlayed) {
    final index = _userQuizzes.indexWhere((quiz) => quiz.id == quizId);
    if (index != -1) {
      final updatedQuiz = QuizModel(
        id: _userQuizzes[index].id,
        title: _userQuizzes[index].title,
        description: _userQuizzes[index].description,
        questions: _userQuizzes[index].questions,
        difficulty: _userQuizzes[index].difficulty,
        creator: _userQuizzes[index].creator,
        tags: _userQuizzes[index].tags,
      );

      _userQuizzes[index] = updatedQuiz;

      // Also update in allQuizzes if it exists there
      final allQuizIndex = _allQuizzes.indexWhere((quiz) => quiz.id == quizId);
      if (allQuizIndex != -1) {
        _allQuizzes[allQuizIndex] = updatedQuiz;
      }

      notifyListeners();
    }
  }
}
