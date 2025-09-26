// To parse this JSON data, do
//
//     final modelo = modeloFromJson(jsonString);

import 'dart:convert';

List<Modelo> modeloFromJson(String str) => List<Modelo>.from(json.decode(str).map((x) => Modelo.fromJson(x)));

String modeloToJson(List<Modelo> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Modelo {
  late int modeloId;
  late int marcaId;
  late String descripcion;
  late bool paraVenta;
  late String orden;
  late String codMarca;
  late String marca;

  Modelo({
    required this.modeloId,
    required this.marcaId,
    required this.descripcion,
    required this.paraVenta,
    required this.orden,
    required this.codMarca,
    required this.marca,
  });

  Modelo copyWith({
    int? modeloId,
    int? marcaId,
    String? descripcion,
    bool? paraVenta,
    String? orden,
    String? codMarca,
    String? marca,
  }) => 
      Modelo(
        modeloId: modeloId ?? this.modeloId,
        marcaId: marcaId ?? this.marcaId,
        descripcion: descripcion ?? this.descripcion,
        paraVenta: paraVenta ?? this.paraVenta,
        orden: orden ?? this.orden,
        codMarca: codMarca ?? this.codMarca,
        marca: marca ?? this.marca,
      );

  factory Modelo.fromJson(Map<String, dynamic> json) => Modelo(
    modeloId: json["modeloId"] as int? ?? 0,
    marcaId: json["marcaId"] as int? ?? 0,
    descripcion: json["descripcion"] as String? ?? '',
    paraVenta: json["paraVenta"] as bool? ?? false,
    orden: json["orden"] as String? ?? '',
    codMarca: json["codMarca"] as String? ?? '',
    marca: json["marca"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "modeloId": modeloId,
    "marcaId": marcaId,
    "descripcion": descripcion,
    "paraVenta": paraVenta,
    "orden": orden,
    "codMarca": codMarca,
    "marca": marca,
  };

  Modelo.empty() {
    modeloId = 0;
    marcaId = 0;
    descripcion = '';
    paraVenta = false;
    orden = '';
    codMarca = '';
    marca = '';
  }
}