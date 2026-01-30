import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_model.dart';
import 'package:kvizz/services/quiz_service.dart';
import '../providers/user_provider.dart';
import '../widgets/loading_widget.dart';
import 'create_or_edit_quiz_screen.dart';
import 'quiz_detail_screen.dart';
import '../widgets/quiz_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MyQuizzesScreen extends StatefulWidget {
  const MyQuizzesScreen({super.key});

  @override
  State<MyQuizzesScreen> createState() => _MyQuizzesScreenState();
}

class _MyQuizzesScreenState extends State<MyQuizzesScreen> {
  late Future<List<QuizModel>?> _loadQuizzesFuture;

  @override
  void initState() {
    super.initState();
    _loadUserQuizzes();
  }

  void _loadUserQuizzes() {
    print("Calling current user from MyQuizzesScreen");
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    print("Got Current User id as ${user?.username}");

    setState(() {
      _loadQuizzesFuture = fetchUserQuizzes(user!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Error! Login Again to view your quizzes.")),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateOrEditQuizScreen()),
                  );
                  // Refresh the quiz list if a new quiz was created
                  if (result == true) {
                    setState(() {
                      _loadUserQuizzes();
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Add New Quiz"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<QuizModel>?>(
                future: _loadQuizzesFuture,
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: LoadingWidget(),);
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Error loading quizzes: ${snapshot.error}"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loadUserQuizzes();
                              });
                            },
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  }

                  final quizzes = snapshot.data ?? [];

                  if (quizzes.isEmpty) {
                    return const Center(
                      child: Text(
                        "No quizzes created yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _loadUserQuizzes();
                      });
                    },
                    child: MasonryGridView.builder(
                      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      itemCount: quizzes.length,
                      itemBuilder: (ctx, index) {
                        return InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    QuizDetailScreen(quizId: quizzes[index].id),
                              ),
                            ).then((onValue) async {
                              _loadUserQuizzes();
                            });
                          },
                          child: QuizCard(quiz: quizzes[index]),
                        );
                      },
                    ),
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
