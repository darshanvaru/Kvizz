// import 'package:collection/collection.dart';
// import 'package:flutter/material.dart';
// import 'package:kvizz/models/Question.dart';
// import '../enums/enums.dart';
//
// class QuizPreviewScreen extends StatefulWidget {
//   final List questions;
//   final int maxPointsPerQuestion = 1;
//
//   const QuizPreviewScreen({
//     super.key,
//     required this.questions,
//   });
//
//   @override
//   State createState() => _QuizPreviewScreenState();
// }
//
// class _QuizPreviewScreenState extends State<QuizPreviewScreen> with TickerProviderStateMixin {
//   late List questions;
//   int currentQuestionIndex = 0;
//
//   bool answered = false;
//   int score = 0;
//   bool? lastAnswerCorrect;
//
//   Set<int> selectedIndexes = {};
//   int? selectedRadio;
//   TextEditingController answerController = TextEditingController();
//   List<MapEntry<int, String>> reorderedOptions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     questions = widget.questions;
//     _prepareQuestion();
//   }
//
//   void _prepareQuestion() {
//     final question = questions[currentQuestionIndex];
//
//     setState(() {
//       answered = false;
//       lastAnswerCorrect = null;
//       selectedIndexes.clear();
//       selectedRadio = null;
//       answerController.clear();
//       reorderedOptions = [];
//
//       if (question.type == QuestionType.reorder) {
//         reorderedOptions = question.options.asMap().entries.toList();
//       }
//     });
//   }
//
//   void submitAnswer() {
//     final question = questions[currentQuestionIndex];
//     bool isCorrect = false;
//     int pointsAwarded = 0;
//
//     List<String>? answerList = [];
//
//     switch (question.type) {
//       case QuestionType.single:
//         if (selectedRadio == null) return; // prevent submit without selection
//         isCorrect = question.options[selectedRadio!] == question.correctAnswer.first;
//         pointsAwarded = isCorrect ? widget.maxPointsPerQuestion : 0;
//         answerList = [question.options[selectedRadio!]];
//         break;
//
//       case QuestionType.multiple:
//         isCorrect = selectedIndexes.length == question.correctAnswer.length &&
//             selectedIndexes.every((i) => question.correctAnswer.contains(question.options[i]));
//         pointsAwarded = isCorrect ? widget.maxPointsPerQuestion : 0;
//         answerList = selectedIndexes.map((i) => question.options[i]).cast<String>().toList();
//         break;
//
//       case QuestionType.open:
//         final answer = answerController.text.trim();
//         if (answer.isEmpty) return;
//         isCorrect = question.correctAnswer.contains(answer);
//         pointsAwarded = isCorrect ? widget.maxPointsPerQuestion : 0;
//         answerList = [answer];
//         break;
//
//       case QuestionType.reorder:
//         List<String> userOrder = reorderedOptions.map((e) => e.value).toList();
//         List<String> correctOrder = question.correctAnswer;
//         final eq = const ListEquality().equals;
//         isCorrect = eq(userOrder, correctOrder);
//         pointsAwarded = isCorrect ? widget.maxPointsPerQuestion : 0;
//         answerList = userOrder;
//         break;
//
//       case QuestionType.trueFalse:
//         if (selectedRadio == null) return;
//         final selectedLabel = selectedRadio == 0 ? 'true' : 'false';
//         isCorrect = selectedLabel == question.correctAnswer.first.toLowerCase();
//         pointsAwarded = isCorrect ? widget.maxPointsPerQuestion : 0;
//         answerList = [selectedLabel];
//         break;
//     }
//
//     setState(() {
//       score += pointsAwarded;
//       lastAnswerCorrect = isCorrect;
//       answered = true;
//     });
//
//     // Optionally, handle socket submission:
//     // SocketService().submitAnswer(...);
//
//     // Do NOT auto advance in preview
//   }
//
//   void _nextQuestion() {
//     if (currentQuestionIndex < questions.length - 1) {
//       setState(() {
//         currentQuestionIndex++;
//       });
//       _prepareQuestion();
//     }
//   }
//
//   void _previousQuestion() {
//     if (currentQuestionIndex > 0) {
//       setState(() {
//         currentQuestionIndex--;
//       });
//       _prepareQuestion();
//     }
//   }
//
//   @override
//   void dispose() {
//     answerController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final question = questions[currentQuestionIndex];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Quiz Preview"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.exit_to_app),
//             tooltip: 'Exit Preview',
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text("${currentQuestionIndex + 1} / ${questions.length}",
//                   textAlign: TextAlign.right),
//               const SizedBox(height: 8),
//               Text(
//                 question.question,
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//
//               // Render question UI exactly like OngoingQuizScreen (reuse or replicate)
//
//               /// Example for single choice for brevity; replicate other types accordingly
//               if (question.type == QuestionType.single)
//                 Column(
//                   children: List.generate(question.options.length, (index) {
//                     final option = question.options[index];
//                     final isCorrect = option == question.correctAnswer.first;
//
//                     Color? tileColor;
//                     Color borderColor = Colors.grey.shade300;
//                     Icon leadingIcon = const Icon(Icons.circle_outlined, color: Colors.grey);
//                     Color optionTextColor = Colors.black54;
//
//                     if (answered) {
//                       if (isCorrect) {
//                         tileColor = const Color(0xFFD6F4E7);
//                         borderColor = Colors.teal;
//                         leadingIcon = const Icon(Icons.check_circle, color: Colors.teal);
//                         optionTextColor = Colors.teal;
//                       } else if (selectedRadio == index && !isCorrect) {
//                         tileColor = const Color(0xFFFBE4DF);
//                         borderColor = Colors.redAccent;
//                         leadingIcon = const Icon(Icons.cancel, color: Colors.redAccent);
//                         optionTextColor = Colors.redAccent;
//                       }
//                     }
//
//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       decoration: BoxDecoration(
//                         color: tileColor ?? Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: borderColor, width: 1),
//                       ),
//                       child: ListTile(
//                         leading: Radio<int>(
//                           value: index,
//                           groupValue: selectedRadio,
//                           onChanged: answered
//                               ? null
//                               : (val) {
//                             setState(() {
//                               selectedRadio = val;
//                             });
//                           },
//                         ),
//                         title: Text(option,
//                             style: TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 color: optionTextColor)),
//                       ),
//                     );
//                   }),
//                 ),
//
//               // Show Submit button if not answered yet
//               if (!answered)
//                 ElevatedButton(
//                   onPressed: () {
//                     submitAnswer();
//                   },
//                   child: const Text("Submit Answer"),
//                 ),
//
//               if (answered && lastAnswerCorrect != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 12),
//                   child: Row(
//                     children: [
//                       Icon(
//                         lastAnswerCorrect == true ? Icons.check_circle : Icons.cancel,
//                         color: lastAnswerCorrect == true ? Colors.teal : Colors.redAccent,
//                         size: 28,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         lastAnswerCorrect == true ? "Correct!" : "Incorrect!",
//                         style: TextStyle(
//                             color: lastAnswerCorrect == true ? Colors.teal : Colors.redAccent,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18),
//                       ),
//                     ],
//                   ),
//                 ),
//
//               const SizedBox(height: 24),
//
//               // Navigation buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   ElevatedButton.icon(
//                       onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
//                       icon: const Icon(Icons.arrow_back),
//                       label: const Text("Previous")),
//                   ElevatedButton.icon(
//                       onPressed: currentQuestionIndex < questions.length - 1 ? _nextQuestion : null,
//                       icon: const Icon(Icons.arrow_forward),
//                       label: const Text("Next")),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
