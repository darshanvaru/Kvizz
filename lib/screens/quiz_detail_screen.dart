import 'package:flutter/material.dart';
import 'package:kvizz/models/Quiz.dart';
import 'package:kvizz/providers/quiz_provider.dart';
import 'package:kvizz/screens/create_or_edit_quiz_screen.dart';
import 'package:kvizz/screens/ongoing_quiz_screen.dart';
import 'package:provider/provider.dart';

class QuizDetailScreen extends StatelessWidget {
  final QuizModel quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  void _confirmAndDeleteQuiz(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<QuizProvider>(context, listen: false)
                  .deleteQuizById(quiz.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Exit detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Quiz deleted successfully!")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Quiz',
            onPressed: () => _confirmAndDeleteQuiz(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 20),
          _buildStatsGrid(context),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Preview logic
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("Preview"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateOrEditQuizScreen(editingQuiz: quiz),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            OngoingQuizScreen(questions: quiz.questions),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(quiz.description,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(label: Text(quiz.difficulty)),
                const SizedBox(width: 10),
                Chip(label: Text(quiz.isActive ? 'Active' : 'Inactive')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = <Map<String, String>>[
      {'Type': quiz.type},
      {'Time per Question': '${quiz.timePerQuestion} sec'},
      {'Order': quiz.questionOrder},
      {'Points per Question': quiz.pointsPerQuestion.toString()},
      {'Times Played': quiz.timesPlayed.toString()},
      {'Avg. Score': '${quiz.averageScore.toStringAsFixed(1)}%'},
      {'Total Players': quiz.totalUserPlayed.toString()},
      {'Participant Limit': quiz.participantLimit.toString()},
      {'Created At': quiz.createdAt.toLocal().toString().split(' ')[0]},
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final entry = stats[index].entries.first;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF8F9FA)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key),
                const SizedBox(height: 4),
                Text(entry.value),
              ],
            ),
          ),
        );
      },
    );
  }
}
