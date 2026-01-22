import 'package:app_tec_sedel/models/usuario.dart';
import 'package:flutter/widgets.dart';

class UsuariosProvider with ChangeNotifier {
  Usuario _usuario = Usuario.empty();
  bool _needsRefresh = false; // Añade esta bandera

  Usuario get usuario => _usuario;
  bool get needsRefresh => _needsRefresh;

  void setUsuario(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void clearSelectedUsuario() {
    _usuario = Usuario.empty();
    notifyListeners();
  }

  // Añade estos métodos
  void markNeedsRefresh() {
    _needsRefresh = true;
    notifyListeners();
  }

  void clearRefreshFlag() {
    _needsRefresh = false;
    notifyListeners();
  }
}