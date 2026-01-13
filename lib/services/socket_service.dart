import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_session_provider.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket _socket;
  bool _isConnected = false;

  // if null error persist, Setting GameSessionProvider as late and replacing all null  with empty GameSessionProvider
  GameSessionProvider? _gameSessionProvider;
  bool _listenersRegistered = false;

  //getters
  io.Socket get socket => _socket;
  bool get isConnected => _isConnected && _socket.connected;
  SocketService._internal();

  void connectSocket(BuildContext context) {
    if (_isConnected && _socket.connected) {
      return;
    }

    _socket = io.io(
      dotenv.env['Socket_URL'],
      io.OptionBuilder()
          .disableAutoConnect()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
    _setupProviderReference(context);
    _registerListeners(context);
    _socket.connect();
  }

  void _setupProviderReference(BuildContext context) {
    _gameSessionProvider = Provider.of<GameSessionProvider>(
      context,
      listen: false,
    );
  }

  void _registerListeners(BuildContext context) {
    if (_listenersRegistered) {
      return;
    }

    // Connection events
    _socket.onConnect((_) {
      _isConnected = true;
    });

    _socket.onDisconnect((reason) {
      _isConnected = false;
      _cleanupOnDisconnect();
    });

    _socket.onConnectError((error) {
      _updateProviderError('Connection failed: $error');
    });

    _socket.onError((error) {
      _updateProviderError('Socket error: $error');
    });

    // GAME SESSION EVENTS
    _socket.on('game-created', (data) {
      _handleSessionUpdate(data, 'Game room created successfully', context, "game-created");
    });

    _socket.on('participant-joined', (data) {
      _handleSessionUpdate(data, 'New participant joined', context, "participant-joined");
    });

    _socket.on('participant-left', (data) {
      _handleSessionUpdate(data, 'Participant left the game', context, "participant-left");
    });

    _socket.on('game-started', (data) {
      _handleSessionUpdate(data, 'Quiz has started', context, "game-started");
    });

    _socket.on('live-scores-updated', (data) {
      _handleSessionUpdate(data, 'Scores updated', context, "live-scores-updated");
    });

    _socket.on('final-leaderboard', (data) {
      _handleSessionUpdate(data, 'Quiz completed with final results', context, "final-leaderboard");
    });

    _socket.on('load-questions', (data) {
      _handleSessionUpdate(data, 'Quiz questions loaded', context, "load-questions");
    });

    // Error events
    _socket.on('error', (data) {
      _updateProviderError(data.toString());
    });

    _listenersRegistered = true;
  }

  // SOCKET that are emitted by client
  void createRoom({required String quizId, required String hostId}) {

    // Ensure socket is connected before emitting
    if (!isConnected) {
      _updateProviderError('Socket not connected. Please try again.');
      return;
    }

    _socket.emit('create-room', {'quizId': quizId, 'hostId': hostId});
  }

  void joinRoom({
    required int gameCode,
    String? userId,
    required String username,
  }) {
    _socket.emit('join-room', {
      'gameCode': gameCode,
      'userId': userId,
      'username': username,
    });
  }

  void leaveQuiz({
    required String gameSessionId,
    String? username,
  }) {
    _socket.emit('leave-quiz', {
      'gameSessionId': gameSessionId,
      'username': username,
    });
  }

  void startQuiz({required String gameSessionId}) {
    _socket.emit('start-quiz', {'gameSessionId': gameSessionId});
  }

  void stopQuiz(String gameSessionId) {
    _socket.emit('stop-quiz', {'gameSessionId': gameSessionId});
  }

  void getQuestions({required String gameSessionId}) {
    _socket.emit('get-questions', {'gameSessionId': gameSessionId});
  }

  // Helper methods
  void _handleSessionUpdate(dynamic data, String message, BuildContext context, String from) {

    if (data == null) {
      _updateProviderError('Received empty data from server');
      return;
    }

    try {
      // Convert to proper Map format
      Map<String, dynamic> sessionData;
      if (data is Map<String, dynamic>) {
        sessionData = data;
      } else if (data is Map) {
        sessionData = Map<String, dynamic>.from(data);
      } else {
        throw Exception('Invalid data format: ${data.runtimeType}');
      }

      // Update provider
      _gameSessionProvider!.updateSessionFromJson(sessionData, from);
    } catch (e) {
      _updateProviderError('Failed to update session: $e');
    }
  }

  void _updateProviderError(String error) {
    _gameSessionProvider?.setError(error);
  }

  void _cleanupOnDisconnect() {
    _gameSessionProvider = null;
    _listenersRegistered = false;
  }

  void submitAnswer({
    required String gameSessionId,
    required String username,
    required String questionId,
    required List<String> answer,
    required bool isCorrect,
    required int timeTaken,
  }) {
    _socket.emit('submit-answer', {
      'gameSessionId': gameSessionId,
      'username': username,
      'questionId': questionId,
      'answers': answer,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
    });
  }

  void manualDisconnect() {
    if (isConnected) {
      _cleanupOnDisconnect();
      _socket.disconnect();
      _isConnected = false;
    }
  }

  void dispose() {
    manualDisconnect();

    if (_socket.connected) {
      _socket.clearListeners();
      _socket.dispose();
    }

    _gameSessionProvider = null;
    _listenersRegistered = false;
    _isConnected = false;
  }

  void emitEvent(String event, dynamic data) {
    _socket.emit(event, data);
  }
}
