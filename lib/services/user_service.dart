import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_endpoints.dart';
import '../models/UserModel.dart';

class UserService {

  // Fetch user profile info
  static Future<UserModel> fetchUserProfile() async {
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
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // Update user profile with any subset of fields
  static Future<UserModel> updateUserProfile(Map<String, dynamic> updateData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    print("Updating user with the following data\n${json.encode(updateData)}\ntoken: $token");
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
}
