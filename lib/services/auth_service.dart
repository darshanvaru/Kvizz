import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/UserModel.dart';
import '../providers/user_provider.dart';
import '../api_endpoints.dart';

class AuthService {

  // Login function
  static Future<UserModel> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    final Map<String, dynamic> data = {
      "email": email.trim(),
      "password": password.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout. Please try again.'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == "success") {
          await prefs.setString("jwt", decoded["token"]);

          final user = UserModel.fromJson(decoded["user"]);
          Provider.of<UserProvider>(context, listen: false).setCurrentUser(user);

          return user;
        } else {
          throw Exception(decoded["message"] ?? "Login failed");
        }
      } else if (response.statusCode == 401) {
        throw Exception("Invalid email or password");
      } else if (response.statusCode >= 500) {
        throw Exception("Server error. Please try again later.");
      } else {
        throw Exception("Login failed. Please try again.");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    }
  }

  // Signup function
  static Future<void> signup({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    final Map<String, dynamic> data = {
      "name": name.trim(),
      "username": username.trim(),
      "email": email.trim(),
      "password": password.trim(),
      "passwordConfirm": passwordConfirm.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.signup),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout. Please try again.'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == "success") {
          // Signup success: no user object expected here (usually)
          return;
        } else {
          throw Exception(decoded["message"] ?? "Registration failed");
        }
      } else if (response.statusCode == 409) {
        throw Exception("Email or username already exists");
      } else if (response.statusCode >= 500) {
        throw Exception("Server error. Please try again later.");
      } else {
        throw Exception("Registration failed. Please try again.");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    }
  }
}
