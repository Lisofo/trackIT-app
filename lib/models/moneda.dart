import 'dart:convert';

List<Moneda> monedaFromMap(String str) => List<Moneda>.from(json.decode(str).map((x) => Moneda.fromJson(x)));

String monedaToMap(List<Moneda> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Moneda {
  final int? monedaId;
  final String? codMoneda;
  final String? descripcion;
  final String? signo;

  Moneda({
    this.monedaId,
    this.codMoneda,
    this.descripcion,
    this.signo,
  });

  factory Moneda.fromJson(Map<String, dynamic> json) => Moneda(
    monedaId: json["monedaId"] as int?,
    codMoneda: json["codMoneda"] as String?,
    descripcion: json["descripcion"] as String?,
    signo: json["signo"] as String?,
  );

  Map<String, dynamic> toMap() => {
    "monedaId": monedaId,
    "codMoneda": codMoneda,
    "descripcion": descripcion,
    "signo": signo,
  };

  factory Moneda.empty() => Moneda(
    monedaId: null,
    codMoneda: null,
    descripcion: null,
    signo: null,
  );

  @override
  String toString() {
    return '$descripcion ($signo)';
  }
}