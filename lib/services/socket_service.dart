import 'dart:developer';
import 'package:kvizz/services/quiz_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Quiz.dart';
import '../models/game_session_model.dart';
import '../providers/game_session_provider.dart';
import '../providers/quiz_provider.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _isConnected = false;

  IO.Socket get socket => _socket;

  SocketService._internal();

  void connectSocket(BuildContext context) {
    if (_isConnected) return;

    _socket = IO.io(
      "http://10.20.51.115:8000",
      IO.OptionBuilder()
          .disableAutoConnect()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _registerListeners(context);

    _socket.connect();
  }

  void _registerListeners(BuildContext context) {
    // Lifecycle events
    socket.onConnect(
          (context) => print('Flutter client connected with ID: ${_socket.id}'),
    );
    socket.onDisconnect((context) => print('Flutter client disconnected'));
    _socket.onConnectError((err) => print('Connection Error: $err'));
    _socket.onError((err) => print('Socket Error: $err'));

    // Game Session updates - Updated to use GameSessionProvider
    final gameUpdateEvents = [
      'game-created',
      'game-started',
      'participant-joined',
      'participant-left',
      'live-scores-updated',
      'final-leaderboard',
    ];

    for (var event in gameUpdateEvents) {
      _socket.on(event, (data) {
        if (data is Map<String, dynamic>) {
          Provider.of<GameSessionProvider>(
            context,
            listen: false,
          ).updateSessionFromJson(data);
          print('📥 Session updated from $event');
        }
      });
    }

    // Quiz data
    _socket.on('load-questions', (data) {
      if (data is Map) {
        final quiz = QuizModel.fromJson(data);
        Provider.of<QuizProvider>(context, listen: false).updateQuiz(quiz);
        log('🔁 quiz-updated: ${quiz.title}');
      }
    });

    // Error handling
    _socket.on('error', (data) {
      Provider.of<GameSessionProvider>(
        context,
        listen: false,
      ).setError(data.toString());
      print("💥💥💥--------------------${data.toString()}");
    });
  }

  void createRoom({required String quizId, required String hostId}) {
    _socket.emit('create-room', {'quizId': quizId, 'hostId': hostId});
  }

  void joinRoom({required String gameCode, String? userId, required String username}) {
    _socket?.emit('join-room', {
      'gameCode': gameCode,
      'userId': userId,
      'username': username,
    });
  }

  void leaveQuiz({required String gameSessionId, String? userId, String? username}) {
    _socket?.emit('leave-quiz', {
      'gameSessionId': gameSessionId,
      'userId': userId,
      'username': username
    });
  }

  void startQuiz({required String gameSessionId}) {
    _socket?.emit('start-quiz', {'gameSessionId': gameSessionId});
  }

  void stopQuiz({required String gameSessionId}) {
    _socket?.emit('stop-quiz', {'gameSessionId': gameSessionId});
  }

  void getQuestions({required String gameSessionId}) {
    _socket?.emit('get-questions', {'gameSessionId': gameSessionId});
  }

  void submitAnswer({
    required String gameSessionId,
    required String userId,
    required String questionId,
    required dynamic answer, // Can be index, string, etc.
    required bool isCorrect,
    required int timeTaken, // e.g., in milliseconds
  }) {
    _socket?.emit('submit-answer', {
      'gameSessionId': gameSessionId,
      'userId': userId,
      'questionId': questionId,
      'answer': answer,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
    });
  }

  // Clean up resources
  void dispose() {
    // _gameSessionController.close();
    // _quizController.close();
    // _errorController.close();
    _socket.dispose();
    // _socket = null;
  }

  void disconnectSocket() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      log('🔌 Socket manually disconnected');
    }
  }

  // Emit Event
  void emitEvent(String event, dynamic data) {
    log("📤 Emitting $event => $data");
    _socket.emit(event, data);
  }

  // Listen to Event
  void onEvent(String event, BuildContext context) {
    _socket.on(event, (data) {
      log("📥 Event received: $event => $data");

      final session = GameSessionModel.fromJson(data);
      Provider.of<GameSessionProvider>(
        context,
        listen: false,
      ).updateSession(session);
    });
  }
}
