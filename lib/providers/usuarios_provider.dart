import 'package:app_tec_sedel/models/usuario.dart';
import 'package:flutter/widgets.dart';

class UsuariosProvider with ChangeNotifier {
  Usuario _usuario = Usuario.empty();
  Usuario get usuario => _usuario;
  
  void setUsuario(Usuario user) {
    _usuario = user;
    notifyListeners();
  }

  void clearSelectedUsuario() {
    _usuario = Usuario.empty();
    notifyListeners();
  }
}