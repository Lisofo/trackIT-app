import 'dart:convert';
import 'dart:typed_data';

ClienteFirma clienteFirmaFromMap(String str) => ClienteFirma.fromJson(json.decode(str));

String clienteFirmaToMap(ClienteFirma data) => json.encode(data.toMap());

class ClienteFirma {
  late int otFirmaId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late String nombre;
  late String area;
  late String firmaPath;
  late String firmaMd5;
  late String comentario;
  late Uint8List? firma;

  ClienteFirma({
    required this.otFirmaId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.nombre,
    required this.area,
    required this.firmaPath,
    required this.firmaMd5,
    required this.comentario,
    required this.firma,
  });

  factory ClienteFirma.fromJson(Map<String, dynamic> json) => ClienteFirma(
        otFirmaId: json["otFirmaId"],
        ordenTrabajoId: json["ordenTrabajoId"],
        otRevisionId: json["otRevisionId"],
        nombre: json["nombre"],
        area: json["area"],
        firmaPath: json["firmaPath"],
        firmaMd5: json["firmaMD5"],
        comentario: json["comentario"],
        firma: null,
      );

  Map<String, dynamic> toMap() => {
        "otFirmaId": otFirmaId,
        "ordenTrabajoId": ordenTrabajoId,
        "otRevisionId": otRevisionId,
        "nombre": nombre,
        "area": area,
        "firmaPath": firmaPath,
        "firmaMD5": firmaMd5,
        "comentario": comentario,
        "firma": firma
      };

  ClienteFirma.empty() {
    otFirmaId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    nombre = '';
    area = '';
    firmaPath = '';
    firmaMd5 = '';
    comentario = '';
    firma = null;
  }

  @override
  String toString() {
    return nombre;
  }
}
