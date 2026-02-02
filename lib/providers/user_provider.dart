import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    print("User set to ${user.username}, id: ${user.id}");
    _currentUser = user;
    print("CurrentUser set to ${_currentUser?.username}, id: ${_currentUser?.id}");
    notifyListeners();
  }
}
