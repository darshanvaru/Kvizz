import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kvizz/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_endpoints.dart';
import '../models/user_model.dart';

class UserService with ChangeNotifier{

  Future<UserModel> fetchUserProfile(BuildContext context) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    final response = await http.get(
      Uri.parse(ApiEndpoints.getMe),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data']['doc'];
      UserModel user = UserModel.fromJson(data);
      print("Calling setCurrentUser from fetchUserProfile.");
      if(context.mounted) {
        Provider.of<UserProvider>(context, listen: false).setCurrentUser(user);
      }

      return user;
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<UserModel> updateUserProfile(Map<String, dynamic> updateData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';

    final response = await http.patch(
      Uri.parse(ApiEndpoints.updateMe),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['updatedUser'];
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<String?> updateMyPassword(String currentPassword, String newPassword, String confirmPassword) async {
    late final SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();

    var body = jsonEncode({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'newPasswordConfirm': confirmPassword,
    });

    try {
      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateMyPassword),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${prefs.getString('jwt') ?? ''}',
        },
        body: body,
      );

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

  Future<bool> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.deleteMe),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> forgetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgetPassword),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": email}),
      );


      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetPassword(String resetCode, String newPassword, String confirmPassword) async {
    try{
      final response = await http.patch(
        Uri.parse(ApiEndpoints.resetPassword),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "token": resetCode,
          "password": newPassword,
          "passwordConfirm": confirmPassword,
        })
      );

      if(response.statusCode == 200){
        return true;
      }else {
        return false;
      }
    } catch(e) {
      rethrow;
    }
  }
}
