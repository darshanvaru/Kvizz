import 'package:flutter/material.dart';
import '../models/Quiz.dart';

class QuizCard extends StatefulWidget {
  final QuizModel quiz;

  const QuizCard({super.key, required this.quiz});

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            FittedBox(
              child: Text(
                widget.quiz.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              widget.quiz.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Info rows
            FittedBox(
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    widget.quiz.difficulty,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.chevron_right,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
