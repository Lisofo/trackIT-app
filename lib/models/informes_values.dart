// To parse this JSON data, do
//
//     final informesValues = informesValuesFromJson(jsonString);

import 'dart:convert';

List<ParametrosValues> informesValuesFromJson(String str) => List<ParametrosValues>.from(json.decode(str).map((x) => ParametrosValues.fromJson(x)));

String informesValuesToJson(List<ParametrosValues> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ParametrosValues {
  late int id;
  late String descripcion;

  ParametrosValues({
    required this.id,
    required this.descripcion,
  });

  factory ParametrosValues.fromJson(Map<String, dynamic> json) => ParametrosValues(
    id: json['id'] as int? ?? 0,
    descripcion: json['descripcion'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "clienteId": id,
    "nombre": descripcion,
  };

  ParametrosValues.empty(){
    id = 0;
    descripcion = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
