import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // For now, we use a simple hardcoded PIN as requested "sederhana saja"
  // In a real app, this would be validated against a secure backend or encrypted storage
  static const String _correctPin = "061223"; // Example PIN, you can change this

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  void login(String pin) {
    if (pin == _correctPin) {
      _isAuthenticated = true;
      _errorMessage = '';
      notifyListeners();
    } else {
      _errorMessage = 'PIN salah. Silakan coba lagi.';
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
