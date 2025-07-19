import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _codeController = TextEditingController();

  // Dummy active quizzes (replace with real-time API data)
  final List<Map<String, String>> activeQuizzes = [
    {'title': 'Flutter Basics', 'host': 'Alice'},
    {'title': 'AI & ML Trivia', 'host': 'Bob'},
    {'title': 'DBMS Concepts', 'host': 'Charlie'},
  ];

  void joinLobby() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid code')),
      );
      return;
    }

    // TODO: Replace this with your real join logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining lobby with code: $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code input + Join button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4B39EF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Active Quizzes (Waiting to Start)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // List of active quizzes
          Expanded(
            child: ListView.builder(
              itemCount: activeQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = activeQuizzes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    title: Text(quiz['title'] ?? ''),
                    subtitle: Text("Hosted by: ${quiz['host']}"),
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: () {
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
