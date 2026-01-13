// game_session_provider.dart
import 'package:flutter/material.dart';
import '../models/game_session_model.dart';

class GameSessionProvider extends ChangeNotifier {
  GameSessionModel? _gameSession;
  String? _error;

  // Getters
  GameSessionModel? get gameSession => _gameSession;
  String? get error => _error;
  bool get hasSession => _gameSession != null;

  bool get isWaiting => _gameSession?.isWaiting ?? false;
  bool get isStarted => _gameSession?.isStarted ?? false;
  bool get isFinished => _gameSession?.isFinished ?? false;

  int get participantCount => _gameSession?.participantCount ?? 0;
  List<Participant> get participants => _gameSession?.participants ?? [];
  List<LeaderboardEntry> get leaderboard => _gameSession?.leaderboard ?? [];

  String get gameCode => _gameSession?.gameCode.toString() ?? '';
  String get status => _gameSession?.status ?? '';

  QuizData? get quizData => _gameSession?.quizData;
  HostData? get hostData => _gameSession?.hostData;
  GameSettings? get settings => _gameSession?.settings;
  CurrentQuestion? get currentQuestion => _gameSession?.currentQuestion;

  // In game_session_provider.dart
  void updateSessionFromJson(Map<String, dynamic> json, String from) {
    try {
      _gameSession = GameSessionModel.fromJson(json);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to parse session data: $e';
      notifyListeners();
    }
  }

  // Set error
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
