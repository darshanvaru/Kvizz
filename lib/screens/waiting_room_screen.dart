import 'package:flutter/material.dart';
import 'package:kvizz/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../providers/game_session_provider.dart';
import '../providers/tab_index_provider.dart';
import '../services/socket_service.dart';
import 'ongoing_quiz_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});
  @override
  WaitingRoomScreenState createState() => WaitingRoomScreenState();
}

class WaitingRoomScreenState extends State<WaitingRoomScreen> with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();

  int _previousParticipantCount = 0;
  String _lastJoinedParticipant = '';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Confirm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Do you really want to stop and exit the game?'),
                  SizedBox(height: 16),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _leaveGame(context);
                  },
                  child: Text('Yes'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('No'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Game Lobby'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Do you really want to stop the game?'),
                      SizedBox(height: 16),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _leaveGame(context);
                      },
                      child: Text('Yes'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('No'),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Consumer<GameSessionProvider>(
              builder: (context, sessionProvider, child) {
                return IconButton(
                  icon: Icon(Icons.share),
                  onPressed: sessionProvider.hasSession ? () => _shareGameCode(sessionProvider.gameCode) : null,
                );
              },
            ),
          ],
        ),
        body: FutureBuilder(
          future: Future.delayed(const Duration(seconds: 2)),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
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
            // Show main waiting room UI with participant-change handling
            return Consumer<GameSessionProvider>(
              builder: (context, sessionProvider, child) {

                // Participant join notification
                if (sessionProvider.hasSession &&
                    sessionProvider.participantCount > _previousParticipantCount
                ) {
                  // Find the new participant
                  if (sessionProvider.participants.isNotEmpty) {
                    final latestParticipant = sessionProvider.participants.last;
                    if (latestParticipant.username != _lastJoinedParticipant) {
                      _lastJoinedParticipant = latestParticipant.username;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showParticipantJoinedNotification(latestParticipant.username);
                      });
                    }
                  }
                }

                // Update previous states AFTER all checks
                _previousParticipantCount = sessionProvider.participantCount;

                if (sessionProvider.error != null) {
                  return _buildErrorState(sessionProvider);
                }

                if (!sessionProvider.hasSession || sessionProvider.gameSession?.status == 'previousFinished') {
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

                if (sessionProvider.isFinished) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _leaveGame(context);
                    Provider.of<TabIndexProvider>(context, listen: false).resetIndex;
                    // Navigator.popUntil(
                    //   context,
                    //       (route) => route.settings.name == 'HomePage',
                    // );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  });
                  return _buildGameStartingState();
                }

                if (sessionProvider.isStarted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OngoingQuizScreen(
                          questions: sessionProvider.quizData!.questions,
                          timePerQuestion: 10, // sessionProvider.gameSession?.settings?.timePerQuestion ?? 10,
                          maxPointsPerQuestion: sessionProvider.gameSession?.settings?.maxPointsPerQuestion ?? 1,
                          isHost: _isCurrentUserHost(sessionProvider),
                          gameSessionId: sessionProvider.gameSession!.id,
                        ),
                      ),
                    );
                  });
                  return _buildGameStartingState();
                }

                return _buildWaitingRoomContent(sessionProvider);
              },
            );
          },
        ),
      ),
    );
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: sessionProvider.participantCount > 0 ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${sessionProvider.participantCount}',
                  style: TextStyle(
                    color: sessionProvider.participantCount > 0 ? Colors.green.shade800 : Colors.grey.shade600,
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
                final participant = sessionProvider.participants[index];
                return GestureDetector(
                  onTap: () {
                    if (_isCurrentUserHost(sessionProvider)) {
                      _socketService.leaveQuiz(
                        gameSessionId: sessionProvider.gameSession!.id,
                        username: sessionProvider.participants[index].username,
                      );
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade300,
                        child: Text(
                          participant.username[0].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            participant.username,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (participant.isGuest)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Guest',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ),
                          SizedBox(width: 8),
                          Icon(
                            participant.isActive ? Icons.circle : Icons.circle_outlined,
                            color: participant.isActive ? Colors.green : Colors.grey,
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
          Text('Waiting for participants...', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          SizedBox(height: 8),
          Text('Share the game code with others to join', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildWaitingRoomContent(GameSessionProvider sessionProvider) {
    final isHost = _isCurrentUserHost(sessionProvider);
    return Column(
      children: [
        _buildGameInfoHeader(sessionProvider),
        Expanded(child: _buildParticipantsList(sessionProvider)),
        _buildBottomControls(sessionProvider, isHost),
      ],
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red.shade700),
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
          Text('Quiz Starting!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              )),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.black),
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

  void _startGame() {
    final sessionProvider = Provider.of<GameSessionProvider>(context, listen: false);
    if (sessionProvider.hasSession) {
      _showStartGameDialog();
    }
  }

  void _showStartGameDialog() {
    final sessionProvider = Provider.of<GameSessionProvider>(context, listen: false);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Start Quiz'),
            ),
          ],
        );
      },
    );
  }

  void _confirmStartGame() {
    final sessionProvider = Provider.of<GameSessionProvider>(context, listen: false);
    if (sessionProvider.hasSession) {
      _socketService.startQuiz(gameSessionId: sessionProvider.gameSession!.id);
    }
  }

  void _leaveGame(BuildContext context) {
    final sessionProvider = Provider.of<GameSessionProvider>(context, listen: false);
    if (sessionProvider.hasSession) {
      final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
      if (_isCurrentUserHost(sessionProvider)) {
        _socketService.stopQuiz(sessionProvider.gameSession!.id);
      } else {
        _socketService.leaveQuiz(
          gameSessionId: sessionProvider.gameSession!.id,
          username: currentUser?.username,
        );
      }
      Navigator.of(context).pop();
    } else {
      Provider.of<TabIndexProvider>(context, listen: false).resetIndex;
      // Navigator.popUntil(
      //   context,
      //       (route) => route.settings.name == 'HomePage',
      // );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  bool _isCurrentUserHost(GameSessionProvider sessionProvider) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (currentUser == null || !sessionProvider.hasSession) return false;
    return sessionProvider.hostData?.id == currentUser.id;
  }

  Widget _buildBottomControls(GameSessionProvider sessionProvider, bool isHost) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest, // replacing Colors.grey.shade50
        border: Border(
          top: BorderSide(color: colorScheme.outline), // replacing Colors.grey.shade300
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHost) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (sessionProvider.participantCount > 1) ? _startGame : null,
                    icon: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
                    label: Text('Start Quiz', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary, // replacing Colors.green
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    _leaveGame(context);
                  },
                  icon: Icon(Icons.close, color: colorScheme.error),
                  label: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error, // replacing Colors.red
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            if (sessionProvider.participantCount < 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Need at least 1 participant to start',
                  style: textTheme.bodySmall?.copyWith(color: Colors.red), // replacing Colors.orange.shade700
                ),
              ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Waiting for host to start the quiz...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ), // replacing Colors.grey.shade700
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _leaveGame(context);
                  },
                  icon: Icon(Icons.exit_to_app, color: colorScheme.error),
                  label: Text('Leave', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error, // replacing Colors.red
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
