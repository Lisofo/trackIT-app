// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/control_orden.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OrdenControlServices{
  final _dio = Dio();
  String apiUrl = Config.APIURL;
  late String apiLink = '${apiUrl}api/v1/ordenes/';
  int? statusCode;

  static void showErrorDialog(BuildContext context, String errorMessage) {
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
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }
  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future getControlOrden(BuildContext context, Orden orden, String token) async {
    String link = '$apiLink${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/controles';

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
      final List<dynamic> controlesList = resp.data;

      return controlesList.map((obj) => ControlOrden.fromJson(obj)).toList();
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

  Future putControl(BuildContext context, Orden orden, ControlOrden control, String token) async {
    try {
      String link = '$apiLink${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/controles/${control.controlRegId}';
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        data: control.toMap(),
        options: Options(
          method: 'PUT', 
          headers: headers
          )
        );
      statusCode = 1;
      if (resp.statusCode == 200) { }
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


  Future postControl(BuildContext context, Orden orden, ControlOrden control, String token) async {
    try {
      String link = '$apiLink${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/controles/';
      var headers = {'Authorization': token};
      var data = control.toMap();
      final resp = await _dio.request(
        link,
        data: data,
        options: Options(
          method: 'POST', 
          headers: headers
        )
      );
      statusCode = 1;
      if (resp.statusCode == 201) {
        control.controlRegId = resp.data["controlRegId"]; 
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

  Future postControles(BuildContext context, Orden orden, List<ControlOrden> controles, String token) async {
    String link = '$apiLink${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/controles/batch';
    print(link);
    List datos = [];
    Map<String, dynamic> mapa;
    for(int i = 0; i < controles.length; i++){
      mapa = ({
        "metodo": controles[i].controlRegId == 0 ? "POST" : "PUT",
        "controlId": controles[i].controlId,
        "ordinal": controles[i].ordinal,
        "respuesta": controles[i].respuesta,
        "comentario": controles[i].comentario,
        "controlRegId": controles[i].controlRegId,
      });
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
      if (resp.statusCode == 201) {
        for(int i = 0; i < controles.length; i++){
          if(controles[i].controlRegId == 0){
            if(resp.data[0]["status"] == 201){
              controles[i].controlRegId = resp.data[0]["content"]["controlRegId"];
              print(controles[i].controlRegId);
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
}