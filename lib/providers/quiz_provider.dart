import 'package:flutter/material.dart';
import '../models/Quiz.dart';

class QuizProvider with ChangeNotifier {
  QuizModel? _quiz;

  QuizModel? get quiz => _quiz;

  void setQuiz(QuizModel quiz) {
    _quiz = quiz;
    notifyListeners();
  }

  void clearQuiz() {
    _quiz = null;
    notifyListeners();
  }
}
