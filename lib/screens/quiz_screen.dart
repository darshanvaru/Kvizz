import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

enum QuestionType { single, multiple, open, reorder }

class Question {
  final String question;
  final List<String> options;
  final QuestionType type;
  final dynamic correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.type,
    required this.correctAnswer,
  });
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final List<Question> questions = [
    Question(
      question: "What is the capital of France?",
      options: ["Paris", "London", "Berlin", "Rome"],
      type: QuestionType.single,
      correctAnswer: 0,
    ),
    Question(
      question: "Select the programming languages.",
      options: ["Python", "Flutter", "C++", "HTML"],
      type: QuestionType.multiple,
      correctAnswer: {0, 2},
    ),
    Question(
      question: "Describe your experience with AI.",
      options: [],
      type: QuestionType.open,
      correctAnswer: ["good", "excellent", "Fabulous"],
    ),
    Question(
      question: "Arrange the steps in priority.",
      options: ["Plan", "Design", "Code", "Test"],
      type: QuestionType.reorder,
      correctAnswer: ["Plan", "Design", "Code", "Test"],
    ),
  ];

  int currentIndex = 2;
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
    _prepareQuestion();
  }

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

  //Starts 10 sec timer and also set flag for times up and answered if 30 sec is completed
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

  void submitAnswer() {
    final question = questions[currentIndex];
    bool isCorrect = false;
    int pointsAwarded = 0;

    switch (question.type) {
      case QuestionType.single:
        isCorrect = selectedRadio == question.correctAnswer;
        pointsAwarded = isCorrect ? 1 : 0;

        print("-------------------");
        print("Question: ${question.question}");
        print("Answer: ${question.options[question.correctAnswer]}");
        print("Answer Submitted: ${selectedRadio != null ? question.options[selectedRadio!] : 'None'}");
        print("Is Correct? $isCorrect");
        print("Time Taken: $timeTaken seconds");
        print("-------------------");
        break;

      case QuestionType.multiple:
        Set<int> correct = Set<int>.from(question.correctAnswer);
        pointsAwarded = selectedIndexes.where((i) => correct.contains(i)).length;
        isCorrect = Set<int>.from(selectedIndexes).containsAll(correct) && selectedIndexes.length == correct.length;
        break;

        case QuestionType.open:
        final answer = answerController.text.trim();
        isCorrect = answer.isNotEmpty &&
            (question.correctAnswer as List)
                .map((e) => e.toString().toLowerCase())
                .contains(answer.toLowerCase());
        pointsAwarded = isCorrect ? 1 : 0;
        break;

      case QuestionType.reorder:
        List<String> userOrder = reorderedOptions.map((e) => e.value).toList();
        isCorrect = const ListEquality().equals(userOrder, List<String>.from(question.correctAnswer));
        pointsAwarded = isCorrect ? 1 : 0;
        break;
    }

    setState(() {
      score += pointsAwarded;
      lastAnswerCorrect = isCorrect;
      answered = true;
    });
  }

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
    if (currentIndex >= questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz Completed")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🎉 Final Score: $score / ${questions.length}",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [

              // Progress Bar
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

              // Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(onPressed: _prepareQuestion, child: Text("Reset")),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff53BDEB)),
                                strokeWidth: 4,
                              ),
                            ),
                            Text(
                              "$timeLeft",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF53BDEB),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Question Card
              Expanded(

                //Outer Main Container
                child: Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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

                      //Question Number and total questions
                      Text(
                        "${currentIndex + 1}/${questions.length}",
                        style: const TextStyle(color: Colors.black54, fontSize: 16),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),

                      // Question
                      Text(
                        question.question,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: question.type != QuestionType.open ? 24 : 8),

                      ///QuestionType Single Option builder
                      if (question.type == QuestionType.single)
                        ...List.generate(question.options.length, (index) {
                          final isSelected = selectedRadio == index;
                          final isCorrect = answered && index == question.correctAnswer;
                          final isIncorrect = answered && isSelected && !isCorrect;

                          Color? tileColor = Colors.white;
                          Color borderColor = Colors.grey.shade300;
                          Icon leadingIcon = const Icon(Icons.circle_outlined, color: Colors.grey);
                          Color optionTextColor = Colors.black54;

                          if (timeUp) {
                            if (isCorrect) {
                              tileColor = const Color(0xFFD6F4E7);
                              borderColor = Colors.teal;
                              leadingIcon = const Icon(Icons.check_circle, color: Colors.teal);
                              optionTextColor = Colors.teal;
                            } else if (isIncorrect) {
                              tileColor = Theme.of(context).primaryColor.withValues(alpha: 0.1);
                              borderColor = Colors.redAccent;
                              leadingIcon = const Icon(Icons.cancel, color: Colors.redAccent);
                              optionTextColor = Colors.redAccent;
                            }
                          } else if (!timeUp && isSelected) {
                            tileColor = Colors.grey.shade200;
                            borderColor = const Color(0xFF57A2C3);
                            leadingIcon = const Icon(Icons.circle_outlined, color: Color(0xFF53BDEB));
                            optionTextColor = Colors.black87;
                          }


                          //Inner Option container
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
                                question.options[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: optionTextColor
                                ),
                              ),
                              onTap: answered
                                  ? null
                                  : () => setState(() {
                                            selectedRadio = index;
                                            timeTaken = DateTime.now()
                                                .difference(questionStartTime!)
                                                .inMilliseconds;
                                            answered = true;
                                          }),
                            ),
                          );
                        }),

                      /// QuestionType Multiple option builder
                      if (question.type == QuestionType.multiple)
                        ...List.generate(question.options.length, (index) {
                          final isSelected = selectedIndexes.contains(index);
                          final isCorrect = (answered || timeUp) &&
                              (question.correctAnswer as Set).contains(index);
                          final isIncorrect = (answered || timeUp) &&
                              isSelected &&
                              !(question.correctAnswer as Set).contains(index);

                          // Colors and styles
                          Color? tileColor = Colors.white;
                          Color borderColor = Colors.grey.shade300;
                          Color optionTextColor = Colors.black87;

                          if (answered || timeUp) {
                            if (isCorrect) {
                              tileColor = const Color(0xFFD6F4E7); // light green
                              borderColor = Colors.teal;
                              optionTextColor = Colors.teal;
                            } else if (isIncorrect) {
                              tileColor = const Color(0xFFFBE4DF); // light red
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
                                width: isSelected || isCorrect || isIncorrect ? 2 : 1,
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

                      /// QuestionType Open Ended TextField builder
                      if (question.type == QuestionType.open)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: answerController,
                              enabled: !answered && !timeUp, // disable if answered or time's up
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Type your answer...",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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


                      if (question.type == QuestionType.reorder)
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          onReorder: answered || timeUp
                              ? (_, __) {}
                              : (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = reorderedOptions.removeAt(oldIndex);
                              reorderedOptions.insert(newIndex, item);
                            });
                          },
                          children: [
                            for (final entry in reorderedOptions)
                              ListTile(
                                key: ValueKey(entry.key),
                                title: Text(entry.value),
                                tileColor: Colors.grey.shade100,
                                trailing: Icon(Icons.drag_handle),
                              ),
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
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Next Button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: const Color(0xFF53BDEB),
              //       foregroundColor: Colors.white,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       minimumSize: const Size(0, 48),
              //     ),
              //     onPressed: ((currentIndex < questions.length - 1) && !answered)? submitAnswer : null,
              //     child:Text(((currentIndex < questions.length - 1) && !answered)? "Submit" : "Finish") ,
              //
              //     // onPressed: (!answered && !timeUp &&
              //     //     (
              //     //         (question.type == QuestionType.single && selectedRadio != null) ||
              //     //             (question.type == QuestionType.multiple && selectedIndexes.isNotEmpty) ||
              //     //             (question.type == QuestionType.open && answerController.text.trim().isNotEmpty) ||
              //     //             (question.type == QuestionType.reorder && reorderedOptions.isNotEmpty))
              //     // )
              //     //     ? () {
              //     //   if (!answered && !timeUp) {
              //     //     submitAnswer();
              //     //   } else if (answered || timeUp) {
              //     //     nextQuestion();
              //     //   }
              //     // }
              //     //     : nextQuestion,
              //     // child: Text(
              //     //   (!answered && !timeUp) ? "Submit" : (currentIndex < questions.length - 1 ? "Next" : "Finish"),
              //     //   style: const TextStyle(
              //     //     fontWeight: FontWeight.w700,
              //     //     fontSize: 20,
              //     //   ),
              //     // ),
              //   ),
              // ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}