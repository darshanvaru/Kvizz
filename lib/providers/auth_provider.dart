import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:kvizz/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../enums/enums.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _initialized = false;
  final AuthService _authService = AuthService();

  AuthStatus _state = AuthStatus.checking;
  AuthStatus get state => _state;

  // Called at app startup
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    Future.microtask(_bootstrap);
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    _state = AuthStatus.checking;
    notifyListeners();

    final bool success = await _authService.tryAutoLogin();

    _state = success
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;

    notifyListeners();
  }

  Future<UserModel> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    // _state = AuthStatus.checking;
    // notifyListeners();

    try {
      final user = await _authService.login(
        context: context,
        email: email,
        password: password,
      );

      _state = AuthStatus.authenticated;
      notifyListeners();
      return user;
    } catch (e) {
      _state = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    // _state = AuthStatus.checking;
    // notifyListeners();

    try {
      await _authService.signup(
        name: name,
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      _state = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _state = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _state = AuthStatus.unauthenticated;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
  }

  Future<bool> deleteAccount() async {
    final success = await _authService.deleteAccount();

    if (!success) return false;
    _state = AuthStatus.unauthenticated;

    notifyListeners();
    return true;
  }

}
