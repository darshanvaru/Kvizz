// lib/screens/ongoing_quiz_screen.dart
// Full replacement — ready to paste.

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/Question.dart';
import '../models/game_session_model.dart';
import '../providers/game_session_provider.dart';
import '../providers/tab_index_provider.dart';
import '../providers/user_provider.dart';       // <-- your existing user provider
import '../services/socket_service.dart';

class OngoingQuizScreen extends StatefulWidget {
  final List<QuestionModel> questions;   // fallback / single-player list
  final bool isMultiplayer;
  final String? gameSessionId;

  const OngoingQuizScreen({
    Key? key,
    required this.questions,
    this.isMultiplayer = false,
    this.gameSessionId,
  }) : super(key: key);

  @override
  State<OngoingQuizScreen> createState() => _OngoingQuizScreenState();
}

class _OngoingQuizScreenState extends State<OngoingQuizScreen>
    with TickerProviderStateMixin {
  late List<QuestionModel> _quizQuestions;

  // quiz state
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  bool timeUp = false;
  bool? lastAnswerCorrect;

  // answer helpers
  Set<int> selectedIndexes = {};
  int? selectedRadio;
  TextEditingController answerController = TextEditingController();
  List<MapEntry<int, String>> reorderedOptions = [];

  // timing
  Timer? timer;
  int timeLeft = 10;
  DateTime? questionStartTime;
  int timeTaken = 0;

  // services
  final SocketService _socket = SocketService();

  @override
  void initState() {
    super.initState();
    _initialiseQuiz();
  }

  /* ────────────────────────────────────────────────────────────
     INITIALISATION
  ──────────────────────────────────────────────────────────── */
  void _initialiseQuiz() {
    if (widget.isMultiplayer) {
      final gs = Provider.of<GameSessionProvider>(context, listen: false);
      if (gs.hasSession && gs.quizData != null) {
        _quizQuestions =
            gs.quizData!.questions.map(_qToQuestionModel).toList();
      } else {
        _quizQuestions = widget.questions;
      }
    } else {
      _quizQuestions = widget.questions;
    }
    _prepareQuestion();
  }

  QuestionModel _qToQuestionModel(QuizQuestion q) => QuestionModel(
    id: q.id,
    type: _stringToType(q.type),
    question: q.question,
    options: q.options,
    correctAnswer: q.correctAnswer,
    createdAt: DateTime.now(),
  );

  QuestionType _stringToType(String raw) {
    switch (raw.toLowerCase()) {
      case 'single':
        return QuestionType.single;
      case 'multiple':
        return QuestionType.multiple;
      case 'open':
        return QuestionType.open;
      case 'reorder':
        return QuestionType.reorder;
      case 'truefalse':
      case 'true-false':
        return QuestionType.trueFalse;
      default:
        return QuestionType.multiple;
    }
  }

  /* ────────────────────────────────────────────────────────────
     QUESTION PREP / TIMER
  ──────────────────────────────────────────────────────────── */
  void _prepareQuestion() {
    timer?.cancel();

    setState(() {
      answered = false;
      timeUp = false;
      lastAnswerCorrect = null;
      selectedIndexes.clear();
      selectedRadio = null;
      answerController.clear();
      reorderedOptions = [];

      timeLeft = _initialTimeForQuestion();
      questionStartTime = DateTime.now();
      timeTaken = 0;

      if (_currentQuestion.type == QuestionType.reorder) {
        reorderedOptions = _currentQuestion.options
            .asMap()
            .entries
            .map((e) => MapEntry(e.key, e.value))
            .toList();
      }
    });

    _startTimer();
  }

  int _initialTimeForQuestion() {
    if (!widget.isMultiplayer) return 10;

    final gs = Provider.of<GameSessionProvider>(context, listen: false);
    // prefer precise endTime – otherwise settings – otherwise 10
    if (gs.currentQuestion != null) {
      final seconds =
          gs.currentQuestion!.endTime.difference(DateTime.now()).inSeconds;
      return seconds > 0 ? seconds : 10;
    }
    if (gs.settings != null) return gs.settings!.timePerQuestion;
    return 10;
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
        if (timeLeft == 0) {
          setState(() {
            timeUp = true;
            _submitAnswer();
          });
        }
      } else {
        t.cancel();
      }
    });
  }

  /* ────────────────────────────────────────────────────────────
     ANSWER SUBMISSION
  ──────────────────────────────────────────────────────────── */
  void _submitAnswer() {
    final q = _currentQuestion;
    bool isCorrect = false;
    dynamic userAnswer;

    switch (q.type) {
      case QuestionType.single:
        userAnswer = selectedRadio?.toString() ?? '';
        isCorrect = q.options[selectedRadio ?? 0] == q.correctAnswer.first;
        break;

      case QuestionType.multiple:
        userAnswer = selectedIndexes.map((i) => i.toString()).toList();
        isCorrect = selectedIndexes.length == q.correctAnswer.length &&
            selectedIndexes.every((i) => q.correctAnswer.contains(q.options[i]));
        break;

      case QuestionType.open:
        userAnswer = answerController.text.trim();
        isCorrect = q.correctAnswer.contains(userAnswer);
        break;

      case QuestionType.reorder:
        userAnswer = reorderedOptions.map((e) => e.value).toList();
        isCorrect = const ListEquality().equals(
            userAnswer, q.correctAnswer);
        break;

      case QuestionType.trueFalse:
        userAnswer = selectedRadio == 0 ? 'false' : 'true';
        isCorrect = userAnswer == q.correctAnswer.first.toLowerCase();
        break;
    }

    timeTaken = DateTime.now().difference(questionStartTime!).inMilliseconds;

    if (widget.isMultiplayer) {
      final gs = Provider.of<GameSessionProvider>(context, listen: false);
      final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.id??'';
      if (gs.hasSession) {
        _socket.submitAnswer(
          gameSessionId: gs.gameSession!.id,
          userId: userId,
          questionId: q.id,
          answer: userAnswer,
          isCorrect: isCorrect,
          timeTaken: timeTaken,
        );
      }
    } else {
      if (isCorrect) score++;
      Future.delayed(const Duration(seconds: 3), _nextQuestion);
    }

    setState(() {
      answered = true;
      lastAnswerCorrect = isCorrect;
    });
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() => currentIndex++);
    if (currentIndex < _quizQuestions.length) {
      _prepareQuestion();
    }
  }

  /* ────────────────────────────────────────────────────────────
     GETTERS
  ──────────────────────────────────────────────────────────── */
  QuestionModel get _currentQuestion => _quizQuestions[currentIndex];

  /* ────────────────────────────────────────────────────────────
     UI BUILD
  ──────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) =>
      widget.isMultiplayer ? _buildMulti() : _buildSingle();

  /* ---------- Multiplayer wrapper ---------- */
  Widget _buildMulti() {
    return Consumer<GameSessionProvider>(
      builder: (_, gs, __) {
        if (!gs.hasSession) return _scaffoldCenter('Joining game...');
        if (gs.isWaiting) return _scaffoldCenter('Waiting for host...');
        if (gs.isFinished) return _leaderBoard(gs);
        if (gs.isStarted) return _quizScaffold(gs);
        return _scaffoldCenter('Loading...');
      },
    );
  }

  /* ---------- Single-player wrapper ---------- */
  Widget _buildSingle() {
    if (currentIndex >= _quizQuestions.length) {
      return _singleResult();
    }
    return _quizScaffold(null);
  }

  /* ---------- QUIZ SCAFFOLD (shared) ---------- */
  Widget _quizScaffold(GameSessionProvider? gs) {
    final total = _quizQuestions.length;
    final qLabel = widget.isMultiplayer
        ? 'Q ${_serverProgress(gs!)}/$total'
        : 'Q ${currentIndex + 1}/$total';

    return Scaffold(
      appBar: AppBar(title: Text(qLabel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _timerBar(),
          const SizedBox(height: 16),
          _questionCard(),
        ],
      ),
    );
  }

  /* ---------- TIMER WIDGET ---------- */
  Widget _timerBar() {
    final total = widget.isMultiplayer ? _initialTimeForQuestion() : 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                value: timeLeft / total,
                strokeWidth: 4,
                valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF53BDEB)),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            Text('$timeLeft',
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        )
      ],
    );
  }

  /* ---------- QUESTION CARD + OPTIONS ---------- */
  Widget _questionCard() {
    final q = _currentQuestion;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.question,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ..._optionWidgets(q),
            if (answered && timeUp) _answerBanner(),
          ],
        ),
      ),
    );
  }

  /* ---------- OPTION BUILDERS ---------- */
  List<Widget> _optionWidgets(QuestionModel q) {
    switch (q.type) {
      case QuestionType.single:
        return List.generate(q.options.length, (i) => _singleTile(q, i));
      case QuestionType.multiple:
        return [
          ...List.generate(q.options.length, (i) => _multiTile(q, i)),
          const SizedBox(height: 12),
          if (!answered && !timeUp)
            _submitButton(disabled: selectedIndexes.isEmpty),
        ];
      case QuestionType.open:
        return [
          TextField(
            controller: answerController,
            maxLines: 3,
            enabled: !answered && !timeUp,
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          if (!answered && !timeUp) _submitButton(),
        ];
      case QuestionType.reorder:
        return [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: answered || timeUp
                ? (_, __) {}
                : (o, n) {
              setState(() {
                if (n > o) n -= 1;
                final item = reorderedOptions.removeAt(o);
                reorderedOptions.insert(n, item);
              });
            },
            itemCount: reorderedOptions.length,
            itemBuilder: (_, i) {
              final entry = reorderedOptions[i];
              return ListTile(
                key: ValueKey(entry.key),
                title: Text(entry.value),
                tileColor: Colors.grey.shade100,
                trailing:
                answered || timeUp ? const SizedBox() : const Icon(Icons.drag_handle),
              );
            },
          ),
          const SizedBox(height: 12),
          if (!answered && !timeUp) _submitButton(),
        ];
      case QuestionType.trueFalse:
        return List.generate(2, (i) => _trueFalseTile(q, i));
    }
  }

  /* ---------- TILE HELPERS ---------- */
  Widget _singleTile(QuestionModel q, int i) {
    final sel = selectedRadio == i;
    final correct = q.options[i] == q.correctAnswer.first;
    final incorrect = answered && sel && !correct;
    Color border = Colors.grey.shade300;
    Color textCol = Colors.black87;
    Icon leading = const Icon(Icons.circle_outlined, color: Colors.grey);

    if (timeUp) {
      if (correct) {
        border = Colors.teal;
        leading = const Icon(Icons.check_circle, color: Colors.teal);
        textCol = Colors.teal;
      } else if (incorrect) {
        border = Colors.redAccent;
        leading = const Icon(Icons.cancel, color: Colors.redAccent);
        textCol = Colors.redAccent;
      }
    } else if (!timeUp && sel) {
      border = const Color(0xFF53BDEB);
      leading = const Icon(Icons.circle, color: Color(0xFF53BDEB));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: leading,
        title: Text(q.options[i], style: TextStyle(color: textCol)),
        onTap: answered
            ? null
            : () {
          setState(() => selectedRadio = i);
          answered = true;
          _submitAnswer();
        },
      ),
    );
  }

  Widget _multiTile(QuestionModel q, int i) {
    final sel = selectedIndexes.contains(i);
    final correct = (answered || timeUp) && q.correctAnswer.contains(q.options[i]);
    final incorrect = (answered || timeUp) && sel && !correct;
    Color border = Colors.grey.shade300;
    Color textCol = Colors.black87;
    if (correct) {
      border = Colors.teal;
      textCol = Colors.teal;
    } else if (incorrect) {
      border = Colors.redAccent;
      textCol = Colors.redAccent;
    } else if (sel) {
      border = const Color(0xFF53BDEB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: sel,
        title: Text(q.options[i], style: TextStyle(color: textCol)),
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: answered || timeUp
            ? null
            : (v) {
          setState(() {
            v! ? selectedIndexes.add(i) : selectedIndexes.remove(i);
          });
        },
      ),
    );
  }

  Widget _trueFalseTile(QuestionModel q, int i) {
    final sel = selectedRadio == i;
    final correctAnsIdx =
    q.correctAnswer.first.toLowerCase() == 'true' ? 1 : 0;
    final correct = answered && i == correctAnsIdx;
    final incorrect = answered && sel && !correct;
    Color border = Colors.grey.shade300;
    Color textCol = Colors.black87;
    Icon leading = const Icon(Icons.circle_outlined, color: Colors.grey);

    if (correct) {
      border = Colors.teal;
      leading = const Icon(Icons.check_circle, color: Colors.teal);
      textCol = Colors.teal;
    } else if (incorrect) {
      border = Colors.redAccent;
      leading = const Icon(Icons.cancel, color: Colors.redAccent);
      textCol = Colors.redAccent;
    } else if (sel) {
      border = const Color(0xFF53BDEB);
      leading = const Icon(Icons.circle, color: Color(0xFF53BDEB));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: leading,
        title: Text(i == 1 ? 'True' : 'False', style: TextStyle(color: textCol)),
        onTap: answered
            ? null
            : () {
          setState(() => selectedRadio = i);
          answered = true;
          _submitAnswer();
        },
      ),
    );
  }

  Widget _submitButton({bool disabled = false}) => ElevatedButton(
    onPressed: disabled ? null : _submitAnswer,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: const Color(0xFF53BDEB),
    ),
    child: const Text('Submit'),
  );

  Widget _answerBanner() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      children: [
        Icon(
          lastAnswerCorrect == true ? Icons.check_circle : Icons.cancel,
          color: lastAnswerCorrect == true ? Colors.teal : Colors.redAccent,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          lastAnswerCorrect == true ? 'Correct!' : 'Incorrect!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
            lastAnswerCorrect == true ? Colors.teal : Colors.redAccent,
          ),
        ),
      ],
    ),
  );

  /* ────────────────────────────────────────────────────────────
     RESULTS & LEADERBOARD
  ──────────────────────────────────────────────────────────── */
  Widget _leaderBoard(GameSessionProvider gs) {
    final entries = gs.leaderboard;
    entries.sort((a, b) => a.rank.compareTo(b.rank));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(e.rank.toString()),
                    backgroundColor: i == 0 ? Colors.amber : null,
                  ),
                  title: Text(e.username),
                  trailing: Text('${e.score} pts'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Return to Dashboard'),
              onPressed: () {
                // clear provider & navigate
                gs.clearSession();
                Navigator.of(context).popUntil((r) => r.isFirst);
                Provider.of<SelectedIndexProvider>(context, listen: false)
                    .updateSelectedIndex(0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _singleResult() => Scaffold(
    appBar: AppBar(title: const Text('Result')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Score: $score / ${_quizQuestions.length}',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Return Home'),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Provider.of<SelectedIndexProvider>(context, listen: false)
                  .updateSelectedIndex(0);
            },
          ),
        ],
      ),
    ),
  );

  /* ────────────────────────────────────────────────────────────
     HELPERS
  ──────────────────────────────────────────────────────────── */
  int _serverProgress(GameSessionProvider gs) {
    if (gs.currentQuestion == null) return currentIndex + 1;
    final qId = gs.currentQuestion!.questionId;
    return _quizQuestions.indexWhere((q) => q.id == qId) + 1;
  }

  Widget _scaffoldCenter(String msg) => Scaffold(
    body: Center(child: Text(msg)),
  );

  @override
  void dispose() {
    timer?.cancel();
    answerController.dispose();
    super.dispose();
  }
}
