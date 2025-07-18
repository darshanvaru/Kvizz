import 'package:flutter/material.dart';
import '../providers/dummy_data.dart';
import 'create_quiz_screen.dart';

class MyQuizzesScreen extends StatelessWidget {
  const MyQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Quizzes"),
      ),
      body: ListView.builder(
        itemCount: dummyQuizzes.length,
        itemBuilder: (ctx, index) {
          final quiz = dummyQuizzes[index];
          return InkWell(
            onTap: () {
              print("On Tap for quiz: ${quiz.title}");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizCreationScreen(questions: quiz.questions)),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  quiz.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(quiz.description),
                    const SizedBox(height: 6),
                    Text("Difficulty: ${quiz.difficulty}"),
                    Text("Type: ${quiz.type}"),
                    Text("Questions: ${quiz.timePerQuestion}s each"),
                    Text("Points: ${quiz.pointsPerQuestion}"),
                    Text("Plays: ${quiz.timesPlayed}"),
                  ],
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuizCreationScreen()),
          );
        },
        label: const Text("Add New Quiz"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
