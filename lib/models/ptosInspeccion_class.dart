// To parse this JSON data, do
//
//     final ptosInspeccion = ptosInspeccionFromMap(jsonString);

// ignore_for_file: file_names

import 'dart:convert';

List<PtosInspeccion> ptosInspeccionFromMap(String str) =>  List<PtosInspeccion>.from(
        json.decode(str).map((x) => PtosInspeccion.fromJson(x)));

String ptosInspeccionToMap(List<PtosInspeccion> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class PtosInspeccion {
  late int puntoInspeccionId;
  late int planoId;
  late String codPuntoInspeccion;
  late String zona;
  late String sector;
  late String codigoBarra;
  late int tipoPuntoInspeccionId;
  late String codTipoPuntoInspeccion;
  late String descTipoPunto;
  late int plagaObjetivoId;
  late String codPlagaObjetivo;
  late String descPlagaObjetivo;
  late DateTime desde;
  late String estado;
  late String subEstado;
  late String comentario;
  late bool seleccionado;

  PtosInspeccion({
    required this.puntoInspeccionId,
    required this.planoId,
    required this.codPuntoInspeccion,
    required this.zona,
    required this.sector,
    required this.codigoBarra,
    required this.tipoPuntoInspeccionId,
    required this.codTipoPuntoInspeccion,
    required this.descTipoPunto,
    required this.plagaObjetivoId,
    required this.codPlagaObjetivo,
    required this.descPlagaObjetivo,
    required this.desde,
    required this.estado,
    required this.subEstado,
    required this.comentario,
    required this.seleccionado
  });

  factory PtosInspeccion.fromJson(Map<String, dynamic> json) => PtosInspeccion(
        puntoInspeccionId: json["puntoInspeccionId"],
        planoId: json["planoId"],
        codPuntoInspeccion: json["codPuntoInspeccion"],
        zona: json["zona"],
        sector: json["sector"],
        codigoBarra: json["codigoBarra"],
        tipoPuntoInspeccionId: json["tipoPuntoInspeccionId"],
        codTipoPuntoInspeccion: json["codTipoPuntoInspeccion"],
        descTipoPunto: json["descTipoPunto"],
        plagaObjetivoId: json["plagaObjetivoId"],
        codPlagaObjetivo: json["codPlagaObjetivo"],
        descPlagaObjetivo: json["descPlagaObjetivo"],
        desde: DateTime.parse(json["desde"]),
        estado: json["estado"],
        subEstado: json["subEstado"],
        comentario: json["comentario"],
        seleccionado: false,
      );

  Map<String, dynamic> toMap() => {
        "puntoInspeccionId": puntoInspeccionId,
        "planoId": planoId,
        "codPuntoInspeccion": codPuntoInspeccion,
        "zona": zona,
        "sector": sector,
        "codigoBarra": codigoBarra,
        "tipoPuntoInspeccionId": tipoPuntoInspeccionId,
        "codTipoPuntoInspeccion": codTipoPuntoInspeccion,
        "descTipoPunto": descTipoPunto,
        "plagaObjetivoId": plagaObjetivoId,
        "codPlagaObjetivo": codPlagaObjetivo,
        "descPlagaObjetivo": descPlagaObjetivo,
        "desde": desde.toIso8601String(),
        "estado": estado,
        "subEstado": subEstado,
        "comentario": comentario,
      };

  PtosInspeccion.empty() {
    puntoInspeccionId = 0;
    planoId = 0;
    codPuntoInspeccion = '';
    zona = '';
    sector = '';
    codigoBarra = '';
    tipoPuntoInspeccionId = 0;
    codTipoPuntoInspeccion = '';
    descTipoPunto = '';
    plagaObjetivoId = 0;
    codPlagaObjetivo = '';
    descPlagaObjetivo = '';
    desde = DateTime.now();
    estado = '';
    subEstado = '';
    comentario = '';
  }
}
