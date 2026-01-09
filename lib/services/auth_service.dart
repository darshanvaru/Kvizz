import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../api_endpoints.dart';

class AuthService {

  // Login function
  static Future<UserModel> login({required BuildContext context, required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "email": email.trim(),
          "password": password.trim(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
        throw Exception('Connection timeout. Please try again.'),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        await prefs.setString("jwt", decoded["token"]);

        final user = UserModel.fromJson(decoded["user"]);
        Provider.of<UserProvider>(context, listen: false).setCurrentUser(user);

        return user;
      } else if (response.statusCode == 401) {
        throw Exception(decoded["message"] ?? "Invalid credentials. Please try again.");
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
        },
        body: jsonEncode(data),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout. Please try again.'),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode > 200 && response.statusCode < 300) {
        print("user created successfully");
        return;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        print("From SignUp Method ${decoded["message"]}");
        throw Exception(decoded["message"] ?? "User already exists. Please try again.");
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
