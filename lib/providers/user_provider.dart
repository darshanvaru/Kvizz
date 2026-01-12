import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    print("user set to ${user.toString()}");
    _currentUser = user;
    notifyListeners();
  }
}
