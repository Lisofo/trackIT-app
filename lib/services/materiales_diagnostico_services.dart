// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_track_it/config/config.dart';
import 'package:app_track_it/config/router/router.dart';
import 'package:app_track_it/models/material.dart';
import 'package:app_track_it/models/materialesTPI.dart';
import 'package:app_track_it/models/orden.dart';
import 'package:app_track_it/models/revision_materiales.dart';
import 'package:app_track_it/models/tipos_ptos_inspeccion.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class MaterialesDiagnosticoServices {
  final _dio = Dio();
  String apiUrl = Config.APIURL;

  static Future<void> showDialogs(BuildContext context, String errorMessage, bool doblePop, bool triplePop) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Mensaje'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (doblePop) {
                  Navigator.of(context).pop();
                }
                if (triplePop) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarError(BuildContext context, String mensaje) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        surfaceTintColor: Colors.white,
        title: const Text('Error'),
        content: Text(mensaje),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future getMateriales(String token) async {
    String link = '${apiUrl}api/v1/materiales/?enAppTecnico=S&enUso=S';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      final List<dynamic> materialList = resp.data;

      return materialList.map((obj) => Materiales.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }

  Future getMaterialesXTPI(TipoPtosInspeccion tPI, String token) async {
    String link =
        '${apiUrl}api/v1/tipos/puntos/${tPI.tipoPuntoInspeccionId}/materiales';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      final List<dynamic> materialXPTIList = resp.data;

      return materialXPTIList.map((obj) => MaterialXtpi.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }

  Future getLotes(int materialId, String token) async {
    String link = '${apiUrl}api/v1/materiales/$materialId/lotes';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      final List<dynamic> lotesList = resp.data;

      return lotesList.map((obj) => Lote.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }

  Future getMetodosAplicacion(String token) async {
    String link = '${apiUrl}api/v1/metodos-aplicacion/';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      final List<dynamic> metodosList = resp.data;

      return metodosList.map((obj) => MetodoAplicacion.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }

  Future getRevisionMateriales(Orden orden, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      final List<dynamic> revisionMaterialesList = resp.data;

      return revisionMaterialesList
          .map((obj) => RevisionMaterial.fromJson(obj))
          .toList();
    } catch (e) {
      print(e);
    }
  }

  Future postRevisionMaterial(BuildContext context, Orden orden, RevisionMaterial revisionMaterial, String token) async {
    
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales';
    var data = ({
      "comentario": revisionMaterial.comentario,
      "cantidad": revisionMaterial.cantidad,
      "idMaterial": revisionMaterial.material.materialId,
      "idMaterialLote": null,
      "idMetodoAplicacion": null,
      "ubicacion": null,
      "areaCobertura": null,
      "idsPlagas": []
    });

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      if (resp.statusCode == 201) {
        revisionMaterial.otMaterialId = resp.data["otMaterialId"];
        await showDialogs(context, 'Material guardado', true, false);
      }

      return;
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            final errors = responseData['errors'] as List<dynamic>;
            final errorMessages = errors.map((error) {
              return "Error: ${error['message']}";
            }).toList();
            await _mostrarError(context, errorMessages.join('\n'));
          } else {
            await _mostrarError(context, 'Error: ${e.response!.data}');
          }
        } else {
          await _mostrarError(context, 'Error: ${e.message}');
        }
      }
    }
  }

  Future deleteRevisionMaterial(BuildContext context, Orden orden, RevisionMaterial revisionMaterial, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales/${revisionMaterial.otMaterialId}';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );
      if (resp.statusCode == 204) {
        // showDialogs(context, 'Material borrado', true, false);
        router.pop(context);
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            final errors = responseData['errors'] as List<dynamic>;
            final errorMessages = errors.map((error) {
              return "Error: ${error['message']}";
            }).toList();
            await _mostrarError(context, errorMessages.join('\n'));
          } else {
            await _mostrarError(context, 'Error: ${e.response!.data}');
          }
        } else {
          await _mostrarError(context, 'Error: ${e.message}');
        }
      }
    }
  }
}
