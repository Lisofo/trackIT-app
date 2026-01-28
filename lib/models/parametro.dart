// To parse this JSON data, do
//
//     final parametro = parametroFromMap(jsonString);

import 'dart:convert';

List<Parametro> parametroFromMap(String str) => List<Parametro>.from(json.decode(str).map((x) => Parametro.fromJson(x)));

String parametroToMap(List<Parametro> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Parametro {
  late int informeId;
  late int parametroId;
  late String parametro;
  late String tipo;
  late int orden;
  late String control;
  late String comparador;
  late String? sql;
  late String? valor;
  late String? valorAMostrar;
  late String? dependeDe;
  late String  obligatorio;
  late String  valorPorDefecto;
  late String  tieneLista;

    Parametro({
      required this.informeId,
      required this.parametroId,
      required this.parametro,
      required this.tipo,
      required this.orden,
      required this.control,
      required this.comparador,
      required this.sql,
      required this.valor,
      required this.dependeDe,
      required this.valorAMostrar,
      required this.obligatorio,
      required this.valorPorDefecto,
      required this.tieneLista,
    });

    factory Parametro.fromJson(Map<String, dynamic> json) => Parametro(
      informeId: json["informeId"] as int? ?? 0,
      parametroId: json["parametroId"] as int? ?? 0,
      parametro: json["parametro"] as String? ?? '',
      tipo: json["tipo"] as String? ?? '',
      orden: json["orden"] as int? ?? 0,
      control: json["control"] as String? ?? '',
      comparador: json["comparador"] as String? ?? '',
      sql: json["sql"] as String? ?? '',
      valor: '',
      valorAMostrar: '',
      dependeDe: json['dependeDe'] as String? ?? '',
      obligatorio: json['obligatorio'] as String? ?? '',
      valorPorDefecto: json['valorPorDefecto'] as String? ?? '',
      tieneLista: json['tieneLista'] as String? ?? '',
    );

    Map<String, dynamic> toMap() => {
        "informeId": informeId,
        "parametroId": parametroId,
        "parametro": parametro,
        "tipo": tipo,
        "orden": orden,
        "control": control,
        "comparador": comparador,
        "sql": sql,
        'dependeDe': dependeDe,
        "obligatorio": obligatorio,
        "valorPorDefecto": valorPorDefecto,
        "tieneLista": tieneLista,
    };

  Parametro.empty(){
    informeId = 0;
    parametroId = 0;
    parametro = '';
    tipo = '';
    orden = 0;
    control = '';
    comparador = '';
    sql = '';
    valor = '';
    valorAMostrar = '';
    dependeDe = '';
    obligatorio = '';
    valorPorDefecto = '';
    tieneLista = '';
  }
}
