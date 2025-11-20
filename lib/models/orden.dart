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
  late int? ordenTrabajoId;
  late String? numeroOrdenTrabajo;
  late String? descripcion;
  late DateTime? fechaOrdenTrabajo;
  late DateTime? fechaVencimiento;
  late DateTime? fechaEntrega;
  late DateTime? fechaDesde;
  late DateTime? fechaHasta;
  late String? ruc;
  late int? monedaId;
  late String? codMoneda;
  late String? descMoneda;
  late String? signo;
  late double? totalOrdenTrabajo;
  late String? comentarioCliente;
  late String? comentarios;
  late String? comentarioTrabajo;
  late int? presupuestoIdPlantilla;
  late int? numeroPresupuesto;
  late String? descripcionPresupuesto;
  late int? totalPresupuesto;
  late bool? plantilla;
  late int? unidadId;
  late String? matricula;
  late int? km;
  late bool? regHs;
  late String? instrucciones;
  late String? estado;
  late TipoOrden? tipoOrden;
  late Cliente? cliente;
  late Tecnico? tecnico;
  late Unidad? unidad;
  late List<ServicioOrdenes>? servicio;
  late int? otRevisionId;
  late int? planoId;
  late int? tecnicoId;
  late int? clienteId;
  late bool? alerta;
  late int? tipoOrdenId;
  
  // Nuevos campos del JSON
  late int? condOTId;
  late bool? credito;
  late int? alertaUsuId;
  late String? producto;
  late String? pedido;
  late String? envase;
  late int? totalTambores;
  late int? batches;
  late double? totalkgs;
  late double? mermaKgs;
  late double? mermaPorcentual;

  Orden({
    this.ordenTrabajoId,
    this.numeroOrdenTrabajo,
    this.descripcion,
    this.fechaOrdenTrabajo,
    this.fechaVencimiento,
    this.fechaEntrega,
    this.fechaDesde,
    this.fechaHasta,
    this.ruc,
    this.monedaId,
    this.codMoneda,
    this.descMoneda,
    this.signo,
    this.totalOrdenTrabajo,
    this.comentarioCliente,
    this.comentarios,
    this.comentarioTrabajo,
    this.estado,
    this.presupuestoIdPlantilla,
    this.numeroPresupuesto,
    this.descripcionPresupuesto,
    this.totalPresupuesto,
    this.plantilla,
    this.unidadId,
    this.matricula,
    this.km,
    this.regHs,
    this.instrucciones,
    this.tipoOrden,
    this.cliente,
    this.tecnico,
    this.unidad,
    this.servicio,
    this.otRevisionId,
    this.planoId,
    this.alerta,
    this.tipoOrdenId,
    this.tecnicoId,
    this.clienteId,
    // Nuevos campos
    this.condOTId,
    this.credito,
    this.alertaUsuId,
    this.producto,
    this.pedido,
    this.envase,
    this.totalTambores,
    this.batches,
    this.totalkgs,
    this.mermaKgs,
    this.mermaPorcentual,
  });

  factory Orden.fromJson(Map<String, dynamic> json) => Orden(
    ordenTrabajoId: json["ordenTrabajoId"] as int?,
    numeroOrdenTrabajo: json["numeroOrdenTrabajo"] as String?,
    descripcion: json["descripcion"] as String?,
    fechaOrdenTrabajo: json["fechaOrdenTrabajo"] != null ? DateTime.tryParse(json["fechaOrdenTrabajo"]) : null,
    fechaVencimiento: json["fechaVencimiento"] != null ? DateTime.tryParse(json["fechaVencimiento"]) : null,
    fechaEntrega: json["fechaEntrega"] != null ? DateTime.tryParse(json["fechaEntrega"]) : null,
    fechaDesde: json["fechaDesde"] != null ? DateTime.tryParse(json["fechaDesde"]) : null,
    fechaHasta: json["fechaHasta"] != null ? DateTime.tryParse(json["fechaHasta"]) : null,
    ruc: json["ruc"] as String?,
    monedaId: json["monedaId"] as int?,
    codMoneda: json["codMoneda"] as String?,
    descMoneda: json["descMoneda"] as String?,
    signo: json["signo"] as String?,
    totalOrdenTrabajo: (json["totalOrdenTrabajo"] as num?)?.toDouble(),
    comentarioCliente: json["comentarioCliente"] as String?,
    comentarios: json["comentarios"] as String?,
    comentarioTrabajo: json["comentarioTrabajo"] as String?,
    estado: json["estado"] as String?,
    presupuestoIdPlantilla: json["presupuestoIdPlantilla"] as int?,
    numeroPresupuesto: json["numeroPresupuesto"] as int?,
    descripcionPresupuesto: json["descripcionPresupuesto"] as String?,
    totalPresupuesto: json["totalPresupuesto"] as int?,
    plantilla: json["plantilla"] as bool?,
    unidadId: json["unidadId"] as int?,
    matricula: json["matricula"] as String?,
    km: json["km"] as int?,
    regHs: json["regHs"] as bool?,
    instrucciones: json["instrucciones"] as String?,
    tipoOrden: json["tipoOrden"] == null ? null : TipoOrden.fromJson(json["tipoOrden"]),
    cliente: json["cliente"] == null ? null : Cliente.fromJson(json["cliente"]),
    tecnico: json["tecnico"] == null ? null : Tecnico.fromJson(json["tecnico"]),
    unidad: json["unidad"] == null ? null : Unidad.fromJson(json["unidad"]),
    servicio: null, // Mantenemos null por ahora
    otRevisionId: json["otRevisionId"] as int?,
    planoId: json["planoId"] as int?,
    alerta: json["alerta"] as bool?,
    tecnicoId: json["tecnicoId"] as int?,
    clienteId: json["clienteId"] as int?,
    tipoOrdenId: json['tipoOrdenId'] as int?,
    // Nuevos campos
    condOTId: json["condOTId"] as int?,
    credito: json["credito"] as bool?,
    alertaUsuId: json["alertaUsuId"] as int?,
    producto: json["producto"] as String?,
    pedido: json["pedido"] as String?,
    envase: json["envase"] as String?,
    totalTambores: json["totalTambores"] as int?,
    batches: json["batches"] as int?,
    totalkgs: (json["totalkgs"] as num?)?.toDouble(),
    mermaKgs: (json["mermaKgs"] as num?)?.toDouble(),
    mermaPorcentual: (json["mermaPorcentual"] as num?)?.toDouble(),
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
    "tipoOrden": tipoOrden?.toMap(),
    "cliente": cliente?.toMap(),
    "tecnico": tecnico?.toMap(),
    "unidad": unidad?.toJson(),
    "otRevisionId": otRevisionId,
    "planoId": planoId,
    "alerta": alerta,
    "tecnicoId": tecnicoId,
    "clienteId": clienteId,
    "tipoOrdenId": tipoOrdenId,
    // Nuevos campos
    "condOTId": condOTId,
    "credito": credito,
    "alertaUsuId": alertaUsuId,
    "producto": producto,
    "pedido": pedido,
    "envase": envase,
    "totalTambores": totalTambores,
    "batches": batches,
    "totalkgs": totalkgs,
    "mermaKgs": mermaKgs,
    "mermaPorcentual": mermaPorcentual,
  };

  Map<String, dynamic> toMapCyP() => {
    "tipoOrdenId": tipoOrdenId,
    "clienteId": cliente?.clienteId,
    "tecnicoId": tecnicoId,
    "unidadId": unidad?.unidadId,
    "numeroOrdenTrabajo": numeroOrdenTrabajo,
    "descripcion": descripcion,
    "fechaOrdenTrabajo": getStringFecha(fechaOrdenTrabajo),
    "fechaDesde": getStringFechaConHoraMinSec(fechaDesde),
    "fechaHasta": getStringFechaConHoraMinSec(fechaHasta),
    "monedaId": monedaId ?? 1,
    "totalOrdenTrabajo": totalOrdenTrabajo,
    "comentarioCliente": comentarioCliente,
    "comentarios": comentarios,
    "comentarioTrabajo": comentarioTrabajo,
    "km": km,
    "instrucciones": instrucciones,
    "plantilla": plantilla ?? false,
  };

  String getStringFecha(DateTime? fecha) {
    if (fecha == null) return '';
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(fecha);
  }

  String getStringFechaConHoraMinSec(DateTime? fecha) {
    if (fecha == null) return '';
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(fecha);
  }

  factory Orden.empty() => Orden(
    ordenTrabajoId: null,
    numeroOrdenTrabajo: null,
    descripcion: null,
    fechaOrdenTrabajo: null,
    fechaVencimiento: null,
    fechaEntrega: null,
    fechaDesde: null,
    fechaHasta: null,
    ruc: null,
    monedaId: null,
    codMoneda: null,
    descMoneda: null,
    signo: null,
    totalOrdenTrabajo: null,
    comentarioCliente: null,
    comentarios: null,
    comentarioTrabajo: null,
    estado: null,
    presupuestoIdPlantilla: null,
    numeroPresupuesto: null,
    descripcionPresupuesto: null,
    totalPresupuesto: null,
    plantilla: null,
    unidadId: null,
    matricula: null,
    km: null,
    regHs: null,
    instrucciones: null,
    tipoOrden: null,
    cliente: null,
    tecnico: null,
    unidad: null,
    servicio: null,
    otRevisionId: null,
    planoId: null,
    alerta: null,
    tipoOrdenId: null,
    tecnicoId: null,
    clienteId: null,
    // Nuevos campos
    condOTId: null,
    credito: null,
    alertaUsuId: null,
    producto: null,
    pedido: null,
    envase: null,
    totalTambores: null,
    batches: null,
    totalkgs: null,
    mermaKgs: null,
    mermaPorcentual: null,
  );
}

class TipoOrden {
  final int? tipoOrdenId;
  final String? codTipoOrden;
  final String? descripcion;

  TipoOrden({
    this.tipoOrdenId,
    this.codTipoOrden,
    this.descripcion,
  });

  factory TipoOrden.fromJson(Map<String, dynamic> json) => TipoOrden(
    tipoOrdenId: json["tipoOrdenId"] as int?,
    codTipoOrden: json["codTipoOrden"] as String?,
    descripcion: json["descripcion"] as String?,
  );

  Map<String, dynamic> toMap() => {
    "tipoOrdenId": tipoOrdenId,
    "codTipoOrden": codTipoOrden,
    "descripcion": descripcion,
  };

  factory TipoOrden.empty() => TipoOrden(
    tipoOrdenId: null,
    codTipoOrden: null,
    descripcion: null,
  );
}