// To parse this JSON data, do
//
//     final cliente = clienteFromMap(jsonString);

import 'dart:convert';

import 'tecnico.dart';

List<Cliente> clienteFromMap(String str) =>
    List<Cliente>.from(json.decode(str).map((x) => Cliente.fromJson(x)));

String clienteToMap(List<Cliente> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Cliente {
  late int clienteId;
  late String codCliente;
  late String nombre;
  late String nombreFantasia;
  late String direccion;
  late String barrio;
  late String localidad;
  late String telefono1;
  late String telefono2;
  late String email;
  late String ruc;
  late String estado;
  late dynamic coordenadas;
  late Tecnico tecnico;
  late Departamento departamento;
  late TipoCliente tipoCliente;
  late int departamentoId;
  late int tipoClienteId;
  late int tecnicoId;
  late String notas;

  Cliente({
    required this.clienteId,
    required this.codCliente,
    required this.nombre,
    required this.nombreFantasia,
    required this.direccion,
    required this.barrio,
    required this.localidad,
    required this.telefono1,
    required this.telefono2,
    required this.email,
    required this.ruc,
    required this.estado,
    required this.coordenadas,
    required this.tecnico,
    required this.departamento,
    required this.tipoCliente,
    required this.notas,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        clienteId: json["clienteId"] as int? ?? 0,
        codCliente: json["codCliente"] as String? ?? '',
        nombre: json["nombre"] as String? ?? '',
        nombreFantasia: json["nombreFantasia"] as String? ?? '',
        direccion: json["direccion"] as String? ?? '',
        barrio: json["barrio"] as String? ?? '',
        localidad: json["localidad"] as String? ?? '',
        telefono1: json["telefono1"] as String? ?? '',
        telefono2: json["telefono2"] as String? ?? '',
        email: json["email"] as String? ?? '',
        ruc: json["ruc"] as String? ?? '',
        estado: json["estado"] as String? ?? '',
        coordenadas: json["coordenadas"] as String? ?? '',
        notas: json["notas"] as String? ?? '',
        tecnico: json["tecnico"] != null
            ? Tecnico.fromJson(json["tecnico"])
            : Tecnico.empty(),
        departamento: json["departamento"] != null
            ? Departamento.fromJson(json["departamento"])
            : Departamento.empty(),
        tipoCliente: json["tipoCliente"] != null
            ? TipoCliente.fromJson(json["tipoCliente"])
            : TipoCliente.empty(),
      );

  Map<String, dynamic> toMap() => {
        "clienteId": clienteId,
        "codCliente": codCliente,
        "nombre": nombre,
        "nombreFantasia": nombreFantasia,
        "direccion": direccion,
        "barrio": barrio,
        "localidad": localidad,
        "telefono1": telefono1,
        "telefono2": telefono2,
        "email": email,
        "ruc": ruc,
        "estado": estado,
        "coordenadas": coordenadas,
        "tecnico": tecnico.toMap(),
        "departamento": departamento.toMap(),
        "tipoCliente": tipoCliente.toMap(),
        "tecnicoId": tecnicoId,
        "departamentoId": departamentoId,
        "tipoClienteId": tipoClienteId,
        "notas": notas,
      };

  Cliente.empty() {
    clienteId = 0;
    codCliente = '';
    nombre = '';
    nombreFantasia = '';
    direccion = '';
    barrio = '';
    localidad = '';
    telefono1 = '';
    telefono2 = '';
    email = '';
    ruc = '';
    estado = '';
    coordenadas = '';
    tecnico = Tecnico.empty();
    departamento = Departamento.empty();
    tipoCliente = TipoCliente.empty();
    tecnicoId = 0;
    departamentoId = 0;
    tipoClienteId = 0;
    notas = '';
  }
}

class Departamento {
  late int departamentoId;
  late String codDepartamento;
  late String nombre;
  late int zonaId;

  Departamento(
      {required this.departamentoId,
      required this.codDepartamento,
      required this.nombre,
      required this.zonaId});

  factory Departamento.fromJson(Map<String, dynamic> json) => Departamento(
      departamentoId: json["departamentoId"] as int? ?? 0,
      codDepartamento: json["codDepartamento"] as String? ?? '',
      nombre: json["descripcion"] as String? ?? '',
      zonaId: json["zonaId"] as int? ?? 0);

  Map<String, dynamic> toMap() => {
        "departamentoId": departamentoId,
        "codDepartamento": codDepartamento,
        "descripcion": nombre,
        "zonaId": zonaId,
      };
  Departamento.empty() {
    departamentoId = 0;
    codDepartamento = '';
    nombre = '';
    zonaId = 0;
  }
}

class TipoCliente {
  late int tipoClienteId;
  late String codTipoCliente;
  late String descripcion;

  TipoCliente({
    required this.tipoClienteId,
    required this.codTipoCliente,
    required this.descripcion,
  });

  factory TipoCliente.fromJson(Map<String, dynamic> json) => TipoCliente(
        tipoClienteId: json["tipoClienteId"],
        codTipoCliente: json["codTipoCliente"],
        descripcion: json["descripcion"],
      );

  Map<String, dynamic> toMap() => {
        "tipoClienteId": tipoClienteId,
        "codTipoCliente": codTipoCliente,
        "descripcion": descripcion,
      };
  TipoCliente.empty() {
    tipoClienteId = 0;
    codTipoCliente = '';
    descripcion = '';
  }
}
