import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_session_model.dart';
import '../providers/game_session_provider.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _isConnected = false;

  IO.Socket get socket => _socket;

  SocketService._internal();

  void connectSocket({required String baseUrl}) {
    if (_isConnected) return;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      _isConnected = true;
      log('🔌 Socket connected');
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      log('❌ Socket disconnected');
    });

    _socket.onConnectError((err) {
      log("❗ Connect Error: $err");
    });

    _socket.onError((err) {
      log("❗ Socket Error: $err");
    });
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
      Provider.of<GameSessionProvider>(context, listen: false)
          .updateSession(session);
    });
  }

  // Use to listen once (e.g. game-created confirmation)
  void onEventOnce(String event, BuildContext context) {
    _socket.once(event, (data) {
      log("📥 Event once: $event => $data");

      final session = GameSessionModel.fromJson(data);
      Provider.of<GameSessionProvider>(context, listen: false)
          .updateSession(session);
    });
  }
}
