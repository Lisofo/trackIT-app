import 'dart:convert';

List<Control> controlFromMap(String str) => List<Control>.from(json.decode(str).map((x) => Control.fromJson(x)));

String controlToMap(List<Control> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Control {
  late int controlId;
  late int ordenTrabajoId;
  late int ordinal;
  late String grupo;
  late String pregunta;
  late String respuesta;
  late int claveRespuesta;
  late String? comentario;

  Control({
    required this.controlId,
    required this.grupo,
    required this.pregunta,
    required this.comentario,
    required this.ordenTrabajoId,
    required this.ordinal,
    required this.respuesta,
    required this.claveRespuesta,
  });

  factory Control.fromJson(Map<String, dynamic> json) => Control(
    controlId: json["controlId"] as int? ?? 0,
    grupo: json["grupo"] as String? ?? '',
    pregunta: json["pregunta"] as String? ?? '',
    comentario: json["comentario"] as String? ?? '', 
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0, 
    ordinal: json["ordianl"] as int? ?? 0,
    respuesta: json["respuesta"] as String? ?? '',
    claveRespuesta: json["claveRespuesta"] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    "controlId": controlId,
    "grupo": grupo,
    "pregunta": pregunta,
    "comentario": '',
  };

  Control.empty(){
    controlId = 0;
    grupo = '';
    pregunta = '';
    comentario = '';
    ordenTrabajoId = 0;
    ordinal = 0;
    respuesta = '';
    claveRespuesta = 0;
  }
}
