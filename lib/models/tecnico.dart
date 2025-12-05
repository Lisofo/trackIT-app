// ignore_for_file: prefer_null_aware_operators

import 'dart:convert';

List<Tecnico> tecnicoFromMap(String str) => List<Tecnico>.from(json.decode(str).map((x) => Tecnico.fromJson(x)));

String tecnicoToMap(List<Tecnico> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Tecnico {
  late int tecnicoId;
  late String codTecnico;
  late String nombre;
  late DateTime? fechaNacimiento;
  late String documento;
  late DateTime? fechaIngreso;
  late DateTime? fechaVtoCarneSalud;
  late bool? deshabilitado;
  late String? firmaPath;
  late String? firmaMd5;
  late String? avatarPath;
  late String? avatarMd5;
  late Cargo? cargo;
  late int cargoId;
  late bool? verDiaSiguiente;

  Tecnico({
    required this.tecnicoId,
    required this.codTecnico,
    required this.nombre,
    required this.fechaNacimiento,
    required this.documento,
    required this.fechaIngreso,
    required this.fechaVtoCarneSalud,
    required this.deshabilitado,
    required this.firmaPath,
    required this.firmaMd5,
    required this.avatarPath,
    required this.avatarMd5,
    required this.cargo,
    required this.cargoId,
    required this.verDiaSiguiente,
  });

  factory Tecnico.fromJson(Map<String, dynamic> json) => Tecnico(
    tecnicoId: json["tecnicoId"] as int? ?? 0,
    codTecnico: json["codTecnico"] as String? ?? '',
    nombre: json["nombre"] as String? ?? '',
    fechaNacimiento: (json["fechaNacimiento"] == null || json["fechaNacimiento"] == 'null') ? null : DateTime.tryParse(json["fechaNacimiento"]),
    documento: json["documento"] as String? ?? '',
    fechaIngreso: (json["fechaIngreso"] == null || json["fechaIngreso"] == 'null') ? null : DateTime.tryParse(json["fechaIngreso"]),
    fechaVtoCarneSalud: (json["fechaVtoCarneSalud"] == null || json["fechaVtoCarneSalud"] == 'null') ? null : DateTime.tryParse(json["fechaVtoCarneSalud"]),
    deshabilitado: json["deshabilitado"] as bool? ?? false,
    firmaPath: json["firmaPath"] as String? ?? '',
    firmaMd5: json["firmaMD5"] as String? ?? '',
    avatarPath: json["avatarPath"] as String? ?? '',
    avatarMd5: json["avatarMD5"] as String? ?? '',
    cargo: json["cargo"] != null ? Cargo.fromJson(json["cargo"]) : null,
    cargoId: 0,
    verDiaSiguiente: json["verDiaSiguiente"] ?? false,
  );

  Map<String, dynamic> toMap() => {
    "nombre": nombre,
    "fechaNacimiento": fechaNacimiento == null ? null : fechaNacimiento!.toIso8601String(),
    "documento": documento,
    "fechaIngreso": fechaIngreso == null ? null : fechaIngreso!.toIso8601String(),
    "fechaVtoCarneSalud": fechaVtoCarneSalud == null ? null : fechaVtoCarneSalud!.toIso8601String(),
    "cargoId": cargoId,
    "verDiaSiguiente": verDiaSiguiente,
  };

  Tecnico.empty() {
    tecnicoId = 0;
    codTecnico = '';
    nombre = '';
    fechaNacimiento = DateTime.now();
    documento = '';
    fechaIngreso = DateTime.now();
    fechaVtoCarneSalud = DateTime.now();
    deshabilitado = false;
    firmaPath = '';
    firmaMd5 = '';
    avatarPath = '';
    avatarMd5 = '';
    cargoId = 0;
    cargo = Cargo(cargoId: 0, codCargo: '', descripcion: '');
    verDiaSiguiente = false;
  }

  @override
  String toString() {
    return nombre;
  }
}

class Cargo {
  late int cargoId;
  late String codCargo;
  late String descripcion;

  Cargo({
    required this.cargoId,
    required this.codCargo,
    required this.descripcion,
  });

  factory Cargo.fromJson(Map<String, dynamic> json) => Cargo(
    cargoId: json["cargoId"] as int? ?? 0,
    codCargo: json["codCargo"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    "cargoId": cargoId,
    "codCargo": codCargo,
    "descripcion": descripcion,
  };
  Cargo.empty() {
    cargoId = 0;
    codCargo = '';
    descripcion = '';
  }

  @override
  String toString() {
    return cargoId.toString();
  }
}