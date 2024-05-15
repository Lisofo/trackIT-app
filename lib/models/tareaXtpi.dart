// To parse this JSON data, do
//
//     final tareaXtpi = tareaXtpiFromMap(jsonString);

// ignore_for_file: file_names

import 'dart:convert';

List<TareaXtpi> tareaXtpiFromMap(String str) =>
    List<TareaXtpi>.from(json.decode(str).map((x) => TareaXtpi.fromJson(x)));

String tareaXtpiToMap(List<TareaXtpi> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class TareaXtpi {
  late int configTpiTareaId;
  late int tipoPuntoInspeccionId;
  late String modo;
  late int tareaId;
  late String codTarea;
  late String descripcion;
  late bool selected;

  TareaXtpi(
      {required this.configTpiTareaId,
      required this.tipoPuntoInspeccionId,
      required this.modo,
      required this.tareaId,
      required this.codTarea,
      required this.descripcion,
      required this.selected});

  factory TareaXtpi.fromJson(Map<String, dynamic> json) => TareaXtpi(
      configTpiTareaId: json["configTPITareaId"],
      tipoPuntoInspeccionId: json["tipoPuntoInspeccionId"],
      modo: json["modo"],
      tareaId: json["tareaId"],
      codTarea: json["codTarea"],
      descripcion: json["descripcion"],
      selected: false);

  Map<String, dynamic> toMap() => {
        "configTPITareaId": configTpiTareaId,
        "tipoPuntoInspeccionId": tipoPuntoInspeccionId,
        "modo": modo,
        "tareaId": tareaId,
        "codTarea": codTarea,
        "descripcion": descripcion,
        "selected": false,
      };
}
