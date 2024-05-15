import 'dart:convert';

List<Plaga> plagaFromMap(String str) =>
    List<Plaga>.from(json.decode(str).map((x) => Plaga.fromJson(x)));

String plagaToMap(List<Plaga> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Plaga {
  late int plagaId;
  late String codPlaga;
  late String descripcion;

  Plaga({
    required this.plagaId,
    required this.codPlaga,
    required this.descripcion,
  });

  factory Plaga.fromJson(Map<String, dynamic> json) => Plaga(
        plagaId: json["plagaId"],
        codPlaga: json["codPlaga"],
        descripcion: json["descripcion"],
      );

  Map<String, dynamic> toMap() => {
        "plagaId": plagaId,
        "codPlaga": codPlaga,
        "descripcion": descripcion,
      };

  Plaga.empty() {
    plagaId = 0;
    codPlaga = '';
    descripcion = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
