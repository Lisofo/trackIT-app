// To parse this JSON data, do
//
//     final tarea = tareaFromMap(jsonString);

import 'dart:convert';

RevisionTarea tareaFromMap(String str) =>
    RevisionTarea.fromJson(json.decode(str));

String tareaToMap(RevisionTarea data) => json.encode(data.toMap());

class RevisionTarea {
  late int otTareaId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late int tareaId;
  late String codTarea;
  late String descripcion;
  late String comentario;

  RevisionTarea({
    required this.otTareaId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.tareaId,
    required this.codTarea,
    required this.descripcion,
    required this.comentario,
  });

  factory RevisionTarea.fromJson(Map<String, dynamic> json) => RevisionTarea(
        otTareaId: json["otTareaId"] as int? ?? 0,
        ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
        otRevisionId: json["otRevisionId"] as int? ?? 0,
        tareaId: json["tareaId"] as int? ?? 0,
        codTarea: json["codTarea"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
        comentario: json["comentario"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "otTareaId": otTareaId,
        "ordenTrabajoId": ordenTrabajoId,
        "otRevisionId": otRevisionId,
        "tareaId": tareaId,
        "codTarea": codTarea,
        "descripcion": descripcion,
        "comentario": comentario,
      };

  RevisionTarea.empty() {
    otTareaId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    tareaId = 0;
    codTarea = '';
    descripcion = '';
    comentario = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
