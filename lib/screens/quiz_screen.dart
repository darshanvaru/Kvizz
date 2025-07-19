import 'dart:async';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../providers/dummy_data.dart' as dummy_data;
import '../models/Question.dart';
import 'create_quiz_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final List<QuestionModel> questions = dummy_data.questions;

  int currentIndex = 0;
  int score = 0;
  bool? lastAnswerCorrect;
  bool answered = false;
  bool timeUp = false;

  Set<int> selectedIndexes = {};
  int? selectedRadio;

  DateTime? questionStartTime;
  int timeTaken = 0;

  TextEditingController answerController = TextEditingController();
  List<MapEntry<int, String>> reorderedOptions = [];

  Timer? timer;
  int timeLeft = 10;

  @override
  void initState() {
    super.initState();
    print("Questions.isEmpty: ${questions.isEmpty}");
    _prepareQuestion();
  }

  /// Resets all the flags, controller and variables
  void _prepareQuestion() {
    setState(() {
      answered = false;
      timeUp = false;
      selectedIndexes.clear();
      selectedRadio = null;
      answerController.clear();
      timeLeft = 10;
      questionStartTime = DateTime.now();
      timeTaken = 0;
      reorderedOptions = [];
    });
    if (timer != null) {
      timer!.cancel();
    }
    _startTimer();
    final question = questions[currentIndex];
    if (question.type == QuestionType.reorder) {
      reorderedOptions = question.options
          .asMap()
          .entries
          .map((e) => MapEntry(e.key, e.value))
          .toList();
    }
  }

  /// Starts 10 sec timer and also set flag for times up and answered if 30 sec is completed
  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
        if (timeLeft == 0) {
          setState(() {
            timeUp = true;
            submitAnswer();
          });
        }
      } else {
        t.cancel();
      }
    });
  }

  /// Check the question type and performs calculations accordingly
  void submitAnswer() {
    final question = questions[currentIndex];
    bool isCorrect = false;
    int pointsAwarded = 0;

    switch (question.type) {
      case QuestionType.single:
        isCorrect = question.options[selectedRadio?? 0] == question.correctAnswer.first;
        pointsAwarded = isCorrect ? 1 : 0;

        print("-------------------");
        print("Question Type: ${question.type}");
        print("Question: ${question.question}");
        print("Answer: ${question.correctAnswer.first}");
        print("Answer Submitted: ${selectedRadio != null ? question.options[selectedRadio!] : 'None'}");
        print("Is Correct? $isCorrect");
        print("Time Taken: $timeTaken Milliseconds");
        print("-------------------");

        Future.delayed(const Duration(seconds: 5), () {
          currentIndex++;
          _prepareQuestion();
        });
        break;

      case QuestionType.multiple:
        isCorrect = selectedIndexes.every((index) => question.correctAnswer.contains(question.options[index])) &&
            selectedIndexes.length == question.correctAnswer.length;
            // Set<int>.from(selectedIndexes).containsAll(correct) &&
            //     selectedIndexes.length == correct.length;
        pointsAwarded = isCorrect ? 1 : 0;

        print("-------------------");
        print("Question Type: ${question.type}");
        print("Question: ${question.question}");
        print("Correct Answers: ${(question.correctAnswer as List).map((i) => question.options[i]).join(', ')}");
        print("Selected Answers: ${selectedIndexes.map((i) => question.options[i]).join(', ')}");
        print("Is Correct? $isCorrect");
        print("Time Taken: $timeTaken Milliseconds");
        print("-------------------");

        Future.delayed(const Duration(seconds: 5), () {
          currentIndex++;
          _prepareQuestion();
        });
        break;

      case QuestionType.open:
        final answer = answerController.text.trim();
        isCorrect = answer.isNotEmpty && question.correctAnswer.contains(answer);

        pointsAwarded = isCorrect ? 1 : 0;

        print("-------------------");
        print("Question Type: ${question.type}");
        print("Question: ${question.question}");
        print("Correct Answers: ${question.correctAnswer.join(', ')}");
        print("Answer Submitted: $answer");
        print("Is Correct? $isCorrect");
        print("Time Taken: $timeTaken Milliseconds");
        print("-------------------");

        Future.delayed(const Duration(seconds: 5), () {
          currentIndex++;
          _prepareQuestion();
        });
        break;

      case QuestionType.reorder:
        List<String> userOrder = reorderedOptions.map((e) => e.value).toList();
        List<String> correctOrder = question.correctAnswer;

        isCorrect = const ListEquality().equals(userOrder, correctOrder);
        pointsAwarded = isCorrect ? 1 : 0;

        print("-------------------");
        print("Question Type: ${question.type}");
        print("Question: ${question.question}");
        print("Correct Order: ${correctOrder.join(' → ')}");
        print("User Order: ${userOrder.join(' → ')}");
        print("Is Correct? $isCorrect");
        print("Time Taken: $timeTaken Milliseconds");
        print("-------------------");

        Future.delayed(const Duration(seconds: 5), () {
          currentIndex++;
          _prepareQuestion();
        });
        break;

      case QuestionType.trueFalse:
        // Convert the string "true"/"false" to index: 1 for true, 0 for false
        // int correctIndex = question.correctAnswer.first.toLowerCase() == "true" ? 1 : 0;
        String selectedLabel = selectedRadio == 0 ? "true" : "false";

        isCorrect = selectedLabel == question.correctAnswer.first.toLowerCase();
        pointsAwarded = isCorrect ? 1 : 0;

        print("-------------------");
        print("Question Type: ${question.type}");
        print("Question: ${question.question}");
        print("Correct Answer: ${question.correctAnswer.first}");
        print("Answer Submitted: ${selectedLabel}");
        print("Is Correct? $isCorrect");
        print("Time Taken: $timeTaken seconds");
        print("-------------------");

        Future.delayed(const Duration(seconds: 5), () {
          currentIndex++;
          _prepareQuestion();
        });
        break;

    }

    setState(() {
      score += pointsAwarded;
      lastAnswerCorrect = isCorrect;
      answered = true;
    });
  }

  /// Increments the index and calls PrepareQuestion()
  void nextQuestion() {
    setState(() {
      currentIndex++;
    });
    if (currentIndex < questions.length) {
      _prepareQuestion();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    ///Result screen
    if (currentIndex >= questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz Completed")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🎉 Final Score: $score / ${questions.length}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    currentIndex = 0;
                    score = 0;
                    _prepareQuestion();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Restart Quiz"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => QuizCreationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Create Quiz"),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// Progress Bar
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3E2FF),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (currentIndex + 1) / questions.length,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF56C7F9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _prepareQuestion,
                      child: Text("Reset"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  value: timeLeft / 10,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xff53BDEB),
                                  ),
                                  strokeWidth: 4,
                                ),
                              ),
                              Text(
                                "$timeLeft",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF53BDEB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                /// Question Card
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //Question Number/Total questions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            question.type == QuestionType.single
                                ? "Single Choice Question"
                                : question.type == QuestionType.open
                                ? "Open Ended Question"
                                : question.type == QuestionType.reorder
                                ? "Reorder Question"
                                : "Multiple Choice Question",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "${currentIndex + 1}/${questions.length}",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Question
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: question.type != QuestionType.open ? 24 : 8,
                      ),

                      ///QuestionType Single Option builder
                      if (question.type == QuestionType.single)
                        ...List.generate(question.options.length, (index) {
                          final isSelected = selectedRadio == index;
                          final isCorrect = question.options[index] == question.correctAnswer.first;
                          // final isCorrect =
                          //     answered && index == question.correctAnswer;
                          final isIncorrect =
                              answered && isSelected && !isCorrect;

                          Color? tileColor = Colors.white;
                          Color borderColor = Colors.grey.shade300;
                          Icon leadingIcon = const Icon(
                            Icons.circle_outlined,
                            color: Colors.grey,
                          );
                          Color optionTextColor = Colors.black54;

                          if (timeUp) {
                            if (isCorrect) {
                              tileColor = const Color(0xFFD6F4E7);
                              borderColor = Colors.teal;
                              leadingIcon = const Icon(
                                Icons.check_circle,
                                color: Colors.teal,
                              );
                              optionTextColor = Colors.teal;
                            } else if (isIncorrect) {
                              tileColor = Theme.of(context,).primaryColor.withValues(alpha: 0.1);
                              borderColor = Colors.redAccent;
                              leadingIcon = const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              );
                              optionTextColor = Colors.redAccent;
                            }
                          } else if (!timeUp && isSelected) {
                            tileColor = Colors.grey.shade200;
                            borderColor = const Color(0xFF57A2C3);
                            leadingIcon = const Icon(
                              Icons.circle,
                              color: Color(0xFF53BDEB),
                            );
                            optionTextColor = Colors.black87;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: tileColor,
                              border: Border.all(
                                color: borderColor,
                                width: isSelected || isCorrect || isIncorrect
                                    ? 2
                                    : 1,
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
                                      timeTaken = DateTime.now().difference(questionStartTime!).inMilliseconds;
                                      answered = true;
                                    }),
                            ),
                          );
                        }),

                      /// QuestionType Multiple option builder
                      if (question.type == QuestionType.multiple)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Options
                            ...List.generate(question.options.length, (index) {
                              final isSelected = selectedIndexes.contains(index);
                              final isCorrect =
                                  (answered || timeUp) &&
                                  question.correctAnswer.contains(question.options[index]);
                              final isIncorrect =
                                  (answered || timeUp) &&
                                  isSelected &&
                                  !question.correctAnswer.contains(question.options[index]);

                              // Colors and styles
                              Color? tileColor = Colors.white;
                              Color borderColor = Colors.grey.shade300;
                              Color optionTextColor = Colors.black87;

                              if (answered && timeUp) {
                                if (isCorrect) {
                                  tileColor = const Color(0xFFD6F4E7); // green
                                  borderColor = Colors.teal;
                                  optionTextColor = Colors.teal;
                                } else if (isIncorrect) {
                                  tileColor = const Color(0xFFFBE4DF); // red
                                  borderColor = Colors.redAccent;
                                  optionTextColor = Colors.redAccent;
                                }
                              } else if (!timeUp && isSelected) {
                                tileColor = Colors.grey.shade200;
                                borderColor = const Color(0xFF57A2C3); // blue
                                optionTextColor = Colors.black87;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  border: Border.all(
                                    color: borderColor,
                                    width:
                                        isSelected || isCorrect || isIncorrect
                                        ? 2
                                        : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (answered || timeUp)
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
                            // Submit Button
                            if (!answered && !timeUp)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF53BDEB),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: selectedIndexes.isEmpty
                                    ? null
                                    : () {
                                        setState(() {
                                          answered = true;
                                          // userAnswer = selectedIndexes.toSet(); // Store user's selected options
                                          // Optionally record timeTaken if needed
                                          timeTaken = DateTime.now()
                                              .difference(questionStartTime!)
                                              .inMilliseconds;
                                        });
                                      },
                                child: const Text("Submit"),
                              ),
                          ],
                        ),

                      /// QuestionType Open Ended TextField builder
                      if (question.type == QuestionType.open)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: answerController,
                              enabled: !answered && !timeUp,
                              // disable if answered or time's up
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

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF53BDEB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: (answered || timeUp)
                                    ? null
                                    : () {
                                        setState(() {
                                          answered = true;

                                          // Save time taken
                                          timeTaken = DateTime.now()
                                              .difference(questionStartTime!)
                                              .inMilliseconds;
                                        });
                                      },
                                child: const Text("Submit"),
                              ),
                            ),
                          ],
                        ),

                      /// QuestionType Reorder Listview option builder
                      if (question.type == QuestionType.reorder)
                        Column(
                          children: [
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: question.options.length,
                              buildDefaultDragHandles: false,
                              onReorder: answered || timeUp
                                  ? (_,__,) {} // still required, but won't be triggered
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

                                // Otherwise, show draggable tile
                                return ReorderableDragStartListener(
                                  key: ValueKey(entry.key),
                                  index: index,
                                  child: ListTile(
                                    tileColor: Colors.grey.shade100,
                                    title: Text(entry.value),
                                    trailing: timeUp
                                        ? Text(
                                            "${question.correctAnswer.indexOf(entry.value) + 1}",
                                          )
                                        : Icon(Icons.drag_handle),
                                  ),
                                );
                              },
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF53BDEB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: (answered || timeUp)
                                    ? null
                                    : () {
                                        setState(() {
                                          answered = true;

                                          // Save time taken
                                          timeTaken = DateTime.now()
                                              .difference(questionStartTime!)
                                              .inMilliseconds;
                                        });
                                      },
                                child: const Text("Submit"),
                              ),
                            ),
                          ],
                        ),

                      /// QuestionType True/False Option builder
                      if (question.type == QuestionType.trueFalse)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...List.generate(2, (index) {
                              final correctAnswerIndex = question.correctAnswer.first.toLowerCase() == 'true' ? 0 : 1;
                              final isSelected = selectedRadio == index;
                              final isCorrect = answered && index == correctAnswerIndex;
                              final isIncorrect = answered && isSelected && !isCorrect;

                              String label = index == 0 ? "False" : "True";

                              Color? tileColor = Colors.white;
                              Color borderColor = Colors.grey.shade300;
                              Icon leadingIcon = Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              );
                              Color optionTextColor = Colors.black54;

                              if (timeUp) {
                                if (isCorrect) {
                                  tileColor = const Color(0xFFD6F4E7);
                                  borderColor = Colors.teal;
                                  leadingIcon = const Icon(Icons.check_circle, color: Colors.teal);
                                  optionTextColor = Colors.teal;
                                } else if (isIncorrect) {
                                  tileColor = Theme.of(context).primaryColor.withOpacity(0.1);
                                  borderColor = Colors.redAccent;
                                  leadingIcon = const Icon(Icons.cancel, color: Colors.redAccent);
                                  optionTextColor = Colors.redAccent;
                                }
                              } else if (!timeUp && isSelected) {
                                tileColor = Colors.grey.shade200;
                                borderColor = const Color(0xFF57A2C3);
                                leadingIcon = const Icon(Icons.circle, color: Color(0xFF53BDEB));
                                optionTextColor = Colors.black87;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  border: Border.all(
                                    color: borderColor,
                                    width: isSelected || isCorrect || isIncorrect ? 2 : 1,
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
                                      : () {
                                    setState(() {
                                      selectedRadio = index;
                                      answered = true;
                                      timeTaken = DateTime.now().difference(questionStartTime!).inMilliseconds;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),

                      //Correct or Incorrect
                      if (answered && lastAnswerCorrect != null && timeUp)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
