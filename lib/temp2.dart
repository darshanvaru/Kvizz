// Updated parts of socket_service.dart
import '../providers/game_session_provider.dart';

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
