// socket_service.dart - Updated version
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_session_provider.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _isConnected = false;

  IO.Socket get socket => _socket;
  bool get isConnected => _isConnected;

  SocketService._internal();

  void connectSocket(BuildContext context) {
    if (_isConnected) return;

    _socket = IO.io(
      dotenv.env['Socket_URL']!,
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
    // Connection events
    _socket.onConnect((_) {
      _isConnected = true;
      print('✅ Socket connected: ${_socket.id}');
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      print('❌ Socket disconnected');
    });

    _socket.onConnectError((err) => print('Connection Error: $err'));
    _socket.onError((err) => print('Socket Error: $err'));

    // Game session events - ALL UPDATE THE SAME PROVIDER
    final gameEvents = [
      'game-created',
      'game-started',
      'participant-joined',
      'participant-left',
      'live-scores-updated',
      'final-leaderboard',
      'load-questions',
    ];

    for (var event in gameEvents) {
      _socket.on(event, (data) {
        print('📥 Received $event: $data');
        if (data is Map<String, dynamic>) {
          Provider.of<GameSessionProvider>(context, listen: false)
              .updateSessionFromJson(data);
        }
      });
    }

    // Error handling
    _socket.on('error', (data) {
      Provider.of<GameSessionProvider>(context, listen: false)
          .setError(data.toString());
      print("💥 Socket Error: ${data.toString()}");
    });
  }

  // Your existing socket methods remain the same
  void createRoom({required String quizId, required String hostId}) {
    _socket.emit('create-room', {'quizId': quizId, 'hostId': hostId});
  }

  void joinRoom({required String gameCode, String? userId, required String username}) {
    _socket.emit('join-room', {
      'gameCode': gameCode,
      'userId': userId,
      'username': username,
    });
  }

// ... rest of your socket methods stay the same
}
