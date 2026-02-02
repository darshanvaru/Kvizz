import 'package:flutter/material.dart';
import 'package:kvizz/models/quiz_model.dart';
import 'package:kvizz/screens/create_or_edit_quiz_screen.dart';
import 'package:kvizz/screens/quiz_preview_screen.dart';
import 'package:kvizz/screens/waiting_room_screen.dart';
import 'package:kvizz/services/quiz_service.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/socket_service.dart';
import '../widgets/loading_widget.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  const QuizDetailScreen({super.key, required this.quizId});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  QuizModel? quiz;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuizDetails();
  }

  Future<void> _fetchQuizDetails() async {

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedQuiz = await fetchQuizById(widget.quizId);

      if (mounted) {
        setState(() {
          quiz = fetchedQuiz;
          isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _fetchQuizDetails();
  }

  void _hostMultiplayerGame(QuizModel quiz) {

    // Connect socket
    final socketService = SocketService();

    // Create room
    final currentUser = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUser!; // Your existing method
    socketService.createRoom(quizId: quiz.id, hostId: currentUser.id);

    // Navigate to host lobby
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WaitingRoomScreen()),
    );
  }

  void _confirmAndDeleteQuiz() {
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
            onPressed: () async {
              final success = await deleteQuiz(widget.quizId);
              if (success) {
                if(mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Quiz deleted successfully!")),
                  );
                }
              }
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Details')),
        body: LoadingWidget(),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading quiz',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchQuizDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Details')),
        body: const Center(child: Text('Quiz not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Quiz',
            onPressed: _confirmAndDeleteQuiz,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildQuizInfoCard(),
            const SizedBox(height: 20),
            _buildQuestionsCard(),
            const SizedBox(height: 20),
            _buildTagsCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              //Preview Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PreviewQuizScreen(questions: quiz?.questions?? []),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("Preview"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              //Edit Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateOrEditQuizScreen(quizId: quiz!.id),
                          ),
                        )
                        .then((value) {
                          _fetchQuizDetails();
                        })
                        .catchError((error) {
                        });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              //Play Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async{
                    // await Future.delayed(Duration(seconds: 2));
                    _hostMultiplayerGame(quiz!);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz!.title
                        .split(' ')
                        .map(
                          (word) => word.isEmpty
                              ? ''
                              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
                        )
                        .join(' '),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(quiz!.difficulty),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quiz!.difficulty.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "${quiz!.description[0].toUpperCase()}${quiz!.description.substring(1)}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Created by: ${quiz!.creator}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.label,
              'Type',
              (quiz?.type?.toLowerCase() ?? 'manual') == 'manual'
                  ? 'Manually Generated'
                  : 'AI Generated',
            ),
            _buildInfoRow(
              Icons.help_outline,
              'Total Questions',
              '${quiz!.questions.length}',
            ),
            _buildInfoRow(
              Icons.speed,
              'Difficulty',
              quiz!.difficulty[0].toUpperCase() + quiz!.difficulty.substring(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          'Questions (${quiz!.questions.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        leading: const Icon(Icons.quiz, color: Colors.blue),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: quiz!.questions.length,
              itemBuilder: (context, index) {
                final question = quiz!.questions[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  title: Text(
                    question.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Type: ${question.type.toString().split('.').last}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    if (quiz!.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quiz!.tags.map((tag) {
                return Chip(
                  label: Text(tag[0].toUpperCase() + tag.substring(1), style: TextStyle(fontSize: 12, color: Colors.black)),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
