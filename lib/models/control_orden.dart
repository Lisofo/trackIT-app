// To parse this JSON data, do
//
//     final controlOrden = controlOrdenFromMap(jsonString);

import 'dart:convert';

List<ControlOrden> controlOrdenFromMap(String str) => List<ControlOrden>.from(json.decode(str).map((x) => ControlOrden.fromJson(x)));

String controlOrdenToMap(List<ControlOrden> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ControlOrden {
    late int controlRegId;
    late int ordenTrabajoId;
    late int controlId;
    late int ordinal;
    late String respuesta;
    late String comentario;
    late String grupo;
    late String pregunta;

    ControlOrden({
        required this.controlRegId,
        required this.ordenTrabajoId,
        required this.controlId,
        required this.ordinal,
        required this.respuesta,
        required this.comentario,
        required this.grupo,
        required this.pregunta,
    });

    factory ControlOrden.fromJson(Map<String, dynamic> json) => ControlOrden(
        controlRegId: json["controlRegId"] as int? ?? 0,
        ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
        controlId: json["controlId"] as int? ?? 0,
        ordinal: json["ordinal"] as int? ?? 0,
        respuesta: json["respuesta"] as String? ?? '',
        comentario: json["comentario"] as String? ?? '',
        grupo: json["grupo"] as String? ?? '',
        pregunta: json["pregunta"] as String? ?? '',
    );

    Map<String, dynamic> toMap() => {
        "controlRegId": controlRegId,
        "ordenTrabajoId": ordenTrabajoId,
        "controlId": controlId,
        "ordinal": controlId,
        "respuesta": respuesta,
        "comentario": comentario,
        "grupo": grupo,
        "pregunta": pregunta,
    };

    ControlOrden.empty(){
      controlRegId = 0;
      ordenTrabajoId = 0;
      controlId = 0;
      ordinal = 0;
      respuesta = '';
      comentario = '';
      grupo = '';
      pregunta = '';
    }
}
