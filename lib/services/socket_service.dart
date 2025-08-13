import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvizz/PrintHelper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_session_provider.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _isConnected = false;
  GameSessionProvider? _gameSessionProvider;
  bool _listenersRegistered = false;

  IO.Socket get socket => _socket;

  bool get isConnected => _isConnected && _socket.connected;

  SocketService._internal();

  void connectSocket(BuildContext context) {
    if (_isConnected && _socket.connected) {
      print('ℹ️ Socket already connected');
      return;
    }

    print('🔌 Connecting to socket... URL: ${dotenv.env['Socket_URL']}');
    _socket = IO.io(
      dotenv.env['Socket_URL'],
      IO.OptionBuilder()
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
      print('🎮 GAME CREATED from game-created listener');
      printFullResponse('🔍 Data received: $data');
      _handleSessionUpdate(data, 'Game room created successfully', context);
    });

    _socket.on('participant-joined', (data) {
      print('👥 PARTICIPANT JOINED');
      printFullResponse('🔍 Data received: $data');
      _handleSessionUpdate(data, 'New participant joined', context);
    });

    _socket.on('participant-left', (data) {
      print('👋 PARTICIPANT LEFT');
      _handleSessionUpdate(data, 'Participant left the game', context);
    });

    _socket.on('game-started', (data) {
      print('🚀 GAME STARTED');
      _handleSessionUpdate(data, 'Quiz has started', context);
    });

    _socket.on('live-scores-updated', (data) {
      print('📊 LIVE SCORES UPDATED');
      _handleSessionUpdate(data, 'Scores updated', context);
    });

    _socket.on('final-leaderboard', (data) {
      print('🏆 FINAL LEADERBOARD');
      _handleSessionUpdate(data, 'Quiz completed with final results', context);
    });

    _socket.on('load-questions', (data) {
      print('📝 QUESTIONS LOADED');
      _handleSessionUpdate(data, 'Quiz questions loaded', context);
    });

    // Error events
    _socket.on('error', (data) {
      print('💥 General error: $data');
      _updateProviderError(data.toString());
    });

    _listenersRegistered = true;
    print('✅ All socket listeners registered');
  }

  // FIXED: Complete implementation of _handleSessionUpdate
  void _handleSessionUpdate(dynamic data, String message, BuildContext context) {
    print('🔄 Processing session update: $message');
    print('🔍 Data type: ${data.runtimeType}');
    print('🔍 Data: $data');

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
      print('🔍 Session ID: ${sessionData['_id'] ?? sessionData['id']}');
      print('🔍 Game Code: ${sessionData['gameCode']}');
      print('🔍 Status: ${sessionData['status']}');
      print('🔍 Participants: ${(sessionData['participants'] as List?)?.length ?? 0}');



      // Ensure provider is available
      if (_gameSessionProvider == null) {
        _setupProviderReference(context);
      }

      // Update provider
      _gameSessionProvider!.updateSessionFromJson(sessionData);
      print('✅ $message');
      print('✅ Provider has session: ${_gameSessionProvider?.hasSession}');
    } catch (e, stackTrace) {
      print('❌ Failed to process session update: $e');
      print(
        '📍 Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}',
      );
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

  // SOCKET EMISSIONS
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
  }

  void getQuestions({required String gameSessionId}) {
    print('📤 Getting questions - Session: $gameSessionId');
    _socket.emit('get-questions', {'gameSessionId': gameSessionId});
  }

  void submitAnswer({
    required String gameSessionId,
    required String userId,
    required String questionId,
    required List<String> answer,
    required bool isCorrect,
    required int timeTaken,
  }) {
    print('📤 Submitting answer - Question: $questionId, Correct: $isCorrect');
    // _socket.emit('submit-answer', {
    //   'gameSessionId': gameSessionId,
    //   'username': userId,
    //   'questionId': questionId,
    //   'answer': answer,
    //   'isCorrect': isCorrect,
    //   'timeTaken': timeTaken,
    // });
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

  void refreshProviderReference(BuildContext context) {
    _setupProviderReference(context);
  }

  void emitEvent(String event, dynamic data) {
    print('📤 Custom emit - Event: $event, Data: $data');
    _socket.emit(event, data);
  }
}
