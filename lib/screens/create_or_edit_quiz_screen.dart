import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kvizz/print_helper.dart';

import '../models/quiz_model.dart';
import '../models/question_model.dart';

import '../enums/enums.dart';
import '../providers/user_provider.dart';

import '../services/quiz_service.dart';

import '../widgets/question_types_widgets/multiple_choice_question_widget.dart';
import '../widgets/question_types_widgets/open_ended_question_widget.dart';
import '../widgets/question_types_widgets/reorderable_question_widget.dart';
import '../widgets/question_types_widgets/single_choice_question_widget.dart';
import '../widgets/question_types_widgets/true_false_question_widget.dart';

class CreateOrEditQuizScreen extends StatefulWidget {
  final String? quizId;

  const CreateOrEditQuizScreen({super.key, this.quizId});

  @override
  CreateOrEditQuizScreenState createState() => CreateOrEditQuizScreenState();
}

class CreateOrEditQuizScreenState extends State<CreateOrEditQuizScreen> {

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController(); // New controller for tags

  // Add FocusNodes for better keyboard management
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _tagsFocusNode = FocusNode();

  // Form state variables
  String _selectedDifficulty = 'medium';
  List<String> _tags = [];
  List<QuestionModel> _questions = [];

  // UI state
  bool _isLoading = false;
  bool _isEditMode = false;

  QuizModel? _existingQuiz;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.quizId != null;
    if (_isEditMode) {
      _loadExistingQuiz();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose(); // Dispose new controller

    // Dispose focus nodes
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _tagsFocusNode.dispose();

    super.dispose();
  }

  // Method to dismiss keyboard and unfocus all fields
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Load existing quiz data for editing
  Future<void> _loadExistingQuiz() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _existingQuiz = await fetchQuizById(widget.quizId ?? '');
      if (_existingQuiz != null) {
        _prefillFormFields();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Prefill form fields with existing quiz data
  void _prefillFormFields() {
    if (_existingQuiz == null) return;
    setState(() {
      _titleController.text = _existingQuiz!.title;
      _descriptionController.text = _existingQuiz!.description;
      _selectedDifficulty = _existingQuiz!.difficulty;
      _tags = List.from(_existingQuiz!.tags);
      _tagsController.text = _tags.join(', '); // Convert tags list to comma-separated string
      _questions = List.from(_existingQuiz!.questions);
    });
  }

  // Process tags input (convert comma-separated string to list)
  void _processTags() {
    final tagsText = _tagsController.text.trim();
    if (tagsText.isNotEmpty) {
      _tags = tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } else {
      _tags = [];
    }
  }

  // Save quiz (create or update)
  Future<void> _saveQuiz() async {
    print("[From CreateOrEditQuizScreen._saveQuiz] Saving quiz with ID: ${_isEditMode ? widget.quizId : 'new'}");

    print("[From CreateOrEditQuizScreen._saveQuiz] Validating quiz data...0");
    if (_questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one question')),
        );
      }
      return;
    }

    print("[From CreateOrEditQuizScreen._saveQuiz] Validating quiz data...1");
    if (_titleController.text.trim().isEmpty) {
      return _showError("Title can't be empty.");
    }

    print("[From CreateOrEditQuizScreen._saveQuiz] Validating quiz data...2");
    for (var q in _questions) {
      if (q.question.trim().isEmpty) {
        return _showError('Each question must have text.');
      }

      switch (q.type) {
        case QuestionType.single:
        case QuestionType.multiple:
          if (q.options.length < 2 ||
              q.options.any((o) => o.trim().isEmpty) ||
              q.correctAnswer.isEmpty) {
            return _showError('Fix options for "${q.question}".');
          }
          break;
        case QuestionType.open:
          if (q.correctAnswer.isEmpty) {
            return _showError('Open-ended question "${q.question}" needs answers.');
          }
          break;
        case QuestionType.reorder:
          if (q.options.length < 3) {
            return _showError('Reorder question "${q.question}" needs at least 3 options.');
          }
          break;
        case QuestionType.trueFalse:
          if (!(q.correctAnswer.first == '0' || q.correctAnswer.first == '1')) {
            return _showError('True/False question "${q.question}" needs valid answer.');
          }
          break;
      }
    }

    print("[From CreateOrEditQuizScreen._saveQuiz] Validating quiz data...3");


    if (!_isEditMode) {
      for (var q in _questions) {
        if (q.type == QuestionType.reorder) {
          print("Shuffling options of reorder question: ${q.question}");
          List<String> tempCorrectAnswer = [...q.options];

          q.options.shuffle();

          List<String> tempCorrectAnswerIndex = [];
          for (var val in tempCorrectAnswer) {
            tempCorrectAnswerIndex.add("${q.options.indexOf(val)}");
          }
          q.correctAnswer = [...tempCorrectAnswerIndex];
        }
      }
    }

    print("[From CreateOrEditQuizScreen._saveQuiz] Validating quiz data...4");

    // Process tags before saving
    _processTags();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    print("[From CreateOrEditQuizScreen._saveQuiz] Saving quiz with ID: ${_isEditMode ? widget.quizId : 'new'}");
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final quizData = QuizModel(
        id: _isEditMode ? widget.quizId! : '', // Server will generate ID for new quiz
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        questions: _questions,
        difficulty: _selectedDifficulty,
        creator: userProvider.currentUser?.id ?? '',
        tags: _tags,
      );

