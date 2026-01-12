import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kvizz/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_endpoints.dart';
import '../models/user_model.dart';

class UserService with ChangeNotifier{

  // Fetch user profile info
  Future<UserModel> fetchUserProfile() async {
    print("[user_service.fetchUserProfile] Fetching user profile data");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    final response = await http.get(
      Uri.parse(ApiEndpoints.getMe),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('API response status: ${response.statusCode}');
    print('API response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data']['doc'];
      UserModel user = UserModel.fromJson(data);
      UserProvider().setCurrentUser(user);
      return user;
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // Update user profile with any subset of fields
  Future<UserModel> updateUserProfile(Map<String, dynamic> updateData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    print("Updating user with the following data\n${json.encode(updateData)}\n and token: $token");
    final response = await http.patch(
      Uri.parse(ApiEndpoints.updateMe),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );

    print('API response status: ${response.statusCode}');
    print('API response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['updatedUser'];
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Update user password
  Future<String?> updateMyPassword(String currentPassword, String newPassword, String confirmPassword) async {
    late final SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();

    var body = jsonEncode({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'newPasswordConfirm': confirmPassword,
    });
    print(jsonEncode(body));

    try {
      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateMyPassword),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${prefs.getString('jwt') ?? ''}',
        },
        body: body,
      );

      print('API response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == "success") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("jwt", decoded["token"]);
        }

        return null; // success
      } else {
        var resJson = jsonDecode(response.body);
        return resJson['message'] ?? 'Unknown error occurred';
      }
    } catch (e) {
      return 'Failed to update password: $e';
    }
  }
}
