import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'create_or_edit_quiz_screen.dart';
import 'quiz_detail_screen.dart';
import '../widgets/quiz_card.dart';

class MyQuizzesScreen extends StatelessWidget {
  const MyQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizzes = Provider.of<QuizProvider>(context).quizzes;

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
                    MaterialPageRoute(builder: (_) => CreateOrEditQuizScreen()),
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
            Expanded(
              child: quizzes.isEmpty
                  ? const Center(
                child: Text(
                  "No quizzes created yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemCount: quizzes.length,
                itemBuilder: (ctx, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizDetailScreen(quiz: quizzes[index]),
                        ),
                      );
                    },
                    child: QuizCard(quiz: quizzes[index]),
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