      bool success;
      if (_isEditMode) {
        success = await _updateQuiz(quizData);
      } else {
        success = await _createQuiz(quizData);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Quiz updated successfully!' : 'Quiz created successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Create new quiz
  Future<bool> _createQuiz(QuizModel quiz) async {
    print("Reached CreateOrEditQuizScreen._createQuiz");
    print("[From CreateOrEditQuizScreen._createQuiz] Creating new quiz");

    // Print the API payload for debugging
    printFullResponse("API Body for Quiz Creation ${quiz.toJson(forApi: true)}");

    try {
      // Call the QuizService to create the quiz on the server
      final QuizModel? createdQuiz = await createQuiz(quiz);

      if (createdQuiz != null) {
        print("[From CreateOrEditQuizScreen._createQuiz] Quiz created successfully with ID: ${createdQuiz.id}");

        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return true;
      } else {
        print("[From CreateOrEditQuizScreen._createQuiz] Failed to create quiz - server returned null");
        return false;
      }
    } catch (e) {
      print("[From CreateOrEditQuizScreen._createQuiz] Error creating quiz: $e");
      return false;
    }
  }

  // Update existing quiz
  Future<bool> _updateQuiz(QuizModel quiz) async {
    print("Reached CreateOrEditQuizScreen._updateQuiz");
    print("[From CreateOrEditQuizScreen._updateQuiz] Updating quiz with ID: ${quiz.id}");
    printFullResponse("Quiz Sample: ${quiz.toJson()}");

    try {
      // Call the QuizService to create the quiz on the server
      final QuizModel? updatedQuiz = await updateQuiz(quiz);

      if (updatedQuiz != null) {
        print("[From CreateOrEditQuizScreen._updateQuiz] Quiz Updated successfully of ID: ${updatedQuiz.id}");

        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return true;
      } else {
        print("[From CreateOrEditQuizScreen._updateQuiz] Failed to update quiz - server returned null");
        return false;
      }
    } catch (e) {
      print("[From CreateOrEditQuizScreen._updateQuiz] Error Updating quiz: $e");
      return false;
    }
  }

  // Remove question
  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Widget _buildQuestionWidget(QuestionModel question, int index) {
    switch (question.type) {
      case QuestionType.single:
        return SingleChoiceQuestionWidget(question: question, onDelete: () => _removeQuestion(index));
      case QuestionType.multiple:
        return MultipleChoiceQuestionWidget(question: question, onDelete: () => _removeQuestion(index));
      case QuestionType.open:
        return OpenEndedQuestionWidget(question: question, onDelete: () => _removeQuestion(index));
      case QuestionType.trueFalse:
        return TrueFalseQuestionWidget(question: question, onDelete: () => _removeQuestion(index));
      case QuestionType.reorder:
        return ReorderableQuestionWidget(question: question, onDelete: () => _removeQuestion(index));
    }
  }

  void _showQuestionTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: QuestionType.values.map((type) {
          return ListTile(
            title: Text(type.toString().split('.').last[0].toUpperCase()+type.toString().split('.').last.substring(1)),
            onTap: () {
              Navigator.pop(context);
              _addQuestion(type);
            },
          );
        }).toList(),
      ),
    );
  }

  void _addQuestion(QuestionType type) {
    final newQuestion = QuestionModel(
      id: '',
      question: '',
      options: [],
      correctAnswer: [],
      type: type,
    );
    setState(() => _questions.add(newQuestion));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizId != null ? 'Edit Quiz' : 'Create Quiz'),
        actions: [

          //Save button
          ElevatedButton(
            onPressed: _isLoading ? null : _saveQuiz,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text("Save"), SizedBox(width: 5), Icon(Icons.save)],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: GestureDetector(
        onTap: () => _dismissKeyboard(), // Dismiss keyboard on background tap
        child: SingleChildScrollView( // Made the entire body scrollable
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Quiz basic information form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quiz Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Title TextField
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        decoration: const InputDecoration(
                          labelText: "Quiz Title",
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _titleFocusNode.unfocus();
                          FocusScope.of(context).requestFocus(_descriptionFocusNode);
                        },
                        onTapOutside: (_) => _dismissKeyboard(),
                      ),
                      const SizedBox(height: 16),

                      // Description TextField
                      TextField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _descriptionFocusNode.unfocus();
                          FocusScope.of(context).requestFocus(_tagsFocusNode);
                        },
                        onTapOutside: (_) => _dismissKeyboard(),
                      ),
                      const SizedBox(height: 16),

                      // Difficulty Selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: "Difficulty",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _dismissKeyboard(); // Dismiss keyboard when dropdown changes
                            setState(() {
                              _selectedDifficulty = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tags TextField
                      TextField(
                        controller: _tagsController,
                        focusNode: _tagsFocusNode,
                        decoration: const InputDecoration(
                          labelText: "Tags (comma separated)",
                          hintText: "e.g., science, physics, chemistry",
                          border: OutlineInputBorder(),
                          helperText: "Separate multiple tags with commas",
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          _tagsFocusNode.unfocus();
                          _dismissKeyboard();
                        },
                        onTapOutside: (_) => _dismissKeyboard(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add Question Card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add, color: Colors.green),
                  title: const Text('Add Question'),
                  subtitle: Text('${_questions.length} question(s) added'),
                  onTap: () {
                    _dismissKeyboard();
                    _showQuestionTypePicker();
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Questions List
              if (_questions.isEmpty)
                // No Question Yet widget
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No questions yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap "Add Question" to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Reorderable Questions
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _questions.removeAt(oldIndex);
                      _questions.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      key: Key('${_questions[index].id}_$index'),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [

                              // Drag icon, Question number, question type indicator
                              Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Question ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                        _questions[index].type.toString().split('.').last[0].toUpperCase() +
                                        _questions[index].type.toString().split('.').last.substring(1)
                                    ),
                                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // actual question widget
                              _buildQuestionWidget(_questions[index], index),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Add some bottom padding
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
