import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String _token = '';
  String get token => _token;
  
  int _uId = 0;
  int get uId => _uId;
  
  String _nombreUsuario = '';
  String get nombreUsuario => _nombreUsuario;

  int _tecnicoId = 0;
  int get tecnicoId => _tecnicoId;

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

  void setUsuarioId(int id) {
    _uId = id;
    notifyListeners();
  }

  void setNombreUsuario(String userName) {
    _nombreUsuario = userName;
    notifyListeners();
  }

  void setTecnicoId(int tecId) {
    _tecnicoId = tecId;
    notifyListeners();
  }

  
}