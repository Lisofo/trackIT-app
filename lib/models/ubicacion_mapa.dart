// To parse this JSON data, do
//
//     final ubicacion = ubicacionFromMap(jsonString);

import 'dart:convert';

import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/tecnico.dart';

List<UbicacionMapa> ubicacionFromMap(String str) => List<UbicacionMapa>.from(json.decode(str).map((x) => UbicacionMapa.fromJson(x)));

String ubicacionToMap(List<UbicacionMapa> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class UbicacionMapa {
  late int ordenTrabajoId;
  late DateTime fechaOrdenTrabajo;
  late int logId;
  late DateTime fechaDate;
  late String estado;
  late int? ubicacionId;
  late String? ubicacion;
  late DateTime inicio;
  late DateTime fin;
  late String estadoOt;
  late TipoOrden tipoOrden;
  late Cliente cliente;
  late Tecnico tecnico;
  late bool seleccionado;

  UbicacionMapa({
    required this.ordenTrabajoId,
    required this.fechaOrdenTrabajo,
    required this.logId,
    required this.fechaDate,
    required this.estado,
    required this.ubicacionId,
    required this.ubicacion,
    required this.inicio,
    required this.fin,
    required this.estadoOt,
    required this.tipoOrden,
    required this.cliente,
    required this.tecnico,
    required this.seleccionado,
  });

  factory UbicacionMapa.fromJson(Map<String, dynamic> json) => UbicacionMapa(
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    fechaOrdenTrabajo: DateTime.parse(json["fechaOrdenTrabajo"]),
    logId: json["logId"] as int? ?? 0,
    fechaDate: DateTime.parse(json["fechaDate"]),
    estado: json["estado"] as String? ?? '',
    ubicacionId: json["ubicacionId"] as int? ?? 0,
    ubicacion: json["ubicacion"] as String? ?? '',
    inicio: DateTime.parse(json["inicio"]),
    fin: DateTime.parse(json["fin"]),
    estadoOt: json["estadoOT"] as String? ?? '',
    tipoOrden: TipoOrden.fromMap(json["tipoOrden"]),
    cliente: Cliente.fromJson(json["cliente"]),
    tecnico: Tecnico.fromJson(json["tecnico"]),
    seleccionado: true,
  );

  Map<String, dynamic> toMap() => {
    "ordenTrabajoId": ordenTrabajoId,
    "fechaOrdenTrabajo": fechaOrdenTrabajo.toIso8601String(),
    "logId": logId,
    "fechaDate": fechaDate.toIso8601String(),
    "estado": estado,
    "ubicacionId": ubicacionId,
    "ubicacion": ubicacion,
    "inicio": inicio.toIso8601String(),
    "fin": fin.toIso8601String(),
    "estadoOT": estadoOt,
    "tipoOrden": tipoOrden.toMap(),
    "cliente": cliente.toMap(),
    "tecnico": tecnico.toMap(),
  };

  UbicacionMapa.empty() {
    ordenTrabajoId = 0;
    fechaOrdenTrabajo = DateTime.now();
    logId = 0;
    fechaDate = DateTime.now();
    estado = '';
    ubicacionId = 0;
    ubicacion = '';
    inicio = DateTime.now();
    fin = DateTime.now();
    estadoOt = '';
    tipoOrden = TipoOrden.empty();
    cliente = Cliente.empty();
    tecnico = Tecnico.empty();
  }
}

class TipoOrden {
  late int tipoOrdenId;
  late String codTipoOrden;
  late String descripcion;

  TipoOrden({
    required this.tipoOrdenId,
    required this.codTipoOrden,
    required this.descripcion,
  });

  factory TipoOrden.fromMap(Map<String, dynamic> json) => TipoOrden(
    tipoOrdenId: json["tipoOrdenId"] as int? ?? 0,
    codTipoOrden: json["codTipoOrden"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    "tipoOrdenId": tipoOrdenId,
    "codTipoOrden": codTipoOrden,
    "descripcion": descripcion,
  };

  TipoOrden.empty() {
    tipoOrdenId = 0;
    codTipoOrden = '';
    descripcion = '';
  }
}
