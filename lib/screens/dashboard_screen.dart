import 'package:flutter/material.dart';
import 'package:kvizz/services/quiz_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _codeController = TextEditingController();
  late Future<List<Map<String, dynamic>>?> _activeQuizzesFuture;

  @override
  void initState() {
    super.initState();
    _loadActiveQuizzes();
  }

  void _loadActiveQuizzes() {
    setState(() {
      _activeQuizzesFuture = getActiveQuizzes();
    });
  }

  void joinLobby() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid code')),
      );
      return;
    }

    print('Join logic for code: $code not implemented');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
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
                    controller: _codeController,
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
                  onPressed: joinLobby,
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
                          subtitle: Text(quiz['description']),
                          trailing: const Icon(Icons.play_circle_outline),
                          onTap: () {
                            print("Tapped on quiz with code: ${quiz['gameCode']}");
                            // TODO: Navigate or join quiz
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
