import 'dart:convert';

List<Tarea> tareaFromMap(String str) =>
    List<Tarea>.from(json.decode(str).map((x) => Tarea.fromJson(x)));

String tareaToMap(List<Tarea> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Tarea {
  late int tareaId;
  late String codTarea;
  late String descripcion;

  Tarea({
    required this.tareaId,
    required this.codTarea,
    required this.descripcion,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) => Tarea(
        tareaId: json["tareaId"],
        codTarea: json["codTarea"],
        descripcion: json["descripcion"],
      );

  Map<String, dynamic> toMap() => {
        "tareaId": tareaId,
        "codTarea": codTarea,
        "descripcion": descripcion,
      };

  Tarea.empty() {
    tareaId = 0;
    codTarea = '';
    descripcion = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
