import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kvizz/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_endpoints.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class Auth extends ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  Timer? _authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_token != null && _expiryDate != null && _expiryDate!.isAfter(DateTime.now())) {
      return _token;
    }
    return null;
  }

  Future<UserModel?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return null;
    }

    final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);
    if (expiryDate.isBefore(DateTime.now())) {
      return null;
    }

    _token = extractedUserData['token'];
    _expiryDate = expiryDate;
    notifyListeners();

    try {
      final fetchedUser = await UserService.fetchUserProfile();
      return fetchedUser;
    } catch (e) {
      return null;
    }
  }


  Future<void> logout() async {
    debugPrint("AuthProvider: logout function called");
    _token = null;
    _expiryDate = null;
    _authTimer?.cancel();
    _authTimer = null;
    _authTimer = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    debugPrint("AuthProvider: Cleared userData from SharedPreferences");
  }

  void _autoLogout() {
    debugPrint("AuthProvider: _autoLogout called");
    _authTimer?.cancel();
    if (_expiryDate == null) {
      debugPrint("AuthProvider: _expiryDate is null, cannot auto logout");
      return;
    }
    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    debugPrint("AuthProvider: Scheduling auto logout in $timeToExpiry seconds");
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  Future<UserModel> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    debugPrint("In AuthProvider Login Function");

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
        _token = decodedResponseBody["token"];
        _expiryDate = DateTime.now().add(const Duration(days: 90)); // Token valid 90 days
        _autoLogout();
        notifyListeners();

        // Storing userData in SharedPreferences
        final userData = json.encode({
          'token': _token,
          'expiryDate': _expiryDate!.toIso8601String(),
        });
        prefs.setString('userData', userData);
        prefs.setString("jwt", decodedResponseBody["token"]);

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
    debugPrint("In AuthProvider signup Started");

    try {
      final response = await http.post(
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
      debugPrint("Response: $decoded");

      if (decoded["status"] == "success") {
        debugPrint("From Auth Provider: user created successfully");
        return;
      } else {
        debugPrint("From Auth Provider: Error: ${decoded["message"]}");
        throw Exception(decoded["message"] ?? "Invalid data. Please try again.");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    }
  }
}
