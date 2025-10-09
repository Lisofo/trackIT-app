// ignore_for_file: avoid_print

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/models/tareaXtpi.dart';
import 'package:app_tec_sedel/models/tipos_ptos_inspeccion.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TareasServices {
  final _dio = Dio();
  String apiLink = Config.APIURL;
  int? statusCode;
  
  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future getTareas(BuildContext context, String token) async {
    String link = '${apiLink}api/v1/tareas/?sort=descripcion';

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
      final List<dynamic> tareaList = resp.data;

      return tareaList.map((obj) => Tarea.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putTarea(BuildContext context, Tarea tarea, String token) async {
    String link = "${apiLink}api/v1/tareas/${tarea.tareaId}/";

    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        data: tarea.toMap(),
        options: Options(
          method: 'PUT', 
          headers: headers
        )
      );

      statusCode = 1;
      if (resp.statusCode == 200) {
        // showDialogs(context, 'Tarea actualizada correctamente', false, false);
      }

      return Tarea.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context); 
    }
  }

  Future postTarea(BuildContext context, Tarea tarea, String token) async {
    String link = "${apiLink}api/v1/tareas/";

    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        data: tarea.toMap(),
        options: Options(
          method: 'POST', 
          headers: headers
        )
      );

      statusCode = 1;
      tarea.tareaId = resp.data["tareaId"];

      if (resp.statusCode == 201) {
        // showDialogs(context, 'Tarea creada correctamente', false, false);
      }

      return Tarea.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context); 
    }
  }

  Future deleteTarea(BuildContext context, Tarea tarea, String token) async {
    String link = "${apiLink}api/v1/tareas/${tarea.tareaId}/";

    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link += tarea.tareaId.toString(),
        options: Options(
          method: 'DELETE', 
          headers: headers
        )
      );
          
      statusCode = 1;
      if (resp.statusCode == 204) {
        // showDialogs(context, 'Tarea borrada correctamente', true, true);
      }

      return resp.statusCode;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context); 
    }
  }

  Future getTareasXTPI(BuildContext context, TipoPtosInspeccion tPI,String modo, String token) async {
    String link = '${apiLink}api/v1/tipos/puntos/${tPI.tipoPuntoInspeccionId}/tareas?modo=$modo&sort=descripcion';

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
      final List<dynamic> tareaXPTIList = resp.data;

      return tareaXPTIList.map((obj) => TareaXtpi.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getMO(BuildContext context, Orden orden, String token) async {
    String link = '${apiLink}api/v1/ordenes/${orden.ordenTrabajoId}/lineas/?MO=MO';

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
      final List<dynamic> tareaList = resp.data;

      return tareaList.map((obj) => Linea.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }
}
