import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../models/Quiz.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _codeController = TextEditingController();

  void joinLobby() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid code')),
      );
      return;
    }

    // TODO: Add actual lobby join logic here
    print('Join logic for code: $code not implemented');
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final List<QuizModel> activeQuizzes =
    quizProvider.quizzes.where((q) => q.isActive).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Lobby code + Join button
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

          /// Active quizzes list
          Expanded(
            child: activeQuizzes.isEmpty
                ? const Center(child: Text("No active quizzes available."))
                : ListView.builder(
              itemCount: activeQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = activeQuizzes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    title: Text(quiz.title),
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: () {
                      // TODO: Handle quiz join/view
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
