// To parse this JSON data, do
//
//     final orden = ordenFromMap(jsonString);

import 'dart:convert';

import 'package:app_tec_sedel/models/unidad.dart';
import 'package:intl/intl.dart';

import 'cliente.dart';
import 'servicio_ordenes.dart';
import 'tecnico.dart';

List<Orden> ordenFromMap(String str) => List<Orden>.from(json.decode(str).map((x) => Orden.fromJson(x)));

String ordenToMap(List<Orden> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Orden {
  late int ordenTrabajoId;
  late String numeroOrdenTrabajo;
  late String descripcion;
  late DateTime? fechaOrdenTrabajo;
  late DateTime? fechaVencimiento;
  late DateTime? fechaEntrega;
  late DateTime? fechaDesde;
  late DateTime? fechaHasta;
  late String ruc;
  late int monedaId;
  late String codMoneda;
  late String descMoneda;
  late String signo;
  late double totalOrdenTrabajo;
  late String comentarioCliente;
  late String comentarios;
  late String comentarioTrabajo;
  late int? presupuestoIdPlantilla;
  late int? numeroPresupuesto;
  late String? descripcionPresupuesto;
  late int? totalPresupuesto;
  late bool plantilla;
  late int unidadId;
  late String? matricula;
  late int? km;
  late bool? regHs;
  late String instrucciones;
  late String estado;
  late TipoOrden tipoOrden;
  late Cliente cliente;
  late Tecnico tecnico;
  late Unidad unidad;
  late List<ServicioOrdenes> servicio;
  late int otRevisionId;
  late int planoId;
  late int? tecnicoId;
  late bool alerta;

  Orden({
    required this.ordenTrabajoId,
    required this.numeroOrdenTrabajo,
    required this.descripcion,
    required this.fechaOrdenTrabajo,
    required this.fechaVencimiento,
    required this.fechaEntrega,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.ruc,
    required this.monedaId,
    required this.codMoneda,
    required this.descMoneda,
    required this.signo,
    required this.totalOrdenTrabajo,
    required this.comentarioCliente,
    required this.comentarios,
    required this.comentarioTrabajo,
    required this.estado,
    required this.presupuestoIdPlantilla,
    required this.numeroPresupuesto,
    required this.descripcionPresupuesto,
    required this.totalPresupuesto,
    required this.plantilla,
    required this.unidadId,
    required this.matricula,
    required this.km,
    required this.regHs,
    required this.instrucciones,
    required this.tipoOrden,
    required this.cliente,
    required this.tecnico,
    required this.servicio,
    required this.otRevisionId,
    required this.planoId,
    required this.alerta,
    required this.unidad,
    this.tecnicoId,
  });

  factory Orden.fromJson(Map<String, dynamic> json) => Orden(
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    numeroOrdenTrabajo: json["numeroOrdenTrabajo"] as String? ?? "",
    descripcion: json["descripcion"] as String? ?? '',
    fechaOrdenTrabajo: json["fechaOrdenTrabajo"] != null ? DateTime.parse(json["fechaOrdenTrabajo"]) : null,
    fechaVencimiento: json["fechaVencimiento"] != null ?  DateTime.parse(json["fechaVencimiento"]) : null,
    fechaEntrega: json["fechaEntrega"] == null ? null : DateTime.parse(json["fechaEntrega"]),
    fechaDesde: json["fechaDesde"] != null ? DateTime.parse(json["fechaDesde"]) : null,
    fechaHasta: json["fechaDesde"] != null ? DateTime.parse(json["fechaHasta"]) : null,
    ruc: json["ruc"] as String? ?? '',
    monedaId: json["monedaId"] as int? ?? 0,
    codMoneda: json["codMoneda"] as String? ?? '',
    descMoneda: json["descMoneda"] as String? ?? '',
    signo: json["signo"] as String? ?? '',
    totalOrdenTrabajo: json["totalOrdenTrabajo"]?.toDouble(),
    comentarioCliente: json["comentarioCliente"] as String? ?? '',
    comentarioTrabajo: json["comentarioTrabajo"] as String? ?? '',
    estado: json["estado"] as String? ?? '',
    presupuestoIdPlantilla: json["presupuestoIdPlantilla"] as int? ?? 0,
    numeroPresupuesto: json["numeroPresupuesto"] as int? ?? 0,
    descripcionPresupuesto: json["descripcionPresupuesto"] as String? ?? '',
    totalPresupuesto: json["totalPresupuesto"] as int? ?? 0,
    plantilla: json["plantilla"],
    unidadId: json["unidadId"] as int? ?? 0,
    matricula: json["matricula"] as String? ?? '',
    km: json["km"] as int? ?? 0,
    regHs: json["regHs"],
    instrucciones: json["instrucciones"] as String? ?? '',
    comentarios: json["comentarios"] as String? ?? '',
    tipoOrden: json["tipoOrden"] == null ? TipoOrden.empty() : TipoOrden.fromJson(json["tipoOrden"]),
    cliente: json["cliente"] == null ? Cliente.empty() : Cliente.fromJson(json["cliente"]),
    tecnico: json["tecnico"] == null ? Tecnico.empty() : Tecnico.fromJson(json["tecnico"]),
    unidad: json["unidad"] == null ? Unidad.empty() : Unidad.fromJson(json["unidad"]),
    servicio: [],//List<ServicioOrdenes>.from(json["servicios"].map((x) => ServicioOrdenes.fromJson(x))),
    otRevisionId: json["otRevisionId"] as int? ?? 0,
    planoId: json["planoId"] as int? ?? 0,
    alerta: json["alerta"] == null ? false : json["alerta"] as bool,
    tecnicoId: json["tecnicoId"] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    "ordenTrabajoId": ordenTrabajoId,
    "numeroOrdenTrabajo": numeroOrdenTrabajo,
    "descripcion": descripcion,
    "fechaOrdenTrabajo": fechaOrdenTrabajo?.toIso8601String(),
    "fechaVencimiento": fechaVencimiento?.toIso8601String(),
    "fechaEntrega": fechaEntrega?.toIso8601String(),
    "fechaDesde": fechaDesde?.toIso8601String(),
    "fechaHasta": fechaHasta?.toIso8601String(),
    "ruc": ruc,
    "monedaId": monedaId,
    "codMoneda": codMoneda,
    "descMoneda": descMoneda,
    "signo": signo,
    "totalOrdenTrabajo": totalOrdenTrabajo,
    "comentarioCliente": comentarioCliente,
    "comentarios": comentarios,
    "comentarioTrabajo": comentarioTrabajo,
    "estado": estado,
    "presupuestoIdPlantilla": presupuestoIdPlantilla,
    "numeroPresupuesto": numeroPresupuesto,
    "descripcionPresupuesto": descripcionPresupuesto,
    "totalPresupuesto": totalPresupuesto,
    "plantilla": plantilla,
    "unidadId": unidadId,
    "matricula": matricula,
    "km": km,
    "regHs": regHs,
    "instrucciones": instrucciones,
    "tipoOrden": tipoOrden.toMap(),
    "cliente": cliente.toMap(),
    "tecnico": tecnico.toMap(),
    "unidad": unidad.toJson(),
    "otRevisionId": otRevisionId,
    "planoId": planoId,
    "alerta": alerta,
  };

  Map<String, dynamic> toMapCyP() => {
    "tipoOrdenId": 5,
    "clienteId": cliente.clienteId,
    "tecnicoId": tecnicoId,
    "unidadId": unidad.unidadId,
    "numeroOrdenTrabajo": numeroOrdenTrabajo,
    "descripcion": descripcion,
    "fechaOrdenTrabajo": getStringFecha(fechaOrdenTrabajo),
    "fechaDesde": getStringFechaConHoraMinSec(fechaDesde),
    "fechaHasta": getStringFechaConHoraMinSec(fechaHasta),
    "monedaId": 1,
    "totalOrdenTrabajo": totalOrdenTrabajo,
    "comentarioCliente": comentarioCliente,
    "comentarios": comentarios,
    "comentarioTrabajo": comentarioTrabajo,
    "km": km,
    "instrucciones": instrucciones,
    "plantilla": false,
  };

  String getStringFecha (DateTime? fecha) {
    if (fecha == null) return '';
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(fecha);
  }

  String getStringFechaConHoraMinSec (DateTime? fecha) {
    if (fecha == null) return '';
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(fecha);
  }

  Orden.empty() {
    ordenTrabajoId = 0;
    numeroOrdenTrabajo = '';
    descripcion = '';
    fechaOrdenTrabajo = null;
    fechaVencimiento = null;
    fechaEntrega = null;
    fechaDesde = null;
    fechaHasta = null;
    ruc = '';
    monedaId = 0;
    codMoneda = '';
    descMoneda = ''; 
    signo = '';
    totalOrdenTrabajo = 0.0;
    comentarioCliente = '';
    comentarios = '';
    comentarioTrabajo = '';
    estado = '';
    presupuestoIdPlantilla = null;
    numeroPresupuesto = null;
    descripcionPresupuesto = null;
    totalPresupuesto = null;
    plantilla = false;
    unidadId = 0;
    matricula = '';
    km = 0;
    regHs = false;
    instrucciones = '';
    estado = '';
    tipoOrden = TipoOrden.empty();
    cliente = Cliente.empty();
    tecnico = Tecnico.empty();
    unidad = Unidad.empty();
    servicio = [];
    otRevisionId = 0;
    planoId = 0;
    alerta = false;
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

  factory TipoOrden.fromJson(Map<String, dynamic> json) => TipoOrden(
    tipoOrdenId: json["tipoOrdenId"] as int? ?? 0,
    codTipoOrden: json["codTipoOrden"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
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
