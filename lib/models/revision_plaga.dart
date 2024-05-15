// To parse this JSON data, do
//
//     final revisionPlaga = revisionPlagaFromMap(jsonString);

import 'dart:convert';

RevisionPlaga revisionPlagaFromMap(String str) => RevisionPlaga.fromJson(json.decode(str));

String revisionPlagaToMap(RevisionPlaga data) => json.encode(data.toMap());

class RevisionPlaga {
  late int otPlagaId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late String comentario;
  late int plagaId;
  late String codPlaga;
  late String plaga;
  late int gradoInfestacionId;
  late String codGradoInfestacion;
  late String gradoInfestacion;

  RevisionPlaga({
    required this.otPlagaId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.comentario,
    required this.plagaId,
    required this.codPlaga,
    required this.plaga,
    required this.gradoInfestacionId,
    required this.codGradoInfestacion,
    required this.gradoInfestacion,
  });

  factory RevisionPlaga.fromJson(Map<String, dynamic> json) => RevisionPlaga(
        otPlagaId: json["otPlagaId"] as int? ?? 0,
        ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
        otRevisionId: json["otRevisionId"] as int? ?? 0,
        comentario: json["comentario"] as String? ?? '',
        plagaId: json["plagaId"] as int? ?? 0,
        codPlaga: json["codPlaga"] as String? ?? '',
        plaga: json["plaga"] as String? ?? '',
        gradoInfestacionId: json["gradoInfestacionId"] as int? ?? 0,
        codGradoInfestacion: json["codGradoInfestacion"] as String? ?? '',
        gradoInfestacion: json["gradoInfestacion"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "otPlagaId": otPlagaId,
        "ordenTrabajoId": ordenTrabajoId,
        "otRevisionId": otRevisionId,
        "comentario": comentario,
        "plagaId": plagaId,
        "codPlaga": codPlaga,
        "plaga": plaga,
        "gradoInfestacionId": gradoInfestacionId,
        "codGradoInfestacion": codGradoInfestacion,
        "gradoInfestacion": gradoInfestacion,
      };

  RevisionPlaga.empty() {
    otPlagaId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    comentario = '';
    plagaId = 0;
    codPlaga = '';
    plaga = '';
    gradoInfestacionId = 0;
    codGradoInfestacion = '';
    gradoInfestacion = '';
  }

  @override
  String toString() {
    return plaga;
  }
}
