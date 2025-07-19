import 'package:flutter/material.dart';
import 'package:kvizz/screens/create_quiz_screen.dart';
import 'package:kvizz/screens/my_quiz.dart';
import 'package:kvizz/screens/prompt_screen.dart';
// import 'package:kvizz/screens/auth_screen.dart';
import 'package:kvizz/screens/quiz_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData quizAppTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4B39EF), // Vibrant violet-blue
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Poppins', // Choose your preferred font

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4B39EF),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        labelStyle: const TextStyle(color: Colors.black54),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),

      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.grey..withValues(alpha: 0.1),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      iconTheme: const IconThemeData(color: Color(0xFF4B39EF), size: 24),

      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: const Color(0xFFFFC107), // For highlights or answers
        error: Colors.redAccent,
      ),
    );


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kwizz',
      theme: quizAppTheme,
      home: MyQuizzesScreen()
    );
  }
}