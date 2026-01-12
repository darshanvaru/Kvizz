import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static final String baseUrl = dotenv.env['API_URL']!;

  // ------------------------ User ------------------------
  static String get getMe => '$baseUrl/users/me';
  static String get updateMe => '$baseUrl/users/update-info';
  static String get updateMyPassword => '$baseUrl/users/update-password';

  // ------------------------ AUTH ------------------------
  static String get login => '$baseUrl/users/login';
  static String get signup => '$baseUrl/users/signup';

  // ------------------------ QUIZZES ------------------------
  ///Medusa AI
  static String get medusaAIGenerateFromPrompt => 'http://192.168.67.181:8000/generate';
  static String get medusaAIGenerateFromFile => 'http://192.168.67.181:8000/generate-from-file';

  /// Get all public quizzes available to everyone
  static String get publicQuizzes => '$baseUrl/quiz/public';

  /// Get all active quizzes
  static String get activeQuizzes => '$baseUrl/games/explore';

  /// Get quiz by Quiz ID
  static String quizByQuizId(String quizId) => '$baseUrl/quizzes/$quizId';

  /// Get all quizzes of a user by User ID
  static String quizzesOfUserByUserID(String userId) => '$baseUrl/quizzes/of/$userId';

  /// Save (create) a new quiz
  static String get saveQuiz => '$baseUrl/quizzes/do/save';

  /// Update a quiz by ID
  static String get updateQuiz => '$baseUrl/quizzes/do/update';

  /// Delete a quiz by ID
  static String deleteQuiz(String quizId) => '$baseUrl/quizzes/do/delete/$quizId';

  ///Delete account
  static String get deleteMe => '$baseUrl/users/delete-me';
}
