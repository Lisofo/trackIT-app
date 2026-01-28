// To parse this JSON data, do
//
//     final tipoOt = tipoOtFromJson(jsonString);

import 'dart:convert';

List<TipoOt> tipoOtFromJson(String str) => List<TipoOt>.from(json.decode(str).map((x) => TipoOt.fromJson(x)));

String tipoOtToJson(List<TipoOt> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoOt {
  late int? tipoOtId;
  late String? descripcion;
  late String? reqUnidad;

  TipoOt({
    this.tipoOtId,
    this.descripcion,
    this.reqUnidad,
  });

  TipoOt copyWith({
    int? tipoOtId,
    String? descripcion,
    String? reqUnidad,
  }) => TipoOt(
    tipoOtId: tipoOtId ?? this.tipoOtId,
    descripcion: descripcion ?? this.descripcion,
    reqUnidad: reqUnidad ?? this.reqUnidad,
  );

  factory TipoOt.fromJson(Map<String, dynamic> json) => TipoOt(
    tipoOtId: json["tipoOTId"] as int?,
    descripcion: json["descripcion"] as String?,
    reqUnidad: json["reqUnidad"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "tipoOTId": tipoOtId,
    "descripcion": descripcion,
    "reqUnidad": reqUnidad,
  };

  TipoOt.empty() {
    tipoOtId = null;
    descripcion = null;
    reqUnidad = null;
  }
}
