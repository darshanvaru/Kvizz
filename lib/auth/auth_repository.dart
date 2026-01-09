import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_endpoints.dart';
import '../models/user_model.dart';
import 'auth_exceptions.dart';

class LoginResult {
  final String token;
  final DateTime expiry;
  final UserModel user;

  LoginResult({
    required this.token,
    required this.expiry,
    required this.user,
  });
}

class AuthRepository {
  static Future<LoginResult> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password.trim(),
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw AuthUnauthorizedException(
        body['message'] ?? 'Invalid credentials',
      );
    }

    if (response.statusCode != 200) {
      throw AuthNetworkException(
        body['message'] ?? 'Login failed',
      );
    }

    return LoginResult(
      token: body['token'],
      expiry: DateTime.now().add(const Duration(days: 90)),
      user: UserModel.fromJson(body['user']),
    );
  }

  static Future<UserModel> fetchMe(String token) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.getMe),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw AuthUnauthorizedException();
    }

    if (response.statusCode != 200) {
      throw AuthNetworkException('Failed to fetch user');
    }

    final decoded = jsonDecode(response.body);
    return UserModel.fromJson(decoded['data']['doc']);
  }
}
