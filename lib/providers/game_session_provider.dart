import 'package:flutter/cupertino.dart';

import '../models/game_session_model.dart';

class GameSessionProvider extends ChangeNotifier {
  GameSessionModel? _session;

  GameSessionModel? get session => _session;

  void updateSession(GameSessionModel session) {
    _session = session;
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    notifyListeners();
  }
}
