import 'package:flutter/material.dart';
import 'package:kvizz/screens/quiz_detail_screen.dart';
import 'package:kvizz/widgets/quiz_card.dart';
import '../providers/dummy_data.dart';
import 'create_or_edit_quiz_screen.dart';

class MyQuizzesScreen extends StatelessWidget {
  const MyQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuizCreationOrEditScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Add New Quiz"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Expanded makes the GridView take remaining space
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemCount: dummyQuizzes.length,
                itemBuilder: (ctx, index) {
                  final quiz = dummyQuizzes[index];
                  return InkWell(
                    onTap: () {
                      print("On Tap for quiz: ${quiz.title}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: quiz)),
                      );
                    },
                    child: QuizCard(quiz: quiz),
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
