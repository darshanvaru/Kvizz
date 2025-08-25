import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvizz/models/Question.dart';
import 'package:kvizz/providers/game_session_provider.dart';
import 'package:kvizz/providers/user_provider.dart';
import 'package:kvizz/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../enums/enums.dart';
import '../models/game_session_model.dart';
// import '../providers/tab_index_provider.dart';

class OngoingQuizScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int timePerQuestion;
  final int maxPointsPerQuestion;
  final bool isHost;
  final String gameSessionId;

  const OngoingQuizScreen({
    super.key,
    required this.questions,
    required this.timePerQuestion,
    required this.maxPointsPerQuestion,
    required this.isHost,
    required this.gameSessionId,
  });

  @override
  State<OngoingQuizScreen> createState() => _OngoingQuizScreenState();
}

class _OngoingQuizScreenState extends State<OngoingQuizScreen> with TickerProviderStateMixin {
  late final List<QuestionModel> questions;

  int currentQuestionIndex = 0;
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
  late int timeLeft;

  bool isFirstTime = true;

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    debugPrint("[OngoingScreen.initState] is Questions Empty: ${questions.isEmpty}");
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
      timeLeft = widget.timePerQuestion;
      questionStartTime = DateTime.now();
      timeTaken = 0;
      reorderedOptions = [];
    });
    if (timer != null) {
      timer!.cancel();
    }
    _startTimer();
    final question = questions[currentQuestionIndex];
    if (question.type == QuestionType.reorder) {
      reorderedOptions = question.options
          .asMap()
          .entries
          .map((e) => MapEntry(e.key, e.value))
          .toList();
    }
  }

  /// Starts timer and also set flag for times up and answered if timer is completed
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
    final question = questions[currentQuestionIndex];
    bool isCorrect = false;
    int pointsAwarded = 0;
    int maxPointPerQuestion = widget.maxPointsPerQuestion;
    List<String> answerList;

    switch (question.type) {

      case QuestionType.single:
        isCorrect = selectedRadio != null &&
            selectedRadio.toString() == question.correctAnswer.first;
        pointsAwarded = isCorrect ? maxPointPerQuestion : 0;
        answerList = [
          if (selectedRadio != null) question.options[selectedRadio!] else ""
        ];
        break;

      case QuestionType.multiple:
        Set<String> selectedIndicesStr =
        selectedIndexes.map((i) => i.toString()).toSet();
        Set<String> correctIndicesSet = question.correctAnswer.toSet();

        isCorrect = selectedIndicesStr.length == correctIndicesSet.length &&
            selectedIndicesStr.containsAll(correctIndicesSet);

        pointsAwarded = isCorrect ? maxPointPerQuestion : 0;
        answerList = selectedIndexes.map((i) => question.options[i]).toList();
        break;

      case QuestionType.open:
        final answer = answerController.text.trim();
        isCorrect =
            answer.isNotEmpty && question.correctAnswer.contains(answer);
        pointsAwarded = isCorrect ? maxPointPerQuestion : 0;
        final ans = answerController.text.trim();
        answerList = ans.isNotEmpty ? [ans] : [];
        break;

      case QuestionType.reorder:
        List<String> userOrder = reorderedOptions.map((e) => e.value).toList();
        List<String> options = question.options;
        List<String> userOrderIndices = userOrder
            .map((optionText) => options.indexOf(optionText).toString())
            .toList();
        List<String> correctOrder = question.correctAnswer;
        isCorrect = const ListEquality().equals(userOrderIndices, correctOrder);
        pointsAwarded = isCorrect ? maxPointPerQuestion : 0;
        answerList = userOrder;
        break;

      case QuestionType.trueFalse:
        String selectedLabel = selectedRadio == 0 ? "0" : "1";
        isCorrect = selectedLabel == question.correctAnswer.first;
        pointsAwarded = isCorrect ? maxPointPerQuestion : 0;
        answerList = [selectedLabel];
        break;
    }

    //submit answer
    print("-------------------------------");
    print("Question Type: ${question.type}");
    print("Question: ${question.question}");
    print("SocketService().submitAnswer called with: ");
    print("GameSessionId: ${widget.gameSessionId}");
    print("Time Taken: $timeTaken");
    print("Question ID: ${questions[currentQuestionIndex].id}");
    print("Answer: $answerList");
    print("Is Correct: $isCorrect");
    print("User Name: ${Provider.of<UserProvider>(context, listen: false).currentUser!.username}");
    print("-------------------------------");

    if(!widget.isHost) {
      SocketService().submitAnswer(
        gameSessionId: widget.gameSessionId,
        timeTaken: timeTaken,
        questionId: questions[currentQuestionIndex].id,
        answer: answerList,
        isCorrect: isCorrect,
        username: Provider.of<UserProvider>(context, listen: false).currentUser?.username ?? "unknown host",
      );
    }

    //TODO: Future Trivia screen
    Future.delayed(const Duration(seconds: 5), () {
      currentQuestionIndex++;
      _prepareQuestion();
    });

    setState(() {
      score += pointsAwarded;
      lastAnswerCorrect = isCorrect;
      answered = true;
    });
  }

  /// Increments the index and calls PrepareQuestion()
  void nextQuestion() {
    setState(() => currentQuestionIndex++);
    if (currentQuestionIndex < questions.length) {
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
    return Scaffold(
        backgroundColor: const Color(0xFFF6FBFF),
        body: Consumer<GameSessionProvider>(
            builder: (context, gameSessionProvider, child) {

              // If game session is finished, show leaderboard
              if (gameSessionProvider.isFinished || currentQuestionIndex >= questions.length) {
                  timer?.cancel();
                  if(widget.isHost && isFirstTime) {
                    print("-------Before StopQuiz called inside ongoingScreen!");
                    SocketService().stopQuiz(gameSessionProvider.gameSession!.id);
                    print("-------After StopQuiz called inside ongoingScreen!");
                    isFirstTime = false;
                  } else {
                    print("----[ongoingScreen] Not first time");
                  }
                  return leaderBoardBuilder(gameSessionProvider.leaderboard);
              }

              final question = questions[currentQuestionIndex];

              //main quiz screen
              return SafeArea(
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
                                widthFactor: (currentQuestionIndex + 1) / questions.length,
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
                            // stop button
                            // ElevatedButton(
                            //   onPressed: _prepareQuestion,
                            //   child: Text("Reset"),
                            // ),
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
                                          value: timeLeft / widget.timePerQuestion,
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

                              //Question Card Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [

                                  //Question Type
                                  Text(
                                    question.type == QuestionType.single
                                        ? "Single Choice Question"
                                        : question.type == QuestionType.open
                                        ? "Open Ended Question"
                                        : question.type == QuestionType.reorder
                                        ? "Reorder Question"
                                        : "Multiple Choice Question",
                                    style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  // Question Number/Total questions
                                  Text(
                                    "${currentQuestionIndex + 1}/${questions.length}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Question text
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
                                  final isCorrect = question.options[index] == question.options[int.parse(question.correctAnswer.first)];
                                  final isIncorrect = answered && isSelected && !isCorrect;

                                  Color? tileColor = Colors.white;
                                  Color borderColor = Colors.grey.shade300;
                                  Icon leadingIcon = const Icon(
                                    Icons.circle_outlined,
                                    color: Colors.grey,
                                  );
                                  Color optionTextColor = Colors.black54;

                                  // Colors and styles based on state
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
                                          color: optionTextColor,
                                        ),
                                      ),
                                      onTap: widget.isHost || answered
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ...List.generate(question.options.length, (index) {
                                      final isSelected = selectedIndexes.contains(index);
                                      final isCorrect =
                                          (answered || timeUp) &&
                                              question.correctAnswer.contains(index.toString());

                                      final isIncorrect =
                                          (answered || timeUp) &&
                                              isSelected &&
                                              !question.correctAnswer.contains(index.toString());


                                      // Colors and styles
                                      Color? tileColor = Colors.white;
                                      Color borderColor = Colors.grey.shade300;
                                      Color optionTextColor = Colors.black87;

                                      // Colors and styles based on state
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
                                              width: isSelected || isCorrect || isIncorrect ? 2 : 1
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          leading: Checkbox(
                                            value: isSelected,
                                            onChanged: widget.isHost || answered || timeUp
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
                                    if (!answered && !timeUp && !widget.isHost)
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
                                      enabled: !answered && !timeUp && !widget.isHost,
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
                                    if(!widget.isHost)...{
                                      const SizedBox(height: 10),
                                      // Submit Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF53BDEB),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            minimumSize: const Size(0, 48),
                                          ),
                                          onPressed: (answered || timeUp)
                                              ? null
                                              : () {
                                            setState(() {
                                              answered = true;
                                              timeTaken = DateTime
                                                  .now()
                                                  .difference(
                                                  questionStartTime!)
                                                  .inMilliseconds;
                                              });
                                            },
                                            child: const Text("Submit"),
                                          ),
                                        ),
                                      }
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
                                      // Disallow reordering if user is host
                                      onReorder: (answered || timeUp || widget.isHost)
                                          ? (_,__) {}
                                          : (oldIndex, newIndex) {
                                        setState(() {
                                          if (newIndex > oldIndex) newIndex -= 1;
                                          final item = reorderedOptions.removeAt(oldIndex);
                                          reorderedOptions.insert(newIndex, item);
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final entry = reorderedOptions[index];

                                        // Show non-draggable tile if user is host
                                        if (widget.isHost) {
                                          return ListTile(
                                            key: ValueKey(entry.key),
                                            tileColor: Colors.grey.shade100,
                                            title: Text(entry.value),
                                            trailing: Icon(Icons.drag_handle, color: Colors.grey.shade300),
                                          );
                                        }
                                        // Otherwise, show draggable tile
                                        return ReorderableDragStartListener(
                                          key: ValueKey(entry.key),
                                          index: index,
                                          child: ListTile(
                                            tileColor: Colors.grey.shade100,
                                            title: Text(entry.value),
                                            trailing: Icon(Icons.drag_handle),
                                          ),
                                        );
                                      },
                                    ),

                                    // Submit Button: only show if user is NOT host
                                    if (!widget.isHost)
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
                                          onPressed: (answered || timeUp) ? null : () {
                                            setState(() {
                                              answered = true;
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
                                      // final correctAnswerIndex =
                                      // question.correctAnswer.first.toLowerCase() ==
                                      //     'true'
                                      //     ? 0
                                      //     : 1;
                                      final isSelected = selectedRadio == index;
                                      final isCorrect = answered && index == int.parse(question.correctAnswer.first);
                                      final isIncorrect = answered && isSelected && !isCorrect;
                                      String label = index == 0 ? "True" : "False";

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
                                          leadingIcon = const Icon(
                                            Icons.check_circle,
                                            color: Colors.teal,
                                          );
                                          optionTextColor = Colors.teal;
                                        } else if (isIncorrect) {
                                          tileColor = Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: .1);
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
                                            width:
                                            isSelected || isCorrect || isIncorrect
                                                ? 2
                                                : 1,
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
                                          onTap: widget.isHost || answered
                                              ? null
                                              : () {
                                            setState(() {
                                              selectedRadio = index;
                                              answered = true;
                                              timeTaken = DateTime.now()
                                                  .difference(questionStartTime!)
                                                  .inMilliseconds;
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),

                              if(!widget.isHost)
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

                              //Stop Button for Host
                              if(widget.isHost)
                                ...[
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Stop Quiz"),
                                          content: const Text("Are you sure you want to stop the quiz?"),
                                          actions: [
                                            //Cancle Button
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("Cancel"),
                                            ),

                                            //Stop Button
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: (){
                                                print("Stop Pressed");
                                                print("Calling stopQuiz from ongoing_room");
                                                SocketService().stopQuiz(gameSessionProvider.gameSession!.id);
                                              },
                                              child: const Text("Confirm"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text("Stop Quiz"),
                                  )
                                ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
        )
    );
  }

  // Leaderboard builder
  Widget leaderBoardBuilder(List<LeaderboardEntry> leaderboard) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏆 Leaderboard"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final participant = leaderboard[index];

          Color tileColor;
          switch (participant.rank) {
            case 1:
              tileColor = Colors.amber.shade200; // Gold
              break;
            case 2:
              tileColor = Colors.grey.shade300; // Silver
              break;
            case 3:
              tileColor = Colors.brown.shade200; // Bronze
              break;
            default:
              tileColor = Colors.white;
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: tileColor,
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple,
                child: Text(
                  participant.rank.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                participant.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text("Correct: ${participant.correctAnswers}"),
                  const SizedBox(width: 10),
                  Icon(Icons.timer, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text("${participant.avgResponseTime.toStringAsFixed(1)}s"),
                ],
              ),
              trailing: Text(
                "${participant.score} pts",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}