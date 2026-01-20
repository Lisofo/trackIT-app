// To parse this JSON data, do
//
//     final perfilUsuario = perfilUsuarioFromMap(jsonString);

import 'dart:convert';

List<PerfilUsuario> perfilUsuarioFromMap(String str) => List<PerfilUsuario>.from(json.decode(str).map((x) => PerfilUsuario.fromJson(x)));

String perfilUsuarioToMap(List<PerfilUsuario> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class PerfilUsuario {
   late int usuarioId;
   late int perfilId;
   late String nombre;
   late String descripcion;

    PerfilUsuario({
        required this.usuarioId,
        required this.perfilId,
        required this.nombre,
        required this.descripcion,
    });

    factory PerfilUsuario.fromJson(Map<String, dynamic> json) => PerfilUsuario(
        usuarioId: json["usuarioId"],
        perfilId: json["perfilId"],
        nombre: json["nombre"],
        descripcion: json["descripcion"],
    );

    Map<String, dynamic> toMap() => {
        "usuarioId": usuarioId,
        "perfilId": perfilId,
        "nombre": nombre,
        "descripcion": descripcion,
    };

    PerfilUsuario.empty(){
      usuarioId = 0;
      perfilId = 0;
      nombre = '';
      descripcion = '';
    }
}
