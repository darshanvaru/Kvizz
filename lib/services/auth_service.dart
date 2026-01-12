import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kvizz/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_endpoints.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class AuthService {

  Future<bool> tryAutoLogin() async {
    try {
      await UserService().fetchUserProfile();
      return true;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt');
      return false;
    }
  }

  Future<UserModel> login({
    required BuildContext context,
    required String email,
    required String password
  }) async {

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
        onTimeout: () => throw Exception('Connection timeout. Please try again.'),
      );

      final decodedResponseBody = jsonDecode(response.body);
      debugPrint("Response: $decodedResponseBody");

      if (decodedResponseBody["status"] == "success") {
        debugPrint("From Auth Provider: user Logged In status: Success");
        debugPrint("Token: ${decodedResponseBody["token"]}");

        // Setting Auth Parameters
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("jwt", decodedResponseBody["token"]);
        prefs.setString("expiryDate", DateTime.now().add(const Duration(days: 90)).toString());

        final user = UserModel.fromJson(decodedResponseBody["user"]);
        Provider.of<UserProvider>(context, listen: false).setCurrentUser(user);

        return user;
      } else {
        debugPrint("From Auth Provider: user Logged In status: Failed");
        debugPrint("Error: ${decodedResponseBody["message"]}");
        throw Exception(decodedResponseBody["message"] ?? "Something went wrong. Please try again.");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on TimeoutException {
      throw Exception("Connection timeout. Please try again.");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    }
  }

  Future<void> signup({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiEndpoints.signup),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "name": name.trim(),
          "username": username.trim(),
          "email": email.trim(),
          "password": password.trim(),
          "passwordConfirm": passwordConfirm.trim(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout. Please try again.'),
      );

      final decoded = jsonDecode(response.body);
      if (decoded["status"] != "success") {
        throw Exception(decoded["message"] ?? "Signup failed");
      }

      return;
    } on SocketException {
      throw Exception("No internet connection");
    } on TimeoutException {
      throw Exception("Connection timeout. Please try again.");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    print("[deleteAccount] Token: $token");
    print("[deleteAccount] URL: ${ApiEndpoints.deleteMe}");

    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.deleteMe),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("1");
      debugPrint('[deleteAccount] HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 204) {
        return true;
      }

      debugPrint('[deleteAccount] Unexpected response: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('[deleteAccount] Exception: $e');
      return false;
    }
  }

}