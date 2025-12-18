// To parse this JSON data, do
//
//     final observacion = observacionFromMap(jsonString);

import 'dart:convert';

RevisionIncidencia revisionIncidenciaFromMap(String str) => RevisionIncidencia.fromJson(json.decode(str));

String revisionIncidenciaToMap(RevisionIncidencia data) => json.encode(data.toMap());

class RevisionIncidencia {
  late int otIncidenciaId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late String observacion;

  RevisionIncidencia({
    required this.otIncidenciaId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.observacion,
  });

  factory RevisionIncidencia.fromJson(Map<String, dynamic> json) => RevisionIncidencia(
    otIncidenciaId: json["otIncidenciaId"] as int? ?? 0,
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    otRevisionId: json["otRevisionId"] as int? ?? 0,
    observacion: json["observacion"] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    "otIncidenciaId": otIncidenciaId,
    "ordenTrabajoId": ordenTrabajoId,
    "otRevisionId": otRevisionId,
    "observacion": observacion,
  };

  RevisionIncidencia.empty() {
    otIncidenciaId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    observacion = '';
  }
}
 