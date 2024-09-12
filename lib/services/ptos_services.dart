// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:convert';

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_pto_inspeccion.dart';
import 'package:app_tec_sedel/models/tipos_ptos_inspeccion.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PtosInspeccionServices {
  final _dio = Dio();
  String apiUrl = Config.APIURL;
  int? statusCode;

  static Future<void> showDialogs(BuildContext context,String errorMessage,bool doblePop,bool triplePop,) async {
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showErrorDialog(BuildContext context, String mensaje) async {
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

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future getTiposPtosInspeccion(BuildContext context, String token) async {
    String link = '${apiUrl}api/v1/tipos/puntos';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      statusCode = 1;
      final List tipoPtoInspeccionList = resp.data;
      var retorno = tipoPtoInspeccionList.map((e) => TipoPtosInspeccion.fromJson(e)).toList();
      return retorno;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future getPtosInspeccion(BuildContext context, Orden orden, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/acciones/';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      statusCode = 1;
      final List ptoInspeccionList = resp.data;
      var retorno = ptoInspeccionList.map((e) => RevisionPtoInspeccion.fromJson(e)).toList();

      Provider.of<OrdenProvider>(context, listen: false).setPI(retorno);

      return retorno;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future postPtoInspeccionAccion(BuildContext context, Orden orden, RevisionPtoInspeccion revisionPtoInspeccion, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/${revisionPtoInspeccion.puntoInspeccionId}/acciones';
    print(link);

    var data;
    switch (revisionPtoInspeccion.idPIAccion) {
      case 1:
        data = ({"idPIAccion": 1, "comentario": revisionPtoInspeccion.comentario});
        break;
      case 4:
        data = ({"idPIAccion": 4, "comentario": revisionPtoInspeccion.comentario});
        break;
      case 7:
        data = ({"idPIAccion": 7, "comentario": revisionPtoInspeccion.comentario});
        break;
      case 2:
        data = ({
          "idPIAccion": 2,
          "comentario": "actividad",
          "materiales": revisionPtoInspeccion.materiales.map((material) => material.toMap()).toList(),
          "tareas": revisionPtoInspeccion.tareas.map((tarea) => tarea.toMap()).toList(),
          "plagas": revisionPtoInspeccion.plagas.map((plaga) => plaga.toMap()).toList()
        });
        break;
      case 3:
        data = ({
          "idPIAccion": 3,
          "comentario": "mantenimiento",
          "materiales": revisionPtoInspeccion.materiales.map((material) => material.toMap()).toList(),
          "tareas": revisionPtoInspeccion.tareas.map((tarea) => tarea.toMap()).toList(),
        });
      case 6:
        data = ({
          "idPIAccion": 6,
          "comentario": revisionPtoInspeccion.comentario,
          "zona": revisionPtoInspeccion.zona,
          "sector": revisionPtoInspeccion.sector
        });
        break;
      case 5:
        data = ({
          "idPIAccion": 5,
          "comentario": revisionPtoInspeccion.comentario,
          "idTipoPuntoInspeccion": revisionPtoInspeccion.tipoPuntoInspeccionId,
          "idPlagaObjetivo": revisionPtoInspeccion.plagaObjetivoId,
          "codPuntoInspeccion": revisionPtoInspeccion.codPuntoInspeccion,
          "codigoBarra": revisionPtoInspeccion.codigoBarra,
          "zona": revisionPtoInspeccion.zona,
          "sector": revisionPtoInspeccion.sector
        });
        break;
    }
    print(data);
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 201) {
        revisionPtoInspeccion.otPuntoInspeccionId = resp.data["otPuntoInspeccionId"];
      }
      return;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future putPtoInspeccionAccion(BuildContext context, Orden orden, RevisionPtoInspeccion revisionPtoInspeccion, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/${revisionPtoInspeccion.puntoInspeccionId}/acciones/${revisionPtoInspeccion.otPuntoInspeccionId}';
    print(link);

    var data;
    switch (revisionPtoInspeccion.idPIAccion) {
      case 1:
        data =
            ({"idPIAccion": 1, "comentario": revisionPtoInspeccion.comentario});
        break;
      case 4:
        data =
            ({"idPIAccion": 4, "comentario": revisionPtoInspeccion.comentario});
        break;
      case 7:
        data =
            ({"idPIAccion": 7, "comentario": revisionPtoInspeccion.comentario});
        break;
      case 2:
        data = ({
          "idPIAccion": 2,
          "comentario": "actividad",
          "materiales": revisionPtoInspeccion.materiales
              .map((material) => material.toMap())
              .toList(),
          "tareas": revisionPtoInspeccion.tareas
              .map((tarea) => tarea.toMap())
              .toList(),
          "plagas": revisionPtoInspeccion.plagas
              .map((plaga) => plaga.toMap())
              .toList()
        });
        break;
      case 3:
        data = ({
          "idPIAccion": 3,
          "comentario": "mantenimiento",
          "materiales": revisionPtoInspeccion.materiales
              .map((material) => material.toMap())
              .toList(),
          "tareas": revisionPtoInspeccion.tareas
              .map((tarea) => tarea.toMap())
              .toList(),
        });
      case 6:
        data = ({
          "idPIAccion": 6,
          "comentario": revisionPtoInspeccion.comentario,
          "zona": revisionPtoInspeccion.zona,
          "sector": revisionPtoInspeccion.sector
        });
        break;
      case 5:
        data = ({
          "idPIAccion": 5,
          "comentario": revisionPtoInspeccion.comentario,
          "idTipoPuntoInspeccion": revisionPtoInspeccion.tipoPuntoInspeccionId,
          "idPlagaObjetivo": revisionPtoInspeccion.plagaObjetivoId,
          "codPuntoInspeccion": revisionPtoInspeccion.codPuntoInspeccion,
          "codigoBarra": revisionPtoInspeccion.codigoBarra,
          "zona": revisionPtoInspeccion.zona,
          "sector": revisionPtoInspeccion.sector
        });
        break;
    }
    print(data);
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(link,
          options: Options(
            method: 'PUT',
            headers: headers,
          ),
          data: data);
      statusCode = 1;
      if (resp.statusCode == 200) {
        revisionPtoInspeccion.otPuntoInspeccionId = resp.data["otPuntoInspeccionId"];
      }
      return;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future deleteAccionesPI(BuildContext context, Orden orden, RevisionPtoInspeccion revisionPtoInspeccion, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/${revisionPtoInspeccion.puntoInspeccionId}/acciones/${revisionPtoInspeccion.otPuntoInspeccionId}';
    print(link);

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );

      statusCode = 1;
      return resp;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future getPIActividad(BuildContext context, Orden orden, RevisionPtoInspeccion revisionPtoInspeccion, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/${revisionPtoInspeccion.puntoInspeccionId}/acciones/${revisionPtoInspeccion.otPuntoInspeccionId}';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      statusCode = 1;
      final RevisionPtoInspeccion ptoInspeccion = RevisionPtoInspeccion.fromJson(resp.data);
      return ptoInspeccion;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future postAcciones(BuildContext context, Orden orden, List<RevisionPtoInspeccion> acciones, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/acciones';
    print(link);
    List datos = [];
    var mapa;
    for(int i = 0; i < acciones.length; i++){
      switch (acciones[i].idPIAccion){
        case 1:
          mapa = ({
            "idPuntoInspeccion": acciones[i].puntoInspeccionId,
            "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
            "idAccion": acciones[i].otPuntoInspeccionId,
            "idPIAccion": 1,
            "comentario": acciones[i].comentario, //SIN ACTIVIDAD,
          });
        break;
        case 2:
          mapa = ({
          "idPIAccion": 2,
          "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
          "comentario": "actividad", //ACTIVIDAD
          "materiales": acciones[i].materiales.map((material) => material.toMap()).toList(),
          "tareas": acciones[i].tareas.map((tarea) => tarea.toMap()).toList(),
          "plagas": acciones[i].plagas.map((plaga) => plaga.toMap()).toList(),
          "idAccion": acciones[i].otPuntoInspeccionId,
          "idPuntoInspeccion": acciones[i].puntoInspeccionId
        });
        break;
        case 3:
          mapa = ({
            "idPIAccion": 3,
            "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
            "comentario": "mantenimiento", // MANTENIMIENTO
            "materiales": acciones[i].materiales.map((material) => material.toMap()).toList(),
            "tareas": acciones[i].tareas.map((tarea) => tarea.toMap()).toList(),
            "idAccion": acciones[i].otPuntoInspeccionId,
            "idPuntoInspeccion": acciones[i].puntoInspeccionId
          });
        break;
        case 4:
          mapa = ({
            "idPuntoInspeccion": acciones[i].puntoInspeccionId,
            "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
            "idPIAccion": 4, //DESINSTALADO
            "comentario": acciones[i].comentario,
            "idAccion": acciones[i].otPuntoInspeccionId,
            
          });
        break;
        case 5:
          mapa = ({
          "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
          "idPIAccion": 5,
          "comentario": acciones[i].comentario, //NUEVO
          "idTipoPuntoInspeccion": acciones[i].tipoPuntoInspeccionId,
          "idPlagaObjetivo": acciones[i].plagaObjetivoId,
          "codPuntoInspeccion": acciones[i].codPuntoInspeccion,
          "codigoBarra": acciones[i].codigoBarra,
          "zona": acciones[i].zona,
          "sector": acciones[i].sector,
          "idAccion": acciones[i].otPuntoInspeccionId,
        });
        break;
        case 6:
          mapa = ({
          "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
          "idPIAccion": 6,
          "comentario": acciones[i].comentario, //TRASLADO
          "zona": acciones[i].zona,
          "sector": acciones[i].sector,
          "idAccion": acciones[i].otPuntoInspeccionId,
          "idPuntoInspeccion": acciones[i].puntoInspeccionId
        });
        break;
        case 7:
          mapa = ({
            "idPuntoInspeccion": acciones[i].puntoInspeccionId,
            "metodo": acciones[i].otPuntoInspeccionId == 0 ? "POST" : "PUT",
            "idPIAccion": 7,
            "comentario": acciones[i].comentario, //SIN ACCESO
            "idAccion": acciones[i].otPuntoInspeccionId,
          });
        break;
      }
    datos.add(mapa);
    } 
    String datosJson = json.encode(datos);
    print(datosJson);
    print(datos);
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,

        ),
        data: datosJson
      );
      statusCode = 1;
      // print(resp);
      // print(resp.data[0]["status"]);
      // print(resp.data[0]["content"]["otPuntoInspeccionId"]);
      if (resp.statusCode == 201) {
        for(int i = 0; i < acciones.length; i++){
          if(acciones[i].otPuntoInspeccionId == 0){
            if(resp.data[i]["status"] == 201){
              acciones[i].otPuntoInspeccionId = resp.data[i]["content"]["otPuntoInspeccionId"];
              print(acciones[i].otPuntoInspeccionId);
            }
          }
        }
      }
      return;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }

  Future deleteAcciones(BuildContext context, Orden orden, List<RevisionPtoInspeccion> acciones, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/puntos/acciones';
    print(link);
    List datos = [];
    var mapa;
    for(int i = 0; i < acciones.length; i++){
      if(acciones[i].otPuntoInspeccionId != 0){
        mapa = ({
          "idPuntoInspeccion": acciones[i].puntoInspeccionId,
          "metodo": "DELETE",
          "idAccion": acciones[i].otPuntoInspeccionId
        });  
        datos.add(mapa);
      }
    }
    String datosJson = json.encode(datos);
    print(datosJson);
    print(datos);
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: datosJson
      );
      statusCode = 1;
      // print(resp);
      if (resp.statusCode == 201) {
        // for(int i = 0; i < acciones.length; i++){
        //   acciones[i].otPuntoInspeccionId = resp.data["otPuntoInspeccionId"];
        // }
      }
      return;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }
}

