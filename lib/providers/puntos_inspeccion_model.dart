import 'package:flutter/cupertino.dart';
import 'package:app_track_it/models/revision_pto_inspeccion.dart';

class PuntosInspeccionModel with ChangeNotifier {
  final List<RevisionPtoInspeccion> _puntosInspeccion = [];

  List<RevisionPtoInspeccion> get puntosInspeccion => _puntosInspeccion;

  agregarPuntoInspeccion(RevisionPtoInspeccion punto) {
    _puntosInspeccion.add(punto);
    notifyListeners();
  }
}
