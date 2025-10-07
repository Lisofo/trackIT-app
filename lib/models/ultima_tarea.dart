// To parse this JSON data, do
//
//     final ultimaTarea = ultimaTareaFromMap(jsonString);

import 'dart:convert';

UltimaTarea ultimaTareaFromMap(String str) => UltimaTarea.fromMap(json.decode(str));

String ultimaTareaToMap(UltimaTarea data) => json.encode(data.toMap());

class UltimaTarea {
  late int ordenTrabajoId;
  late String numeroOrdenTrabajo;
  late String descripcion;
  late int lineaId;
  late int itemId;
  late String codItem;
  late String descActividad;
  late int otTiempoId;
  late int usuarioId;
  late String usuario;
  late DateTime desde;
  late DateTime? hasta;
  late int avance;
  late String estado;
  late String estadoTot;
  late String comentario;
  late bool administrado;

  UltimaTarea({
    required this.ordenTrabajoId,
    required this.numeroOrdenTrabajo,
    required this.descripcion,
    required this.lineaId,
    required this.itemId,
    required this.codItem,
    required this.descActividad,
    required this.otTiempoId,
    required this.usuarioId,
    required this.usuario,
    required this.desde,
    required this.hasta,
    required this.avance,
    required this.estado,
    required this.estadoTot,
    required this.comentario,
    required this.administrado,
  });

  factory UltimaTarea.fromMap(Map<String, dynamic> json) => UltimaTarea(
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    numeroOrdenTrabajo: json["numeroOrdenTrabajo"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    lineaId: json["lineaId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    descActividad: json["descActividad"] as String? ?? '',
    otTiempoId: json["OTTiempoId"] as int? ?? 0,
    usuarioId: json["usuarioId"] as int? ?? 0,
    usuario: json["usuario"] as String? ?? '',
    desde: DateTime.parse(json["desde"]),
    hasta: json["hasta"] == null ? null : DateTime.parse(json["hasta"]),
    avance: json["avance"] as int? ?? 0,
    estado: json["estado"] as String? ?? '',
    estadoTot: json["estadoTOT"] as String? ?? '',
    comentario: json["comentario"] as String? ?? '',
    administrado: json["administrado"] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    "ordenTrabajoId": ordenTrabajoId,
    "numeroOrdenTrabajo": numeroOrdenTrabajo,
    "descripcion": descripcion,
    "lineaId": lineaId,
    "itemId": itemId,
    "codItem": codItem,
    "descActividad": descActividad,
    "OTTiempoId": otTiempoId,
    "usuarioId": usuarioId,
    "usuario": usuario,
    "desde": desde.toIso8601String(),
    "hasta": hasta,
    "avance": avance,
    "estado": estado,
    "estadoTOT": estadoTot,
    "comentario": comentario,
    "administrado": administrado,
  };

  UltimaTarea.empty() {
    ordenTrabajoId = 0;
    numeroOrdenTrabajo = '';
    descripcion = '';
    lineaId = 0;
    itemId = 0;
    codItem = '';
    descActividad = '';
    otTiempoId = 0;
    usuarioId = 0;
    usuario = '';
    desde = DateTime.now();
    hasta = null;
    avance = 0;
    estado = '';
    estadoTot = '';
    comentario = '';
    administrado = false;
  }
}
