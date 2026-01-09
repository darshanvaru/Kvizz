import 'package:flutter/material.dart';
import 'package:kvizz/screens/waiting_room_screen.dart';
import 'package:kvizz/services/quiz_service.dart';

import 'package:kvizz/services/socket_service.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _gameCodeController = TextEditingController();
  late Future<List<Map<String, dynamic>>?> _activeQuizzesFuture;

  @override
  void initState() {
    super.initState();
    _socketService.connectSocket(context);
    _loadActiveQuizzes();
  }

  void _loadActiveQuizzes() {
    setState(() {
      _activeQuizzesFuture = getActiveQuizzes();
    });
  }

  void _joinGame(String gameCode) {
    if (gameCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a game code')),
      );
      return;
    }
    // Validate game code format (6-digit number)
    if (!RegExp(r'^\d+$').hasMatch(gameCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid game code. Must be a 6-digit number and only numeric')),
      );
      return;
    }

    // Get current user info (from your existing user system)
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;

    // Join the room via socket
    _socketService.joinRoom(
      gameCode: int.tryParse(gameCode) ?? 000000,
      userId: currentUser?.id,
      username: currentUser?.username ?? 'Guest User',
    );

    // Navigate to waiting room
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingRoomScreen(),
      ),
    ).then((_) => _loadActiveQuizzes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Lobby"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadActiveQuizzes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Join Code Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gameCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter lobby code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: (){_joinGame(_gameCodeController.text.trim());},
                  child: const Text('Join'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Active Quizzes (Waiting to Start)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Active Quizzes List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>?>(
                future: _activeQuizzesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading quizzes."));
                  }

                  final quizzes = snapshot.data;

                  if (quizzes == null || quizzes.isEmpty) {
                    return const Center(child: Text("No active quizzes available."));
                  }

                  return ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(quiz['title']),
                          subtitle: Text("${quiz['gameCode']} - ${quiz['description']}"),
                          trailing: const Icon(Icons.play_circle_outline),
                          onTap: () {
                            print("Tapped on quiz with code: ${quiz['gameCode']}");
                            _joinGame(quiz['gameCode'].toString());
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
