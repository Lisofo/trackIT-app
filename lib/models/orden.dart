// To parse this JSON data, do
//
//     final orden = ordenFromMap(jsonString);

import 'dart:convert';

import 'cliente.dart';
import 'servicio_ordenes.dart';
import 'tecnico.dart';

List<Orden> ordenFromMap(String str) =>
    List<Orden>.from(json.decode(str).map((x) => Orden.fromJson(x)));

String ordenToMap(List<Orden> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Orden {
  late int ordenTrabajoId;
  late DateTime fechaOrdenTrabajo;
  late DateTime fechaDesde;
  late DateTime fechaHasta;
  late String instrucciones;
  late dynamic comentarios;
  late String estado;
  late TipoOrden tipoOrden;
  late Cliente cliente;
  late Tecnico tecnico;
  late List<ServicioOrdenes> servicio;
  late int otRevisionId;
  late int planoId;

  Orden({
    required this.ordenTrabajoId,
    required this.fechaOrdenTrabajo,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.instrucciones,
    required this.comentarios,
    required this.estado,
    required this.tipoOrden,
    required this.cliente,
    required this.tecnico,
    required this.servicio,
    required this.otRevisionId,
    required this.planoId,
  });

  factory Orden.fromJson(Map<String, dynamic> json) => Orden(
        ordenTrabajoId: json["ordenTrabajoId"],
        fechaOrdenTrabajo: DateTime.parse(json["fechaOrdenTrabajo"]),
        fechaDesde: DateTime.parse(json["fechaDesde"]),
        fechaHasta: DateTime.parse(json["fechaHasta"]),
        instrucciones: json["instrucciones"] as String? ?? '',
        comentarios: json["comentarios"] as String? ?? '',
        estado: json["estado"],
        tipoOrden: TipoOrden.fromMap(json["tipoOrden"]),
        cliente: Cliente.fromJson(json["cliente"]),
        tecnico: Tecnico.fromJson(json["tecnico"]),
        servicio: List<ServicioOrdenes>.from(
            json["servicios"].map((x) => ServicioOrdenes.fromJson(x))),
        otRevisionId: json["otRevisionId"] as int? ?? 0,
        planoId: json["planoId"] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        "ordenTrabajoId": ordenTrabajoId,
        "fechaOrdenTrabajo": fechaOrdenTrabajo.toIso8601String(),
        "fechaDesde": fechaDesde.toIso8601String(),
        "fechaHasta": fechaHasta.toIso8601String(),
        "instrucciones": instrucciones,
        "comentarios": comentarios,
        "estado": estado,
        "tipoOrden": tipoOrden.toMap(),
        "cliente": cliente.toMap(),
        "tecnico": tecnico.toMap(),
        "otRevisionId": otRevisionId,
        "planoId": planoId,
      };

  Orden.empty() {
    ordenTrabajoId = 0;
    fechaOrdenTrabajo = DateTime.now();
    fechaDesde = DateTime.now();
    fechaHasta = DateTime.now();
    instrucciones = '';
    comentarios = '';
    estado = '';
    tipoOrden = TipoOrden.empty();
    cliente = Cliente.empty();
    tecnico = Tecnico.empty();
    otRevisionId = 0;
    planoId = 0;
  }
}

class TipoOrden {
  late int tipoOrdenId;
  late String codTipoOrden;
  late String descripcion;

  TipoOrden({
    required this.tipoOrdenId,
    required this.codTipoOrden,
    required this.descripcion,
  });

  factory TipoOrden.fromMap(Map<String, dynamic> json) => TipoOrden(
        tipoOrdenId: json["tipoOrdenId"],
        codTipoOrden: json["codTipoOrden"],
        descripcion: json["descripcion"],
      );

  Map<String, dynamic> toMap() => {
        "tipoOrdenId": tipoOrdenId,
        "codTipoOrden": codTipoOrden,
        "descripcion": descripcion,
      };

  TipoOrden.empty() {
    tipoOrdenId = 0;
    codTipoOrden = '';
    descripcion = '';
  }
}
