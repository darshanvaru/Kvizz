import 'package:flutter/material.dart';
import 'package:kvizz/models/Quiz.dart';
import 'package:kvizz/providers/dummy_data.dart';

import 'create_or_edit_quiz_screen.dart';
import 'ongoing_quiz_screen.dart';

class QuizDetailScreen extends StatelessWidget {
  final Quiz quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(quiz.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(quiz.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            _buildDetailRow("Type", quiz.type),
            _buildDetailRow("Time per Question", "${quiz.timePerQuestion} sec"),
            _buildDetailRow("Order", quiz.questionOrder),
            _buildDetailRow("Points per Question", quiz.pointsPerQuestion.toString()),
            _buildDetailRow("Difficulty", quiz.difficulty),
            _buildDetailRow("Times Played", quiz.timesPlayed.toString()),
            _buildDetailRow("Avg. Score", "${quiz.averageScore.toStringAsFixed(1)}%"),
            _buildDetailRow("Total Players", quiz.totalUserPlayed.toString()),
            _buildDetailRow("Participant Limit", quiz.participantLimit.toString()),
            _buildDetailRow("Status", quiz.isActive ? "Active" : "Inactive"),
            _buildDetailRow("Created At", quiz.createdAt.toLocal().toString().split(' ')[0]),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Handle Preview
                },
                child: const Text("Preview"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuizCreationOrEditScreen(questions: quiz.questions)),
                  );
                },
                child: const Text("Edit"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => OngoingQuizScreen(questions: quiz.questions)),
                  );
                },
                child: const Text("Play Quiz"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
