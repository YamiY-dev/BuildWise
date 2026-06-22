import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isDarkMode = true;
  String _searchQuery = '';

  int get currentIndex => _currentIndex;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
