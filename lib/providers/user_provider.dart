import 'package:flutter/foundation.dart';

import '../models/UserModel.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Add methods for new fields
  void updateUserStats(UserStats stats) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        mobile: _currentUser!.mobile,
        username: _currentUser!.username,
        photo: _currentUser!.photo,
        createdAt: _currentUser!.createdAt,
        passwordChangedAt: _currentUser!.passwordChangedAt,
        active: _currentUser!.active,
        deletedAt: _currentUser!.deletedAt,
        stats: stats, // Updated stats
        ownedQuizzes: _currentUser!.ownedQuizzes,
        playedQuiz: _currentUser!.playedQuiz,
        settings: _currentUser!.settings,
      );
      notifyListeners();
    }
  }

  void updateUserSettings(UserSettings settings) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        mobile: _currentUser!.mobile,
        username: _currentUser!.username,
        photo: _currentUser!.photo,
        createdAt: _currentUser!.createdAt,
        passwordChangedAt: _currentUser!.passwordChangedAt,
        active: _currentUser!.active,
        deletedAt: _currentUser!.deletedAt,
        stats: _currentUser!.stats,
        ownedQuizzes: _currentUser!.ownedQuizzes,
        playedQuiz: _currentUser!.playedQuiz,
        settings: settings, // Updated settings
      );
      notifyListeners();
    }
  }
}
