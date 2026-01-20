import 'dart:convert';

Usuario usuarioFromMap(String str) => Usuario.fromJson(json.decode(str));

String usuarioToMap(Usuario data) => json.encode(data.toMap());

class Usuario {
  late int usuarioId;
  late String login;
  late String nombre;
  late String apellido;
  late String direccion;
  late String telefono;
  late String tipo;
  late bool autorizante;
  late String estado;
  late String reghs;

  Usuario({
    required this.usuarioId,
    required this.login,
    required this.nombre,
    required this.apellido,
    required this.direccion,
    required this.telefono,
    required this.tipo,
    required this.autorizante,
    required this.estado,
    required this.reghs,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    usuarioId: json["usuarioId"] as int? ?? 0,
    login: json["login"] as String? ?? '',
    nombre: json["nombre"] as String? ?? '',
    apellido: json["apellido"] as String? ?? '',
    direccion: json["direccion"] as String? ?? '',
    telefono: json["telefono"] as String? ?? '',
    tipo: json["tipo"] as String? ?? '',
    autorizante: false,
    estado: json["estado"] as String? ?? '',
    reghs: json["reghs"] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    "usuarioId": usuarioId,
    "login": login,
    "nombre": nombre,
    "apellido": apellido,
    "direccion": direccion,
    "telefono": telefono,
    "tipo": tipo,
    "autorizante": autorizante,
    "estado": estado,
    "reghs": reghs,
  };

  Usuario.empty() {
    usuarioId = 0;
    login = '';
    nombre = '';
    apellido = '';
    direccion = '';
    telefono = '';
    tipo = '';
    autorizante = false;
    estado = '';
    reghs = '';
  }
}
