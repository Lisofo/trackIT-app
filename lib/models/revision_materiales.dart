// To parse this JSON data, do
//
//     final revisionMateriales = revisionMaterialesFromMap(jsonString);

import 'dart:convert';

import 'package:app_track_it/models/material.dart';
import 'package:app_track_it/models/plaga.dart';

RevisionMaterial revisionMaterialesFromMap(String str) => RevisionMaterial.fromJson(json.decode(str));

String revisionMaterialesToMap(RevisionMaterial data) =>
    json.encode(data.toMap());

class RevisionMaterial {
  late int otMaterialId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late double cantidad;
  late String comentario;
  late String ubicacion;
  late String areaCobertura;
  late List<Plaga> plagas;
  late Materiales material;
  late Lote lote;
  late MetodoAplicacion metodoAplicacion;

  RevisionMaterial({
    required this.otMaterialId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.cantidad,
    required this.comentario,
    required this.ubicacion,
    required this.areaCobertura,
    required this.plagas,
    required this.material,
    required this.lote,
    required this.metodoAplicacion,
  });

  factory RevisionMaterial.fromJson(Map<String, dynamic> json) =>
      RevisionMaterial(
        otMaterialId: json["otMaterialId"] as int? ?? 0,
        ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
        otRevisionId: json["otRevisionId"] as int? ?? 0,
        cantidad: json["cantidad"]?.toDouble() as double? ?? 0.0,
        comentario: json["comentario"] as String? ?? '',
        ubicacion: json["ubicacion"] as String? ?? '',
        areaCobertura: json["areaCobertura"] as String? ?? '',
        plagas: List<Plaga>.from(json["plagas"].map((x) => Plaga.fromJson(x))),
        material: Materiales.fromJson(json["material"]),
        lote: Lote.fromJson(json["lote"]),
        metodoAplicacion: MetodoAplicacion.fromJson(json["metodoAplicacion"]),
      );

  Map<String, dynamic> toMap() => {
        "otMaterialId": otMaterialId,
        "ordenTrabajoId": ordenTrabajoId,
        "otRevisionId": otRevisionId,
        "cantidad": cantidad,
        "comentario": comentario,
        "ubicacion": ubicacion,
        "areaCobertura": areaCobertura,
        "plagas": List<dynamic>.from(plagas.map((x) => x.toMap())),
        "material": material.toMap(),
        "lote": lote.toMap(),
        "metodoAplicacion": metodoAplicacion.toMap(),
      };

  RevisionMaterial.empty() {
    otMaterialId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    cantidad = 0.0;
    comentario = '';
    ubicacion = '';
    areaCobertura = '';
    plagas = [];
    material = Materiales.empty();
    lote = Lote.empty();
    metodoAplicacion = MetodoAplicacion.empty();
  }

  @override
  String toString() {
    return material.descripcion;
  }
}

class Lote {
  late int materialLoteId;
  late String lote;

  Lote({
    required this.materialLoteId,
    required this.lote,
  });

  factory Lote.fromJson(Map<String, dynamic> json) => Lote(
        materialLoteId: json["materialLoteId"] as int? ?? 0,
        lote: json["lote"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "materialLoteId": materialLoteId,
        "lote": lote,
      };

  Lote.empty() {
    materialLoteId = 0;
    lote = '';
  }

  @override
  String toString() {
    return lote;
  }
}

class MetodoAplicacion {
  late int metodoAplicacionId;
  late String codMetodoAplicacion;
  late String descripcion;

  MetodoAplicacion({
    required this.metodoAplicacionId,
    required this.codMetodoAplicacion,
    required this.descripcion,
  });

  factory MetodoAplicacion.fromJson(Map<String, dynamic> json) =>
      MetodoAplicacion(
        metodoAplicacionId: json["metodoAplicacionId"] as int? ?? 0,
        codMetodoAplicacion: json["codMetodoAplicacion"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "metodoAplicacionId": metodoAplicacionId,
        "codMetodoAplicacion": codMetodoAplicacion,
        "descripcion": descripcion,
      };

  MetodoAplicacion.empty() {
    metodoAplicacionId = 0;
    codMetodoAplicacion = '';
    descripcion = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
