import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvizz/print_helper.dart';
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
      print('ℹ️ Socket already connected');
      return;
    }

    print('🔌 Connecting to socket... URL: ${dotenv.env['Socket_URL']}');
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
    try {
      _gameSessionProvider = Provider.of<GameSessionProvider>(
        context,
        listen: false,
      );
      print('✅ GameSessionProvider reference established');
    } catch (e) {
      print('❌ Failed to get GameSessionProvider: $e');
    }
  }

  void _registerListeners(BuildContext context) {
    if (_listenersRegistered) {
      print('ℹ️ Listeners already registered');
      return;
    }

    // Connection events
    _socket.onConnect((_) {
      _isConnected = true;
      print('✅ Socket connected successfully: ${_socket.id}');
    });

    _socket.onDisconnect((reason) {
      _isConnected = false;
      print('🔌 Socket disconnected. Reason: $reason');
      _cleanupOnDisconnect();
    });

    _socket.onConnectError((error) {
      print('❌ Connection error: $error');
      _updateProviderError('Connection failed: $error');
    });

    _socket.onError((error) {
      print('❌ Socket error: $error');
      _updateProviderError('Socket error: $error');
    });

    // GAME SESSION EVENTS
    _socket.on('game-created', (data) {
      print('🎮 GAME CREATED from game-created socket listener');
      _handleSessionUpdate(data, 'Game room created successfully', context, "game-created");
    });

    _socket.on('participant-joined', (data) {
      print('👥 PARTICIPANT JOINED');
      _handleSessionUpdate(data, 'New participant joined', context, "participant-joined");
    });

    _socket.on('participant-left', (data) {
      print('👋 PARTICIPANT LEFT');
      _handleSessionUpdate(data, 'Participant left the game', context, "participant-left");
    });

    _socket.on('game-started', (data) {
      print('🚀 GAME STARTED');
      _handleSessionUpdate(data, 'Quiz has started', context, "game-started");
    });

    _socket.on('live-scores-updated', (data) {
      print('📊 LIVE SCORES UPDATED');
      _handleSessionUpdate(data, 'Scores updated', context, "live-scores-updated");
    });

    _socket.on('final-leaderboard', (data) {
      print('🏆 FINAL LEADERBOARD');
      _handleSessionUpdate(data, 'Quiz completed with final results', context, "final-leaderboard");
    });

    _socket.on('load-questions', (data) {
      print('📝 QUESTIONS LOADED');
      _handleSessionUpdate(data, 'Quiz questions loaded', context, "load-questions");
    });

    // Error events
    _socket.on('error', (data) {
      print('💥 General error: $data');
      _updateProviderError(data.toString());
    });

    _listenersRegistered = true;
    print('✅ All socket listeners registered');
  }

  // SOCKET that are emitted by client
  void createRoom({required String quizId, required String hostId}) {
    print('📤 Creating room - Quiz: $quizId, Host: $hostId');

    // Ensure socket is connected before emitting
    if (!isConnected) {
      print('❌ Socket not connected, cannot create room');
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
    print('📤 Joining room - Code: $gameCode, User: $username');
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
    print('📤 Leaving quiz - Session: $gameSessionId');
    _socket.emit('leave-quiz', {
      'gameSessionId': gameSessionId,
      'username': username,
    });
  }

  void startQuiz({required String gameSessionId}) {
    print('📤 Starting quiz - Session: $gameSessionId');
    _socket.emit('start-quiz', {'gameSessionId': gameSessionId});
  }

  void stopQuiz(String gameSessionId) {
    print('📤 Stopping quiz - Session: $gameSessionId');
    _socket.emit('stop-quiz', {'gameSessionId': gameSessionId});
    print("Stop Emitted");
  }

  void getQuestions({required String gameSessionId}) {
    print('📤 Getting questions - Session: $gameSessionId');
    _socket.emit('get-questions', {'gameSessionId': gameSessionId});
  }

  // Helper methods
  void _handleSessionUpdate(dynamic data, String message, BuildContext context, String from) {
    print('🔄 Processing session update: $message');
    printFullResponse('🔍 Data Received from socket: $data');

    if (data == null) {
      print('❌ Received null session data');
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

      print('✅ Session data validated');
      printFullResponse("✅ Full Session data: $sessionData");
      print("Updating GameSessionProvider with received socket data, is _gameSessionProvider null: ${_gameSessionProvider == null}");

      // Update provider
      _gameSessionProvider!.updateSessionFromJson(sessionData, from);
      print('✅ Provider Updated, is _gameSessionProvider null: ${_gameSessionProvider == null}');
    } catch (e, stackTrace) {
      print('❌ Failed to process session update: $e');
      print('📍 Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}',);
      _updateProviderError('Failed to update session: $e');
    }
  }

  void _updateProviderError(String error) {
    print("❌ Updating provider with error: $error");
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
    print('📤 Submitting answer - Question: $questionId, Correct: $isCorrect');
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
      print('🔌 Manually disconnecting socket...');
      _cleanupOnDisconnect();
      _socket.disconnect();
      _isConnected = false;
      print('✅ Socket disconnected manually');
    } else {
      print('ℹ️ Socket already disconnected');
    }
  }

  void dispose() {
    print('🗑️ Disposing SocketService...');
    manualDisconnect();

    if (_socket.connected) {
      _socket.clearListeners();
      _socket.dispose();
    }

    _gameSessionProvider = null;
    _listenersRegistered = false;
    _isConnected = false;
    print('✅ SocketService disposed completely');
  }

  void emitEvent(String event, dynamic data) {
    print('📤 Custom emit - Event: $event, Data: $data');
    _socket.emit(event, data);
  }
}
