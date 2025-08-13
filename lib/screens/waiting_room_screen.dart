// screens/waiting_room_screen.dart - Updated to show participant join notifications
import 'package:flutter/material.dart';
import 'package:kvizz/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../models/UserModel.dart';
import '../providers/game_session_provider.dart';
import '../providers/tab_index_provider.dart';
import '../services/socket_service.dart';
import 'ongoing_quiz_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  @override
  _WaitingRoomScreenState createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _previousParticipantCount = 0;
  String _lastJoinedParticipant = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startGame() {
    final sessionProvider = Provider.of<GameSessionProvider>(context,listen: false);

    if (sessionProvider.hasSession) {
      _showStartGameDialog();
    }
  }

  void _showStartGameDialog() {
    final sessionProvider = Provider.of<GameSessionProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Quiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to start the quiz?'),
              SizedBox(height: 8),
              Text('• All ${sessionProvider.participantCount} participants will begin immediately'),
              Text('• Quiz: ${sessionProvider.quizData?.title ?? "Unknown"}'),
              Text('• Questions: ${sessionProvider.quizData?.questions.length ?? 0}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmStartGame();
              },
              child: Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmStartGame() {
    final sessionProvider = Provider.of<GameSessionProvider>(context,listen: false);

    if (sessionProvider.hasSession) {
      _socketService.startQuiz(gameSessionId: sessionProvider.gameSession!.id);

      // Show loading state
      sessionProvider.setLoading(true);
    }
  }

  void _leaveGame(BuildContext context) {
    print("Leave pressed");
    final sessionProvider = Provider.of<GameSessionProvider>(
      context,
      listen: false,
    );
    bool isHost = _isCurrentUserHost(sessionProvider);
    print("[from waiting_room_screen._leave Is host: $isHost");

    if (sessionProvider.hasSession) {
      final currentUser = _getCurrentUser();

      if (isHost) {
        _socketService.stopQuiz(sessionProvider.gameSession!.id);
      } else {
        _socketService.leaveQuiz(
          gameSessionId: sessionProvider.gameSession!.id,
          username: currentUser?.name,
        );
      }
      print(
        "[waiting_room_screen._leave] Leaving game session: ${sessionProvider.gameSession!.id}, ${currentUser?.id}, ${currentUser?.name}",
      );

      // sessionProvider.clearSession();
      Navigator.of(context).pop();
    }
  }

  UserModel? _getCurrentUser() {
    return Provider.of<UserProvider>(context, listen: false).currentUser;
  }

  bool _isCurrentUserHost(GameSessionProvider sessionProvider) {
    final currentUser = _getCurrentUser();
    if (currentUser == null || !sessionProvider.hasSession) return false;

    print(
      "[Checking host] Current User ID: ${currentUser.id}, Host ID: ${sessionProvider.hostData?.id}",
    );
    return sessionProvider.hostData?.id == currentUser.id;
  }

  void _showParticipantJoinedNotification(String username) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.person_add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('$username joined the game!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Lobby'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _leaveGame(context);
          },
        ),
        actions: [
          Consumer<GameSessionProvider>(
            builder: (context, sessionProvider, child) {
              return IconButton(
                icon: Icon(Icons.share),
                onPressed: sessionProvider.hasSession
                    ? () => _shareGameCode(sessionProvider.gameCode)
                    : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<GameSessionProvider>(
        builder: (context, sessionProvider, child) {
          final gameSession = sessionProvider.gameSession;

          debugPrint("[from waiting screen build] GamesSessionNull: ${gameSession == null}");
          debugPrint("[from waiting screen build] GameSession: ${gameSession?.toJson()}");

          // Check for participant count changes and show notification (Snackbar)
          if (sessionProvider.hasSession &&
              sessionProvider.participantCount > _previousParticipantCount) {
            // Find the new participant
            if (sessionProvider.participants.isNotEmpty) {
              final latestParticipant = sessionProvider.participants.last;
              if (latestParticipant.username != _lastJoinedParticipant) {
                _lastJoinedParticipant = latestParticipant.username;

                // Show notification after build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showParticipantJoinedNotification(
                    latestParticipant.username,
                  );
                });
              }
            }
          }
          _previousParticipantCount = sessionProvider.participantCount;

          // Handle different states
          if (sessionProvider.error != null) {
            return _buildErrorState(sessionProvider);
          }

          if (!sessionProvider.hasSession) {
            //loading screen
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Joining game...', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we connect you to the lobby',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Check if game has canceled/Finished and navigate to dashboard
          if (sessionProvider.isFinished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _leaveGame(context);
              Provider.of<SelectedIndexProvider>(context, listen: false).updateSelectedIndex(0);
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
            return _buildGameStartingState();
          }

          // Check if game has started and navigate to quiz
          if (sessionProvider.isStarted) {
            print("Game has started, navigating to OngoingQuizScreen from waiting screen");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OngoingQuizScreen(
                    questions: sessionProvider.quizData!.questions,
                    timePerQuestion: sessionProvider.gameSession!.settings!.timePerQuestion,
                    maxPointsPerQuestion: sessionProvider.gameSession?.settings?.maxPointsPerQuestion ?? 1,
                    isHost: _isCurrentUserHost(sessionProvider),
                    gameSessionId: sessionProvider.gameSession!.id,
                  ),
                ),
              );
            });
            return _buildGameStartingState();
          }

          // Show waiting room UI
          return _buildWaitingRoomContent(sessionProvider);
        },
      ),
    );
  }

  Widget _buildWaitingRoomContent(GameSessionProvider sessionProvider) {
    final isHost = _isCurrentUserHost(sessionProvider);

    return Column(
      children: [
        // Game info header with real-time updates
        _buildGameInfoHeader(sessionProvider),

        // Participants section
        Expanded(child: _buildParticipantsList(sessionProvider)),

        // Bottom controls
        _buildBottomControls(sessionProvider, isHost),
      ],
    );
  }

  Widget _buildGameInfoHeader(GameSessionProvider sessionProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Code',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    sessionProvider.gameCode,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sessionProvider.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Real-time participant counter
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '${sessionProvider.participantCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (sessionProvider.quizData != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionProvider.quizData!.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.quiz, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${sessionProvider.quizData!.questions.length} Questions',
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.category, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text(
                        sessionProvider.quizData!.category,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsList(GameSessionProvider sessionProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participants',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: sessionProvider.participantCount > 0
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${sessionProvider.participantCount}',
                  style: TextStyle(
                    color: sessionProvider.participantCount > 0
                        ? Colors.green.shade800
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Expanded(
            child: sessionProvider.participants.isEmpty
                ? _buildEmptyParticipantsState()
                : ListView.builder(
                    itemCount: sessionProvider.participants.length,
                    itemBuilder: (context, index) {
                      print("Index: $index");
                      print(
                        "participant name: ${sessionProvider.participants[index].username}",
                      );
                      if (index >= sessionProvider.participants.length) {
                        return SizedBox.shrink();
                      }

                      final participant = sessionProvider.participants[index];
                      final isHost =
                          sessionProvider.hostData?.id == participant.userId;

                      return GestureDetector(
                        onTap: () {
                          print(
                            "Tapped on participant: ${participant.username}",
                          );
                          if (isHost) {
                            _socketService.leaveQuiz(
                              gameSessionId: sessionProvider.gameSession!.id,
                              username:
                                  sessionProvider.participants[index].username,
                            );
                          }
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isHost
                                  ? Colors.amber.shade300
                                  : Colors.blue.shade300,
                              child: Text(
                                participant.username[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  participant.username,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (isHost) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'HOST',
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (participant.isGuest)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Guest',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                SizedBox(width: 8),
                                Icon(
                                  participant.isActive
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  color: participant.isActive
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyParticipantsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Waiting for participants...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Share the game code with others to join',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    GameSessionProvider sessionProvider,
    bool isHost,
  ) {
    print(
      "Participant Count: ${sessionProvider.participantCount} && IsLoading: ${sessionProvider.isLoading}",
    );
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHost) ...[
            // Host controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (sessionProvider.participantCount > 0)
                        ? _startGame
                        : null,
                    icon: sessionProvider.isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.play_arrow),
                    label: Text(
                      sessionProvider.isLoading ? 'Starting...' : 'Start Quiz',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: sessionProvider.isLoading
                      ? null
                      : () {
                          _leaveGame(context);
                        },
                  icon: Icon(Icons.close),
                  label: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (sessionProvider.participantCount == 0)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Need at least 1 participant to start',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ),
          ] else ...[
            // Participant controls
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Waiting for host to start the quiz...',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _leaveGame(context);
                  },
                  icon: Icon(Icons.exit_to_app),
                  label: Text('Leave'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(GameSessionProvider sessionProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.red.shade700),
            ),
            SizedBox(height: 8),
            Text(
              sessionProvider.error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // sessionProvider.clearSession();
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStartingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Quiz Starting!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('Get ready...'),
          SizedBox(height: 16),
          CircularProgressIndicator(color: Colors.green),
        ],
      ),
    );
  }

  void _shareGameCode(String gameCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Game Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code with others to join:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                gameCode,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
