// To parse this JSON data, do
//
//     final tipoClientes = tipoClientesFromMap(jsonString);

import 'dart:convert';

List<TipoClientes> tipoClientesFromMap(String str) => List<TipoClientes>.from(
    json.decode(str).map((x) => TipoClientes.fromJson(x)));

String tipoClientesToMap(List<TipoClientes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class TipoClientes {
  late int tipoClienteId;
  late String codTipoCliente;
  late String descripcion;

  TipoClientes({
    required this.tipoClienteId,
    required this.codTipoCliente,
    required this.descripcion,
  });

  factory TipoClientes.fromJson(Map<String, dynamic> json) => TipoClientes(
        tipoClienteId: json["tipoClienteId"]as int? ?? 0,
        codTipoCliente: json["codTipoCliente"]as String? ?? '',
        descripcion: json["descripcion"]as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "tipoClienteId": tipoClienteId,
        "codTipoCliente": codTipoCliente,
        "descripcion": descripcion,
      };

  TipoClientes.empty() {
    tipoClienteId = 0;
    codTipoCliente = '';
    descripcion = '';
  }
}
