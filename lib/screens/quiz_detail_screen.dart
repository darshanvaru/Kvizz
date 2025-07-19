import 'package:flutter/material.dart';
import 'package:kvizz/models/Quiz.dart';
import 'package:kvizz/screens/create_or_edit_quiz_screen.dart';
import 'package:kvizz/screens/ongoing_quiz_screen.dart';

class QuizDetailScreen extends StatelessWidget {
  final QuizModel quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        // backgroundColor: Colors.deepPurple,
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
                  // style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateOrEditQuizScreen(questions: quiz.questions),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  // style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OngoingQuizScreen(questions: quiz.questions),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play"),
                  // style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
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
      // color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(quiz.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(
                  label: Text(quiz.difficulty),
                  // backgroundColor: Colors.deepPurple.shade100,
                ),
                const SizedBox(width: 10),
                Chip(
                  label: Text(quiz.isActive ? 'Active' : 'Inactive'),
                  // backgroundColor: quiz.isActive ? Colors.green.shade100 : Colors.red.shade100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    // final labelStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[800]);
    // final valueStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87);

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
                color: Colors.grey.withValues(alpha: .15),
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
                Text(entry.value,),
              ],
            ),
          ),
        );
      },
    );
  }
}
