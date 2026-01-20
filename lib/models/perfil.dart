import 'dart:convert';

List<Perfil> perfilFromMap(String str) => List<Perfil>.from(json.decode(str).map((x) => Perfil.fromJson(x)));

String perfilToMap(List<Perfil> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Perfil {
    late int perfilId;
    late String nombre;
    late String descripcion;
    late bool activo;

    Perfil({
        required this.perfilId,
        required this.nombre,
        required this.descripcion,
        this.activo = false
    });

    factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        perfilId: json["perfilId"],
        nombre: json["nombre"],
        descripcion: json["descripcion"],
        activo: false
    );

    Map<String, dynamic> toMap() => {
        "perfilId": perfilId,
        "nombre": nombre,
        "descripcion": descripcion,
    };

    Perfil.empty(){
      perfilId = 0;
      nombre = '';
      descripcion = '';
      activo = false;
    }
}
