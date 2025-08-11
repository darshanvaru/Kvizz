// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import '../models/UserModel.dart';
//
// Future<UserModel?> signUpUser({
//   required String name,
//   required String email,
//   required String password,
//   required String passwordConfirm,
// }) async {
//   const url = 'http://192.168.104.75:8000/api/v1/users/signup';
//
//   final response = await http.post(
//     Uri.parse("${dotenv.env['API_URL']}/users/signup"),
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode({
//       'name': name,
//       'email': email,
//       'password': password,
//       'passwordConfirm': passwordConfirm,
//     }),
//   );
//
//   if (response.statusCode == 201 || response.statusCode == 200) {
//     final body = jsonDecode(response.body);
//     return UserModel.fromJson(body['data']['user']);
//   } else {
//     print('Signup Failed: ${response.body}');
//     return null;
//   }
// }
