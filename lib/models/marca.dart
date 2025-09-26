// To parse this JSON data, do
//
//     final marca = marcaFromJson(jsonString);

import 'dart:convert';

List<Marca> marcaFromJson(String str) => List<Marca>.from(json.decode(str).map((x) => Marca.fromJson(x)));

String marcaToJson(List<Marca> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Marca {
  late int marcaId;
  late String descripcion;
  late bool paraVenta;
  late String orden;

  Marca({
    required this.marcaId,
    required this.descripcion,
    required this.paraVenta,
    required this.orden,
  });

  Marca copyWith({
    int? marcaId,
    String? descripcion,
    bool? paraVenta,
    String? orden,
  }) => 
      Marca(
        marcaId: marcaId ?? this.marcaId,
        descripcion: descripcion ?? this.descripcion,
        paraVenta: paraVenta ?? this.paraVenta,
        orden: orden ?? this.orden,
      );

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
    marcaId: json["marcaId"] as int? ?? 0,
    descripcion: json["descripcion"] as String? ?? '',
    paraVenta: json["paraVenta"] as bool? ?? false,
    orden: json["orden"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "marcaId": marcaId,
    "descripcion": descripcion,
    "paraVenta": paraVenta,
    "orden": orden,
  };

  Marca.empty() {
    marcaId = 0;
    descripcion = '';
    paraVenta = false;
    orden = '';
  }
}