// game_session_provider.dart
import 'package:flutter/material.dart';
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

  // Session state getters
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

  // Update session from JSON (from socket events)
  void updateSessionFromJson(Map<String, dynamic> json) {
    try {
      _gameSession = GameSessionModel.fromJson(json);
      _error = null;
      notifyListeners();
    } catch (e) {
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
    _gameSession = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Add participant (for real-time updates)
  void addParticipant(Participant participant) {
    if (_gameSession != null) {
      final updatedParticipants = List<Participant>.from(_gameSession!.participants);
      updatedParticipants.add(participant);

      _gameSession = GameSessionModel(
        id: _gameSession!.id,
        quizData: _gameSession!.quizData,
        hostData: _gameSession!.hostData,
        gameCode: _gameSession!.gameCode,
        connectionId: _gameSession!.connectionId,
        status: _gameSession!.status,
        isActive: _gameSession!.isActive,
        currentQuestion: _gameSession!.currentQuestion,
        participants: updatedParticipants,
        settings: _gameSession!.settings,
        results: _gameSession!.results,
        startedAt: _gameSession!.startedAt,
        finishedAt: _gameSession!.finishedAt,
        createdAt: _gameSession!.createdAt,
        updatedAt: _gameSession!.updatedAt,
      );
      notifyListeners();
    }
  }

  // Remove participant (for real-time updates)
  void removeParticipant(String participantId) {
    if (_gameSession != null) {
      final updatedParticipants = _gameSession!.participants
          .where((p) => p.id != participantId)
          .toList();

      _gameSession = GameSessionModel(
        id: _gameSession!.id,
        quizData: _gameSession!.quizData,
        hostData: _gameSession!.hostData,
        gameCode: _gameSession!.gameCode,
        connectionId: _gameSession!.connectionId,
        status: _gameSession!.status,
        isActive: _gameSession!.isActive,
        currentQuestion: _gameSession!.currentQuestion,
        participants: updatedParticipants,
        settings: _gameSession!.settings,
        results: _gameSession!.results,
        startedAt: _gameSession!.startedAt,
        finishedAt: _gameSession!.finishedAt,
        createdAt: _gameSession!.createdAt,
        updatedAt: _gameSession!.updatedAt,
      );
      notifyListeners();
    }
  }

  // Update session status
  void updateStatus(String newStatus) {
    if (_gameSession != null) {
      _gameSession = GameSessionModel(
        id: _gameSession!.id,
        quizData: _gameSession!.quizData,
        hostData: _gameSession!.hostData,
        gameCode: _gameSession!.gameCode,
        connectionId: _gameSession!.connectionId,
        status: newStatus,
        isActive: _gameSession!.isActive,
        currentQuestion: _gameSession!.currentQuestion,
        participants: _gameSession!.participants,
        settings: _gameSession!.settings,
        results: _gameSession!.results,
        startedAt: _gameSession!.startedAt,
        finishedAt: _gameSession!.finishedAt,
        createdAt: _gameSession!.createdAt,
        updatedAt: _gameSession!.updatedAt,
      );
      notifyListeners();
    }
  }

  // Get participant by ID
  Participant? getParticipant(String participantId) {
    return _gameSession?.getParticipantById(participantId);
  }

  // Get participant by user ID
  Participant? getParticipantByUserId(String userId) {
    return _gameSession?.getParticipantByUserId(userId);
  }

  // Check if current user is host
  bool isHost(String userId) {
    return _gameSession?.hostData?.id == userId;
  }

  // Get current question data
  QuizQuestion? getCurrentQuestionData() {
    if (_gameSession?.currentQuestion != null && _gameSession?.quizData != null) {
      final questionId = _gameSession!.currentQuestion!.questionId;
      try {
        return _gameSession!.quizData!.questions
            .firstWhere((q) => q.id == questionId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Get current question index (for UI display)
  int getCurrentQuestionIndex() {
    if (_gameSession?.currentQuestion != null && _gameSession?.quizData != null) {
      final questionId = _gameSession!.currentQuestion!.questionId;
      try {
        return _gameSession!.quizData!.questions
            .indexWhere((q) => q.id == questionId);
      } catch (e) {
        return -1;
      }
    }
    return -1;
  }
}
