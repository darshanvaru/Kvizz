import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

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
                widget.quiz.title
                    .split(' ')
                    .map(
                      (word) => word.isEmpty
                      ? ''
                      : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
                )
                    .join(' '),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              "${widget.quiz.description[0].toUpperCase()}${widget.quiz.description.substring(1)}",
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 10),

            // Difficulty row
            Row(
              children: [
                Icon(Icons.bolt, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  "${widget.quiz.difficulty[0].toUpperCase()}${widget.quiz.difficulty.substring(1)}",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Type row
            Row(
              children: [
                Icon(
                  widget.quiz.type == 'manual' ? Icons.handyman : Icons.memory,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.quiz.type == 'manual'
                      ? 'Manually Generated'
                      : 'AI Generated',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Tags row
            if (widget.quiz.tags.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.tag, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.quiz.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList()
                        ..addAll(
                          widget.quiz.tags.length > 3
                              ? [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${widget.quiz.tags.length - 3}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]
                              : [],
                        ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

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
