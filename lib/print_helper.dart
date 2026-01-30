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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final question = questions[currentQuestionIndex];

    // Theme-aware colors
    final backgroundColor = colorScheme.surface;
    final cardColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurface;
    final subtleTextColor = colorScheme.onSurfaceVariant;
    final primaryColor = colorScheme.primary;
    final progressBarBackground = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.primaryContainer.withOpacity(0.3);
    final correctColor = isDark ? Colors.green.shade400 : Colors.teal;
    final incorrectColor = isDark ? Colors.red.shade400 : Colors.redAccent;
    final optionBorderColor = isDark
        ? colorScheme.outline.withOpacity(0.5)
        : colorScheme.outlineVariant;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: progressBarBackground,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.3 : 0.05,
                                    ),
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
                              height: 12,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Top Row with Exit Button and Question Numbering
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.3 : 0.08,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close_rounded,
                                color: subtleTextColor,
                                size: 26,
                              ),
                              padding: const EdgeInsets.all(10),
                              tooltip: "Exit",
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              "${currentQuestionIndex + 1}/${questions.length}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getQuestionTypeLabel(question.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Question Text
                            Text(
                              question.question,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Media Display
                            if (question.media != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    question.media!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color:
                                                    colorScheme.errorContainer,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: colorScheme.error,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Failed to load media",
                                                    style: TextStyle(
                                                      color: colorScheme.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Answer Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Single Choice Questions
                            if (question.type == QuestionType.single)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...question.options.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final option = entry.value;
                                    final isCorrect =
                                        answered &&
                                        index.toString() ==
                                            question.correctAnswer.first;
                                    final isSelected = selectedRadio == index;
                                    final isIncorrect =
                                        answered && isSelected && !isCorrect;

                                    Color tileColor;
                                    Color borderColor;
                                    Icon leadingIcon;
                                    Color optionTextColor;

                                    if (answered) {
                                      if (isCorrect) {
                                        tileColor = correctColor.withOpacity(
                                          0.15,
                                        );
                                        borderColor = correctColor;
                                        leadingIcon = Icon(
                                          Icons.check_circle,
                                          color: correctColor,
                                        );
                                        optionTextColor = correctColor;
                                      } else if (isIncorrect) {
                                        tileColor = incorrectColor.withOpacity(
                                          0.15,
                                        );
                                        borderColor = incorrectColor;
                                        leadingIcon = Icon(
                                          Icons.cancel,
                                          color: incorrectColor,
                                        );
                                        optionTextColor = incorrectColor;
                                      } else {
                                        tileColor = cardColor;
                                        borderColor = optionBorderColor;
                                        leadingIcon = Icon(
                                          Icons.circle_outlined,
                                          color: subtleTextColor,
                                        );
                                        optionTextColor = subtleTextColor;
                                      }
                                    } else {
                                      tileColor = isSelected
                                          ? primaryColor.withOpacity(0.1)
                                          : cardColor;
                                      borderColor = isSelected
                                          ? primaryColor
                                          : optionBorderColor;
                                      leadingIcon = Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? primaryColor
                                            : subtleTextColor,
                                      );
                                      optionTextColor = isSelected
                                          ? primaryColor
                                          : textColor;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: tileColor,
                                        border: Border.all(
                                          color: borderColor,
                                          width:
                                              (isCorrect ||
                                                  isIncorrect ||
                                                  isSelected)
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: leadingIcon,
                                        title: Text(
                                          option,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: optionTextColor,
                                          ),
                                        ),
                                        onTap: answered
                                            ? null
                                            : () => setState(() {
                                                selectedRadio = index;
                                              }),
                                      ),
                                    );
                                  }),
                                ],
                              ),

                            // Multiple Choice Questions
                            if (question.type == QuestionType.multiple)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...question.options.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final option = entry.value;
                                    final isCorrect =
                                        answered &&
                                        question.correctAnswer.contains(
                                          index.toString(),
                                        );
                                    final isSelected = selectedIndexes.contains(
                                      index,
                                    );
                                    final isIncorrect =
                                        answered && isSelected && !isCorrect;

                                    Color tileColor;
                                    Color borderColor;
                                    Icon leadingIcon;
                                    Color optionTextColor;

                                    if (answered) {
                                      if (isCorrect) {
                                        tileColor = correctColor.withOpacity(
                                          0.15,
                                        );
                                        borderColor = correctColor;
                                        leadingIcon = Icon(
                                          Icons.check_circle,
                                          color: correctColor,
                                        );
                                        optionTextColor = correctColor;
                                      } else if (isIncorrect) {
                                        tileColor = incorrectColor.withOpacity(
                                          0.15,
                                        );
                                        borderColor = incorrectColor;
                                        leadingIcon = Icon(
                                          Icons.cancel,
                                          color: incorrectColor,
                                        );
                                        optionTextColor = incorrectColor;
                                      } else {
                                        tileColor = cardColor;
                                        borderColor = optionBorderColor;
                                        leadingIcon = Icon(
                                          Icons.check_box_outline_blank,
                                          color: subtleTextColor,
                                        );
                                        optionTextColor = subtleTextColor;
                                      }
                                    } else {
                                      tileColor = isSelected
                                          ? primaryColor.withOpacity(0.1)
                                          : cardColor;
                                      borderColor = isSelected
                                          ? primaryColor
                                          : optionBorderColor;
                                      leadingIcon = Icon(
                                        isSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: isSelected
                                            ? primaryColor
                                            : subtleTextColor,
                                      );
                                      optionTextColor = isSelected
                                          ? primaryColor
                                          : textColor;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: tileColor,
                                        border: Border.all(
                                          color: borderColor,
                                          width:
                                              (isCorrect ||
                                                  isIncorrect ||
                                                  isSelected)
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: leadingIcon,
                                        title: Text(
                                          option,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: optionTextColor,
                                          ),
                                        ),
                                        onTap: answered
                                            ? null
                                            : () {
                                                setState(() {
                                                  if (selectedIndexes.contains(
                                                    index,
                                                  )) {
                                                    selectedIndexes.remove(
                                                      index,
                                                    );
                                                  } else {
                                                    selectedIndexes.add(index);
                                                  }
                                                });
                                              },
                                      ),
                                    );
                                  }),
                                ],
                              ),

                            // Open-ended Questions
                            if (question.type == QuestionType.open)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: answerController,
                                    enabled: !answered,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Type your answer here...",
                                      hintStyle: TextStyle(
                                        color: subtleTextColor,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? colorScheme.surfaceContainer
                                          : colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: optionBorderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: optionBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: optionBorderColor.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    maxLines: 3,
                                  ),
                                  if (answered)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: correctColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: correctColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline,
                                              color: correctColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Correct answer(s): ${question.correctAnswer.join(', ')}",
                                                style: TextStyle(
                                                  color: correctColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                            // Reorder Questions
                            if (question.type == QuestionType.reorder)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ReorderableListView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    onReorder: answered
                                        ? (_, __) {}
                                        : (oldIndex, newIndex) {
                                            setState(() {
                                              if (newIndex > oldIndex) {
                                                newIndex -= 1;
                                              }
                                              final item = reorderedOptions
                                                  .removeAt(oldIndex);
                                              reorderedOptions.insert(
                                                newIndex,
                                                item,
                                              );
                                            });
                                          },
                                    children: reorderedOptions.map((entry) {
                                      final index = reorderedOptions.indexOf(
                                        entry,
                                      );
                                      final originalIndex = entry.key;
                                      final isCorrect =
                                          answered &&
                                          index.toString() ==
                                              question
                                                  .correctAnswer[originalIndex];

                                      Color tileColor;
                                      Color borderColor;
                                      Color optionTextColor;

                                      if (answered) {
                                        if (isCorrect) {
                                          tileColor = correctColor.withOpacity(
                                            0.15,
                                          );
                                          borderColor = correctColor;
                                          optionTextColor = correctColor;
                                        } else {
                                          tileColor = incorrectColor
                                              .withOpacity(0.15);
                                          borderColor = incorrectColor;
                                          optionTextColor = incorrectColor;
                                        }
                                      } else {
                                        tileColor = cardColor;
                                        borderColor = optionBorderColor;
                                        optionTextColor = textColor;
                                      }

                                      return Container(
                                        key: ValueKey(entry.key),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tileColor,
                                          border: Border.all(
                                            color: borderColor,
                                            width:
                                                isCorrect ||
                                                    (!isCorrect && answered)
                                                ? 2
                                                : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: answered
                                              ? Icon(
                                                  isCorrect
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: isCorrect
                                                      ? correctColor
                                                      : incorrectColor,
                                                )
                                              : Icon(
                                                  Icons.drag_handle,
                                                  color: subtleTextColor,
                                                ),
                                          title: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: optionTextColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),

                            // True/False Questions
                            if (question.type == QuestionType.trueFalse)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...List.generate(2, (index) {
                                    final isCorrect =
                                        answered &&
                                        index ==
                                            int.parse(
                                              question.correctAnswer.first,
                                            );
                                    final isSelected = selectedRadio == index;
                                    final isIncorrect =
                                        answered && isSelected && !isCorrect;
                                    final label = index == 0 ? "False" : "True";

                                    Color tileColor;
                                    Color borderColor;
                                    Icon leadingIcon;
                                    Color optionTextColor;

                                    if (answered) {
                                      if (isCorrect) {
                                        tileColor = correctColor.withOpacity(
                                          0.15,
                                        );
                                        borderColor = correctColor;
                                        leadingIcon = Icon(
                                          Icons.check_circle,
                                          color: correctColor,
                                        );
                                        optionTextColor = correctColor;
                                      } else if (isIncorrect) {
                                        tileColor = incorrectColor.withOpacity(
                                          0.15,
                                        );
                                        borderColor = incorrectColor;
                                        leadingIcon = Icon(
                                          Icons.cancel,
                                          color: incorrectColor,
                                        );
                                        optionTextColor = incorrectColor;
                                      } else {
                                        tileColor = cardColor;
                                        borderColor = optionBorderColor;
                                        leadingIcon = Icon(
                                          Icons.circle_outlined,
                                          color: subtleTextColor,
                                        );
                                        optionTextColor = subtleTextColor;
                                      }
                                    } else {
                                      tileColor = isSelected
                                          ? primaryColor.withOpacity(0.1)
                                          : cardColor;
                                      borderColor = isSelected
                                          ? primaryColor
                                          : optionBorderColor;
                                      leadingIcon = Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? primaryColor
                                            : subtleTextColor,
                                      );
                                      optionTextColor = isSelected
                                          ? primaryColor
                                          : textColor;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: tileColor,
                                        border: Border.all(
                                          color: borderColor,
                                          width:
                                              (isCorrect ||
                                                  isIncorrect ||
                                                  isSelected)
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

                            // Submit Button for non-auto-submit questions
                            if (!answered &&
                                question.type != QuestionType.trueFalse)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if ((question.type == QuestionType.single &&
                                            selectedRadio != null) ||
                                        (question.type ==
                                                QuestionType.multiple &&
                                            selectedIndexes.isNotEmpty) ||
                                        (question.type == QuestionType.open &&
                                            answerController.text
                                                .trim()
                                                .isNotEmpty) ||
                                        (question.type ==
                                                QuestionType.reorder &&
                                            reorderedOptions.isNotEmpty)) {
                                      submitAnswer();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    "Submit Answer",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            // Feedback Section
                            if (answered && lastAnswerCorrect != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        (lastAnswerCorrect == true
                                                ? correctColor
                                                : incorrectColor)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: lastAnswerCorrect == true
                                          ? correctColor
                                          : incorrectColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        lastAnswerCorrect == true
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 30,
                                        color: lastAnswerCorrect == true
                                            ? correctColor
                                            : incorrectColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lastAnswerCorrect == true
                                                  ? "Correct!"
                                                  : "Incorrect!",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: lastAnswerCorrect == true
                                                    ? correctColor
                                                    : incorrectColor,
                                              ),
                                            ),
                                            if (question.funFact != null &&
                                                question.funFact!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  "💡 ${question.funFact}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: textColor
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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

            // Pinned Navigation Buttons at Bottom
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: currentQuestionIndex > 0
                              ? _previousQuestion
                              : null,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                          label: const Text("Previous"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentQuestionIndex > 0
                                ? primaryColor
                                : (isDark
                                      ? colorScheme.surfaceContainerHighest
                                      : colorScheme.surfaceContainerHigh),
                            foregroundColor: currentQuestionIndex > 0
                                ? colorScheme.onPrimary
                                : subtleTextColor,
                            elevation: currentQuestionIndex > 0 ? 4 : 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: currentQuestionIndex < questions.length - 1
                              ? _nextQuestion
                              : null,
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20,
                          ),
                          label: const Text("Next"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentQuestionIndex < questions.length - 1
                                ? primaryColor
                                : (isDark
                                      ? colorScheme.surfaceContainerHighest
                                      : colorScheme.surfaceContainerHigh),
                            foregroundColor:
                                currentQuestionIndex < questions.length - 1
                                ? colorScheme.onPrimary
                                : subtleTextColor,
                            elevation:
                                currentQuestionIndex < questions.length - 1
                                ? 4
                                : 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return "SINGLE CHOICE";
      case QuestionType.multiple:
        return "MULTIPLE CHOICE";
      case QuestionType.open:
        return "OPEN ENDED";
      case QuestionType.reorder:
        return "REORDER";
      case QuestionType.trueFalse:
        return "TRUE/FALSE";
    }
  }
}
