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
    lineaId: json["lineaId"] as int? ?? 0,
    ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    macroFamilia: json["macroFamilia"] as String? ?? '',
    familia: json["familia"] as String? ?? '',
    grupoInventario: json["grupoInventario"] as String? ?? '',
    ordinal: json["ordinal"] as int? ?? 0,
    cantidad: json["cantidad"]?.toDouble() as double? ?? 0.0,
    costoUnitario: json["costoUnitario"]?.toDouble() as double? ?? 0.0,
    descuento1: json["descuento1"] as int? ?? 0,
    descuento2: json["descuento2"] as int? ?? 0,
    descuento3: json["descuento3"] as int? ?? 0,
    precioVenta: json["precioVenta"]?.toDouble() as double? ?? 0.0,
    comentario: json["comentario"] as String? ?? '',
    ivaId: json["ivaId"] as int? ?? 0,
    iva: json["IVA"] as String? ?? '',
    valor: json["valor"] as int? ?? 0,
    codGruInv: json["codGruInv"] as String? ?? '',
    gruInvId: json["gruInvId"] as int? ?? 0,
    avance: json["avance"] as int? ?? 0,
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

  String getAvanceEnHorasMinutos() {
    if (avance == null || avance! < 0) return "0:00";  // Manejo de nulos o valores negativos

    int horas = avance! < 60 ? 0 : avance! ~/ 60; // División entera para obtener las horas
    int minutos = avance! % 60; // Resto para obtener los minutos

    // Formatear el resultado en "hh:mm"
    String horasStr = horas.toString();
    String minutosStr = minutos.toString().padLeft(2, '0');  // Asegurar que siempre sean dos dígitos
    print(horasStr);
    print(minutosStr);
    return "$horasStr:$minutosStr";
  }

}
