import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kvizz/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_model.dart';

// To create a new quiz
Future<QuizModel?> createQuiz(QuizModel quiz) async {
  final String body = jsonEncode(quiz.toJson(forApi: true));
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';

  try {
    final response = await http.post(
      Uri.parse(ApiEndpoints.saveQuiz),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final QuizModel createdQuiz = QuizModel.fromJson(data['data']['quiz']);

      return createdQuiz;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

// To create a new quiz
Future<QuizModel?> updateQuiz(QuizModel quiz) async {
  final String body = jsonEncode(quiz.toJson());
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';

  try {
    final response = await http.patch(
      Uri.parse(ApiEndpoints.updateQuiz),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final QuizModel updatedQuiz = QuizModel.fromJson(data['data']['quiz']);
      return updatedQuiz;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

//Delete quiz by quizId
Future<bool> deleteQuiz(String quizId) async {
  if (quizId.isEmpty) return false;
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';

  try {
    final response = await http.delete(
      Uri.parse(ApiEndpoints.deleteQuiz(quizId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

// Fetch active quizzes from the server
Future<List<Map<String, dynamic>>?> getActiveQuizzes() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';

  try {
    final response = await http.get(
      Uri.parse(ApiEndpoints.activeQuizzes),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List<dynamic> docs = data['data']?['doc'] ?? [];

      final List<Map<String, dynamic>> activeQuizzes = docs.map<Map<String, dynamic>>((doc) {
        return {
          'id': doc['quizId']?? '',
          "title": doc['quizId']?['title'] ?? "",
          "description": doc['quizId']?['description'] ?? "",
          "gameCode": doc['gameCode'] ?? 000000,
        };
      }).toList();

      return activeQuizzes;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

// Fetch a quiz by its ID
Future<QuizModel?> fetchQuizById(String quizId) async {
  if(quizId == '') return null;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';
  try {
    final response = await http.get(
      Uri.parse(ApiEndpoints.quizByQuizId(quizId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // printFullResponse("[From QuizService.fetchQuizById] Response received: ${response.body}");
      final data = json.decode(response.body);

      // printFullResponse("[From QuizService.fetchQuizById] Parsed data: $data");
      final QuizModel quiz = QuizModel.fromJson(data['data']['doc']);

      // printFullResponse("[From QuizService.fetchQuizById] Quiz fetched successfully: ${quiz.title}");
      return quiz;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

// Fetch all public quizzes
Future<List<QuizModel>?> fetchAllQuizzes() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';
  try {
    final response = await http.get(
      Uri.parse(ApiEndpoints.publicQuizzes),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<QuizModel> allQuizzes = [];

      final data = json.decode(response.body);
      allQuizzes = (data['data']['doc'] as List)
          .map((quiz) => QuizModel.fromJson(quiz))
          .toList();

      return allQuizzes;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

// Fetch all use quiz by user ID
Future<List<QuizModel>?> fetchUserQuizzes(String userId) async {
  try {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    final response = await http.get(
      Uri.parse(ApiEndpoints.quizzesOfUserByUserID(userId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Parse the quiz list from response
      final List<QuizModel> quizzes = (data['data']['doc'] as List)
          .map((quiz) => QuizModel.fromJson(quiz))
          .toList();

      // Return the parsed quizzes
      return quizzes;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}