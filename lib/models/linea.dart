// To parse this JSON data, do
//
//     final linea = lineaFromJson(jsonString);

import 'dart:convert';

List<Linea> lineaFromJson(String str) => List<Linea>.from(json.decode(str).map((x) => Linea.fromJson(x)));

String lineaToJson(List<Linea> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Linea {
  late int lineaId;
  late int ordenTrabajoId;
  late int itemId;
  late String codItem;
  late String descripcion;
  late String macroFamilia;
  late String familia;
  late String grupoInventario;
  late int ordinal;
  late double cantidad;
  late double costoUnitario;
  late int descuento1;
  late int descuento2;
  late int descuento3;
  late double precioVenta;
  late String comentario;
  late int ivaId;
  late String iva;
  late int valor;
  late String codGruInv;
  late int gruInvId;
  late int? avance;
  late String mo;

  Linea({
    required this.lineaId,
    required this.ordenTrabajoId,
    required this.itemId,
    required this.codItem,
    required this.descripcion,
    required this.macroFamilia,
    required this.familia,
    required this.grupoInventario,
    required this.ordinal,
    required this.cantidad,
    required this.costoUnitario,
    required this.descuento1,
    required this.descuento2,
    required this.descuento3,
    required this.precioVenta,
    required this.comentario,
    required this.ivaId,
    required this.iva,
    required this.valor,
    required this.codGruInv,
    required this.gruInvId,
    required this.avance,
    required this.mo,
  });

  factory Linea.fromJson(Map<String, dynamic> json) => Linea(
    lineaId: json["LineaId"] as int? ?? 0,
    ordenTrabajoId: json["OrdenTrabajoId"] as int? ?? 0,
    itemId: json["ItemId"] as int? ?? 0,
    codItem: json["CodItem"] as String? ?? '',
    descripcion: json["Descripcion"] as String? ?? '',
    macroFamilia: json["MacroFamilia"] as String? ?? '',
    familia: json["Familia"] as String? ?? '',
    grupoInventario: json["GrupoInventario"] as String? ?? '',
    ordinal: json["Ordinal"] as int? ?? 0,
    cantidad: json["Cantidad"]?.toDouble(),
    costoUnitario: json["CostoUnitario"]?.toDouble(),
    descuento1: json["Descuento1"] as int? ?? 0,
    descuento2: json["Descuento2"] as int? ?? 0,
    descuento3: json["Descuento3"] as int? ?? 0,
    precioVenta: json["PrecioVenta"]?.toDouble(),
    comentario: json["Comentario"] as String? ?? '',
    ivaId: json["IvaId"] as int? ?? 0,
    iva: json["IVA"] as String? ?? '',
    valor: json["Valor"] as int? ?? 0,
    codGruInv: json["CodGruInv"] as String? ?? '',
    gruInvId: json["GruInvId"] as int? ?? 0,
    avance: json["Avance"] as int? ?? 0,
    mo: json["MO"] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    "LineaId": lineaId,
    "OrdenTrabajoId": ordenTrabajoId,
    "ItemId": itemId,
    "CodItem": codItem,
    "Descripcion": descripcion,
    "MacroFamilia": macroFamilia,
    "Familia": familia,
    "GrupoInventario": grupoInventario,
    "Ordinal": ordinal,
    "Cantidad": cantidad,
    "CostoUnitario": costoUnitario,
    "Descuento1": descuento1,
    "Descuento2": descuento2,
    "Descuento3": descuento3,
    "PrecioVenta": precioVenta,
    "Comentario": comentario,
    "IvaId": ivaId,
    "IVA": iva,
    "Valor": valor,
    "CodGruInv": codGruInv,
    "GruInvId": gruInvId,
    "Avance": avance,
    "MO": mo,
  };

  Linea.empty(){
    lineaId = 0;
    ordenTrabajoId = 0;
    itemId = 0;
    codItem = '';
    descripcion = '';
    macroFamilia = '';
    familia = '';
    grupoInventario = '';
    ordinal = 0;
    cantidad = 0;
    costoUnitario = 0.0;
    descuento1 = 0;
    descuento2 = 0;
    descuento3 = 0;
    precioVenta = 0.0;
    comentario = '';
    ivaId = 0;
    iva = '';
    valor = 0;
    codGruInv = '';
    gruInvId = 0;
    avance = 0;
    mo = '';
  }
}
