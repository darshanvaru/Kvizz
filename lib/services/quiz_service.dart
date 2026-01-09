import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kvizz/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../print_helper.dart';
import '../models/quiz_model.dart';

// To create a new quiz
Future<QuizModel?> createQuiz(QuizModel quiz) async {
  final String body = jsonEncode(quiz.toJson(forApi: true));
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';

  printFullResponse('[QuizService.createQuiz] Body → $body');

  try {
    final response = await http.post(
      Uri.parse(ApiEndpoints.saveQuiz),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    debugPrint('[QuizService.createQuiz] HTTP ${response.statusCode}');
    debugPrint('[QuizService.createQuiz] Response → ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final QuizModel createdQuiz = QuizModel.fromJson(data['data']['quiz']);

      debugPrint('[QuizService.createQuiz] Quiz saved on server with id ${createdQuiz.id}');
      return createdQuiz;
    } else {
      debugPrint(
        '[QuizService.createQuiz] Failed – status ${response.statusCode}',
      );
      return null;
    }
  } catch (e) {
    debugPrint('[QuizService.createQuiz] Error → $e');
    return null;
  }
}

// To create a new quiz
Future<QuizModel?> updateQuiz(QuizModel quiz) async {
  final String body = jsonEncode(quiz.toJson());
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt') ?? '';

  printFullResponse('[QuizService.updateQuiz] Body → $body');

  try {
    final response = await http.patch(
      Uri.parse(ApiEndpoints.updateQuiz),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    debugPrint('[QuizService.updateQuiz] HTTP ${response.statusCode}');
    debugPrint('[QuizService.updateQuiz] Response → ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final QuizModel updatedQuiz = QuizModel.fromJson(data['data']['quiz']);

      debugPrint('[QuizService.updateQuiz] Quiz updated on server with id ${updatedQuiz.id}');
      return updatedQuiz;
    } else {
      debugPrint(
        '[QuizService.updateQuiz] Failed – status ${response.statusCode}',
      );
      return null;
    }
  } catch (e) {
    debugPrint('[QuizService.updateQuiz] Error → $e');
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
    debugPrint('[QuizService.deleteQuiz] HTTP ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      debugPrint('[QuizService.deleteQuiz] Quiz deleted successfully with ID: $quizId');
      return true;
    } else {
      debugPrint('[QuizService.deleteQuiz] Failed to delete quiz: HTTP ${response.statusCode}');
      return false;
    }
  } catch (e) {
    debugPrint('[QuizService.deleteQuiz] Error deleting quiz: $e');
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

      print("[From QuizService.getActiveQuizzes] Active Quizzes fetched successfully: ${activeQuizzes.length} quizzes found.");
      return activeQuizzes;
    } else {
      debugPrint("[From QuizService.getActiveQuizzes] Failed to fetch quiz: HTTP ${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("[From QuizService.getActiveQuizzes] Error fetching quizzes. Error: $e");
    return null;
  }
}

// Fetch a quiz by its ID
Future<QuizModel?> fetchQuizById(String quizId) async {
  if(quizId == '') return null;
  print("[From QuizService.fetchQuizById] Fetching quiz with ID: $quizId");

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
      debugPrint("[From QuizService.fetchQuizById] Failed to fetch quiz: HTTP ${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("[From QuizService.fetchQuizById] Error fetching quiz by ID. Error: $e");
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
      debugPrint("Failed to fetch all quizzes: HTTP ${response.statusCode}");
      return null;
    }
  } catch (e) {
    debugPrint("Error fetching all quizzes: $e");
    return null;
  }
}

// Fetch all use quiz by user ID
Future<List<QuizModel>?> fetchUserQuizzes(String userId) async {
  try {

    print("[From QuizService.fetchUserQuizzes] Fetching quizzes for user ID: $userId");
    print("Link: ${ApiEndpoints.quizzesOfUserByUserID(userId)}");

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
      print("[From QuizService.fetchUserQuizzes] User quizzes fetched successfully: ${quizzes.length} quizzes found.");
      return quizzes;
    } else {
      debugPrint("[From QuizService.fetchUserQuizzes] Failed to fetch quizzes: HTTP ${response.statusCode}");
      return null; // Return null to indicate failure
    }
  } catch (e) {
    debugPrint("[From QuizService.fetchUserQuizzes] Error fetching user quizzes: $e");
    return null; // Return null to indicate error
  }
}