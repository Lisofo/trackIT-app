// To parse this JSON data, do
//
//     final observacion = observacionFromMap(jsonString);

import 'dart:convert';

Observacion observacionFromMap(String str) =>
    Observacion.fromJson(json.decode(str));

String observacionToMap(Observacion data) => json.encode(data.toMap());

class Observacion {
  late int otObservacionId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late String observacion;
  late String obsRestringida;
  late String comentarioInterno;

  Observacion({
    required this.otObservacionId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.observacion,
    required this.obsRestringida,
    required this.comentarioInterno,
  });

  factory Observacion.fromJson(Map<String, dynamic> json) => Observacion(
        otObservacionId: json["otObservacionId"] as int? ?? 0,
        ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
        otRevisionId: json["otRevisionId"] as int? ?? 0,
        observacion: json["observacion"] as String? ?? '',
        obsRestringida: json["obsRestringida"] as String? ?? '',
        comentarioInterno: json["comentarioInterno"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "otObservacionId": otObservacionId,
        "ordenTrabajoId": ordenTrabajoId,
        "otRevisionId": otRevisionId,
        "observacion": observacion,
        "obsRestringida": obsRestringida,
        "comentarioInterno": comentarioInterno,
      };

  Observacion.empty() {
    otObservacionId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    observacion = '';
    obsRestringida = '';
    comentarioInterno = '';
  }
}
