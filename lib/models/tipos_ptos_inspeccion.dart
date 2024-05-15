// To parse this JSON data, do
//
//     final tipoPtosInspeccion = tipoPtosInspeccionFromMap(jsonString);

import 'dart:convert';

List<TipoPtosInspeccion> tipoPtosInspeccionFromMap(String str) =>
    List<TipoPtosInspeccion>.from(
        json.decode(str).map((x) => TipoPtosInspeccion.fromJson(x)));

String tipoPtosInspeccionToMap(List<TipoPtosInspeccion> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class TipoPtosInspeccion {
  late int tipoPuntoInspeccionId;
  late String codTipoPuntoInspeccion;
  late String descripcion;

  TipoPtosInspeccion({
    required this.tipoPuntoInspeccionId,
    required this.codTipoPuntoInspeccion,
    required this.descripcion,
  });

  factory TipoPtosInspeccion.fromJson(Map<String, dynamic> json) =>
      TipoPtosInspeccion(
        tipoPuntoInspeccionId: json["tipoPuntoInspeccionId"],
        codTipoPuntoInspeccion: json["codTipoPuntoInspeccion"],
        descripcion: json["descripcion"],
      );

  Map<String, dynamic> toMap() => {
        "tipoPuntoInspeccionId": tipoPuntoInspeccionId,
        "codTipoPuntoInspeccion": codTipoPuntoInspeccion,
        "descripcion": descripcion,
      };

  TipoPtosInspeccion.empty() {
    tipoPuntoInspeccionId = 0;
    codTipoPuntoInspeccion = '';
    descripcion = '';
  }
}
