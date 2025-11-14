import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String _token = '';
  String get token => _token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  String _flavor = '';
  String get flavor => _flavor;

  void setFlavor(String flavor) {
    _flavor = flavor;
    notifyListeners();
  }

  
}