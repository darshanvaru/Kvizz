import 'package:flutter/material.dart';
import 'package:kvizz/models/question_model.dart';
import 'package:collection/collection.dart';
import '../enums/enums.dart';

class PreviewQuizScreen extends StatefulWidget {
  final List<QuestionModel> questions;

  const PreviewQuizScreen({super.key, required this.questions});

  @override
  State createState() => PreviewQuizScreenState();
}

class PreviewQuizScreenState extends State<PreviewQuizScreen>
    with TickerProviderStateMixin {
  late final List<QuestionModel> questions;

  int currentQuestionIndex = 0;
  bool? lastAnswerCorrect;
  bool answered = false;

  Set<int> selectedIndexes = {};
  int? selectedRadio;

  TextEditingController answerController = TextEditingController();
  List<MapEntry<int, String>> reorderedOptions = [];

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    _prepareQuestion();
  }

  /// Prepare state for the current question
  void _prepareQuestion() {
    setState(() {
      answered = false;
      selectedIndexes.clear();
      selectedRadio = null;
      answerController.clear();
      reorderedOptions = [];
    });

    final question = questions[currentQuestionIndex];
    if (question.type == QuestionType.reorder) {
      reorderedOptions = question.options.asMap().entries.toList();
    }
  }

  /// Submit the answer for the current question and evaluate correctness
  void submitAnswer() {
    final question = questions[currentQuestionIndex];
    bool isCorrect = false;

    switch (question.type) {
      case QuestionType.single:
        isCorrect =
            selectedRadio != null &&
            selectedRadio.toString() == question.correctAnswer.first;
        break;

      case QuestionType.multiple:
        Set<String> selectedIndicesStr = selectedIndexes
            .map((i) => i.toString())
            .toSet();
        Set<String> correctIndicesSet = question.correctAnswer.toSet();
        isCorrect =
            selectedIndicesStr.length == correctIndicesSet.length &&
            selectedIndicesStr.containsAll(correctIndicesSet);
        break;

      case QuestionType.open:
        final answer = answerController.text.trim();
        isCorrect =
            answer.isNotEmpty &&
            question.correctAnswer
                .map((e) => e.toLowerCase())
                .contains(answer.toLowerCase());
        break;

      case QuestionType.reorder:
        List<String> userOrder = reorderedOptions.map((e) => e.value).toList();
        List<String> options = question.options;
        List<String> userOrderIndices = userOrder
            .map((optionText) => options.indexOf(optionText).toString())
            .toList();
        List<String> correctOrder = question.correctAnswer;
        isCorrect = const ListEquality().equals(userOrderIndices, correctOrder);
        break;

      case QuestionType.trueFalse:
        String selectedLabel = selectedRadio == 0 ? "0" : "1";
        isCorrect = selectedLabel == question.correctAnswer.first;
        break;
    }

    setState(() {
      lastAnswerCorrect = isCorrect;
      answered = true;
    });
  }

  /// Navigate to the next question, if available
  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _prepareQuestion();
    }
  }

  /// Navigate to the previous question, if available
  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _prepareQuestion();
    }
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Smooth scroll effect
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Bar with subtle shadow and height
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        width:
                            MediaQuery.of(context).size.width *
                                ((currentQuestionIndex + 1) /
                                    questions.length) -
                            32,
                        // subtract horizontal padding
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F8DF9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4F8DF9,
                              ).withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Row with Exit Button aligned left and question numbering right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text("Exit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    Text(
                      "${currentQuestionIndex + 1} of ${questions.length}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Question Card with deeper shadow and more padding
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Type Label with subtle background
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          question.type == QuestionType.single
                              ? "Single Choice Question"
                              : question.type == QuestionType.open
                              ? "Open Ended Question"
                              : question.type == QuestionType.reorder
                              ? "Reorder Question"
                              : "Multiple Choice Question",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Question Text
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(
                        height: question.type != QuestionType.open ? 32 : 16,
                      ),

                      // --- Question Types Builders ---

                      // Single choice
                      if (question.type == QuestionType.single)
                        ...List.generate(question.options.length, (index) {
                          final isCorrect =
                              question.options[index] ==
                              question.options[int.parse(
                                question.correctAnswer.first,
                              )];
                          final isIncorrect = answered && !isCorrect;

                          Color tileColor = Colors.white;
                          Color borderColor = Colors.grey.shade300;
                          Icon leadingIcon = const Icon(
                            Icons.circle_outlined,
                            color: Colors.grey,
                          );
                          Color optionTextColor = Colors.black54;

                          if (answered) {
                            if (isCorrect) {
                              tileColor = const Color(0xFFD6F4E7);
                              borderColor = Colors.teal;
                              leadingIcon = const Icon(
                                Icons.check_circle,
                                color: Colors.teal,
                              );
                              optionTextColor = Colors.teal;
                            } else if (isIncorrect) {
                              tileColor = Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1);
                              borderColor = Colors.redAccent;
                              leadingIcon = const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              );
                              optionTextColor = Colors.redAccent;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: tileColor,
                              border: Border.all(
                                color: borderColor,
                                width: isCorrect || isIncorrect ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: leadingIcon,
                              title: Text(
                                question.options[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: optionTextColor,
                                ),
                              ),
                              onTap: answered
                                  ? null
                                  : () => setState(() {
                                      selectedRadio = index;
                                      answered = true;
                                      submitAnswer();
                                    }),
                            ),
                          );
                        }),

                      // Multiple choice
                      if (question.type == QuestionType.multiple)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...List.generate(question.options.length, (index) {
                              final isCorrect =
                                  answered &&
                                  question.correctAnswer.contains(
                                    index.toString(),
                                  );
                              final isIncorrect =
                                  answered &&
                                  !question.correctAnswer.contains(
                                    index.toString(),
                                  );

                              Color tileColor = Colors.white;
                              Color borderColor = Colors.grey.shade300;
                              Color optionTextColor = Colors.black87;

                              if (answered) {
                                if (isCorrect) {
                                  tileColor = const Color(0xFFD6F4E7);
                                  borderColor = Colors.teal;
                                  optionTextColor = Colors.teal;
                                } else if (isIncorrect) {
                                  tileColor = const Color(0xFFFBE4DF);
                                  borderColor = Colors.redAccent;
                                  optionTextColor = Colors.redAccent;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  border: Border.all(
                                    color: borderColor,
                                    width: isCorrect || isIncorrect ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: selectedIndexes.contains(index),
                                    onChanged: answered
                                        ? null
                                        : (val) {
                                            setState(() {
                                              if (val == true) {
                                                selectedIndexes.add(index);
                                              } else {
                                                selectedIndexes.remove(index);
                                              }
                                            });
                                          },
                                  ),
                                  title: Text(
                                    question.options[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: optionTextColor,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            if (!answered)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentQuestionIndex > 0
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  foregroundColor: currentQuestionIndex > 0
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  elevation: currentQuestionIndex > 0 ? 4 : 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: selectedIndexes.isEmpty
                                    ? null
                                    : () {
                                        submitAnswer();
                                      },
                                child: const Text("Submit"),
                              ),
                          ],
                        ),

                      // Open ended
                      if (question.type == QuestionType.open)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: answerController,
                              enabled: !answered,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Type your answer...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentQuestionIndex > 0
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  foregroundColor: currentQuestionIndex > 0
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  elevation: currentQuestionIndex > 0 ? 4 : 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: answered ? null : () => submitAnswer(),
                                child: const Text("Submit"),
                              ),
                            ),
                          ],
                        ),

                      // Reorder
                      if (question.type == QuestionType.reorder)
                        Column(
                          children: [
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reorderedOptions.length,
                              buildDefaultDragHandles: false,
                              onReorder: answered
                                  ? (_, __) {}
                                  : (oldIndex, newIndex) {
                                      setState(() {
                                        if (newIndex > oldIndex) newIndex -= 1;
                                        final item = reorderedOptions.removeAt(
                                          oldIndex,
                                        );
                                        reorderedOptions.insert(newIndex, item);
                                      });
                                    },
                              itemBuilder: (context, index) {
                                final entry = reorderedOptions[index];
                                return ReorderableDragStartListener(
                                  key: ValueKey(entry.key),
                                  index: index,
                                  child: ListTile(
                                    tileColor: Colors.grey.shade100,
                                    title: Text(entry.value),
                                    trailing: const Icon(Icons.drag_handle),
                                  ),
                                );
                              },
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentQuestionIndex > 0
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  foregroundColor: currentQuestionIndex > 0
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  elevation: currentQuestionIndex > 0 ? 4 : 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: answered
                                    ? null
                                    : () => submitAnswer(),
                                child: const Text("Submit"),
                              ),
                            ),
                          ],
                        ),

                      // True/False
                      if (question.type == QuestionType.trueFalse)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...List.generate(2, (index) {
                              final isCorrect =
                                  answered &&
                                  index ==
                                      int.parse(question.correctAnswer.first);
                              final isIncorrect = answered && !isCorrect;
                              final label = index == 0 ? "False" : "True";

                              Color tileColor = Colors.white;
                              Color borderColor = Colors.grey.shade300;
                              Icon leadingIcon = const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              );
                              Color optionTextColor = Colors.black54;

                              if (answered) {
                                if (isCorrect) {
                                  tileColor = const Color(0xFFD6F4E7);
                                  borderColor = Colors.teal;
                                  leadingIcon = const Icon(
                                    Icons.check_circle,
                                    color: Colors.teal,
                                  );
                                  optionTextColor = Colors.teal;
                                } else if (isIncorrect) {
                                  tileColor = Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1);
                                  borderColor = Colors.redAccent;
                                  leadingIcon = const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                  );
                                  optionTextColor = Colors.redAccent;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  border: Border.all(
                                    color: borderColor,
                                    width: isCorrect || isIncorrect ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: leadingIcon,
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: optionTextColor,
                                    ),
                                  ),
                                  onTap: answered
                                      ? null
                                      : () => setState(() {
                                          selectedRadio = index;
                                          answered = true;
                                          submitAnswer();
                                        }),
                                ),
                              );
                            }),
                          ],
                        ),

                      // Bottom textual feedback for all question types
                      if (answered && lastAnswerCorrect != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              Icon(
                                lastAnswerCorrect == true
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 30,
                                color: lastAnswerCorrect == true
                                    ? Colors.teal
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lastAnswerCorrect == true
                                    ? "Correct!"
                                    : "Incorrect!",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: lastAnswerCorrect == true
                                      ? Colors.teal
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Buttons Row with elevated and consistent padding
                // Replace your existing navigation buttons Row with this:
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                constraints.maxWidth *
                                0.45, // max half width for button
                          ),
                          child: ElevatedButton.icon(
                            onPressed: currentQuestionIndex > 0
                                ? _previousQuestion
                                : null,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                            ),
                            label: const FittedBox(child: Text("Previous")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentQuestionIndex > 0
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              foregroundColor: currentQuestionIndex > 0
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              elevation: currentQuestionIndex > 0 ? 4 : 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.45,
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                currentQuestionIndex < questions.length - 1
                                ? _nextQuestion
                                : null,
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 20,
                            ),
                            label: const FittedBox(child: Text("Next")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  currentQuestionIndex < questions.length - 1
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              foregroundColor:
                                  currentQuestionIndex < questions.length - 1
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              elevation:
                                  currentQuestionIndex < questions.length - 1
                                  ? 4
                                  : 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
