// To parse this JSON data, do
//
//     final tarifa = tarifaFromJson(jsonString);

import 'dart:convert';

List<Tarifa> tarifaFromJson(String str) => List<Tarifa>.from(json.decode(str).map((x) => Tarifa.fromJson(x)));

String tarifaToJson(List<Tarifa> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Tarifa {
  late int? tarifaId;
  late String? codTarifa;
  late String? descripcion;
  late int? valor;

    Tarifa({
        this.tarifaId,
        this.codTarifa,
        this.descripcion,
        this.valor,
    });

    Tarifa copyWith({
        int? tarifaId,
        String? codTarifa,
        String? descripcion,
        int? valor,
    }) => 
        Tarifa(
            tarifaId: tarifaId ?? this.tarifaId,
            codTarifa: codTarifa ?? this.codTarifa,
            descripcion: descripcion ?? this.descripcion,
            valor: valor ?? this.valor,
        );

    factory Tarifa.fromJson(Map<String, dynamic> json) => Tarifa(
        tarifaId: json["tarifaId"] as int? ?? 0,
        codTarifa: json["codTarifa"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
        valor: json["valor"] as int? ?? 0,
    );

    Map<String, dynamic> toJson() => {
        "tarifaId": tarifaId,
        "codTarifa": codTarifa,
        "descripcion": descripcion,
        "valor": valor,
    };

  Tarifa.empty() {
    tarifaId = 0;
    codTarifa = '';
    descripcion = '';
    valor = 0;
  }
}
