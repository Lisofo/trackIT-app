// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:app_track_it/models/orden.dart';
import 'package:app_track_it/models/revision_pto_inspeccion.dart';
import 'package:app_track_it/models/tipos_ptos_inspeccion.dart';

class OrdenProvider with ChangeNotifier {
  Orden _orden = Orden.empty();
  String _menu = '';
  String _token = '';
  int _uId = 0;
  String _nombreUsuario = '';
  int _marcaId = 0;
  TipoPtosInspeccion _tipoPtosInspeccion = TipoPtosInspeccion.empty();
  List<RevisionPtoInspeccion> _ptosInspeccion = [];
  RevisionPtoInspeccion _revisionPtoInspeccion = RevisionPtoInspeccion.empty();
  String _modo = '';
  int _tecnicoId = 0;
  List<Orden> ordenesEnProceso = [];


  Orden get orden => _orden;
  String get menu => _menu;
  String get token => _token;
  int get uId => _uId;
  String get nombreUsuario => _nombreUsuario;
  int get marcaId => _marcaId;
  bool _pendientes = false;
  TipoPtosInspeccion get tipoPtosInspeccion => _tipoPtosInspeccion;
  List<RevisionPtoInspeccion> get ptosInspeccion => _ptosInspeccion;
  List<RevisionPtoInspeccion> get puntosSeleccionados => _ptosInspeccion.where((pto) => pto.seleccionado).toList();
  List<RevisionPtoInspeccion> get puntosFiltrados => _ptosInspeccion.where((pto) => pto.tipoPuntoInspeccionId == tipoPtosInspeccion.tipoPuntoInspeccionId).toList();
  List<RevisionPtoInspeccion> get listaPuntos => puntosFiltrados.where((element) => _pendientes ? element.codAccion == '' : element.codAccion == element.codAccion).toList();
  List<RevisionPtoInspeccion> get _ptosInspeccionCompleta => listaPuntos;
  RevisionPtoInspeccion get revisionPtoInspeccion => _revisionPtoInspeccion;
  String get modo => _modo;
  int get tecnicoId => _tecnicoId;

  void setPendiente(bool pendi) {
    _pendientes = pendi;
    notifyListeners();
  }

  void setOrden(Orden orden) {
    _orden = orden;
    notifyListeners();
  }

  void setPage(String codPages) {
    _menu = codPages;
    notifyListeners();
  }

  void setToken(String tok) {
    _token = tok;
    notifyListeners();
  }

  void setUsuarioId(int id) {
    _uId = id;
    notifyListeners();
  }

  void setTecnicoId(int tecId) {
    _tecnicoId = tecId;
    notifyListeners();
  }

  void setNombreUsuario(String userName) {
    _nombreUsuario = userName;
    notifyListeners();
  }

  void setMarca(int mId) {
    _marcaId = mId;
    notifyListeners();
  }

  void setTipoPTI(TipoPtosInspeccion tPI) {
    _tipoPtosInspeccion = tPI;
    notifyListeners();
  }

  void setPI(List<RevisionPtoInspeccion> listaPI) {
    _ptosInspeccion = listaPI;
    notifyListeners();
  }

  void setRevisionPI(RevisionPtoInspeccion revisionPI) {
    _revisionPtoInspeccion = revisionPI;
    notifyListeners();
  }

  void SetModo(String modo) {
    _modo = modo;
    notifyListeners();
  }

  void actualizarPunto(int i, RevisionPtoInspeccion punto) {
    puntosSeleccionados[i] = punto;
    notifyListeners();
  }

  void setOrdenes(List<Orden> ordenes) {
    ordenesEnProceso = ordenes;
  }
    
  void filtrarPuntosInspeccion1(String criterio) {
    _ptosInspeccion = _ptosInspeccionCompleta.where((pto) => pto.codPuntoInspeccion.contains(criterio)).toList();
    notifyListeners();
  }

  void filtrarPuntosInspeccion2(String criterio) {
    _ptosInspeccion = _ptosInspeccionCompleta.where((pto) => pto.codigoBarra.contains(criterio)).toList();
    notifyListeners();
  }

}