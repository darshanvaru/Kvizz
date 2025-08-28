import 'package:flutter/material.dart';

class TabIndexProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void updateSelectedIndex(int newIndex) {
    if (_selectedIndex != newIndex) {
      _selectedIndex = newIndex;
      notifyListeners();
    }
  }

  void resetIndex() {
    _selectedIndex = 0;
    notifyListeners();
  }
}