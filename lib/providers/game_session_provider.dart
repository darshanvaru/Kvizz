// game_session_provider.dart
import 'package:flutter/material.dart';
import 'package:kvizz/PrintHelper.dart';
import '../models/game_session_model.dart';

class GameSessionProvider extends ChangeNotifier {
  GameSessionModel? _gameSession;
  bool _isLoading = false;
  String? _error;

  // Getters
  GameSessionModel? get gameSession => _gameSession;
  bool get isLoading => _isLoading;
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

  // Update the entire session (from socket events)
  void updateSession(GameSessionModel newSession) {
    _gameSession = newSession;
    _error = null;
    notifyListeners();
  }

  // In game_session_provider.dart
  void updateSessionFromJson(Map<String, dynamic> json, String from) {
    print("In updateSessionFromJson from $from socket listener ");
    try {
      printFullResponse('🔍 GameSession JSON input from $from: $json');

      _gameSession = GameSessionModel.fromJson(json);
      print('✅ GameSession: ${_gameSession?.id}, Code: ${_gameSession?.gameCode}');
      _error = null;

      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error parsing session data: $e');
      printFullResponse('📄 JSON data: $json');
      print('📍 Stack trace: $stackTrace');
      _error = 'Failed to parse session data: $e';
      notifyListeners();
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear session (when leaving/disconnecting)
  void clearSession() {
    // _gameSession = null;
    //Empty session dummy data
    _gameSession = GameSessionModel(
      id: '',
      quizData: null,
      hostData: null,
      gameCode: 0,
      connectionId: null,
      status: 'previousFinished',
      isActive: false,
      currentQuestion: null,
      participants: [],
      settings: null,
      results: null,
      startedAt: null,
      finishedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
