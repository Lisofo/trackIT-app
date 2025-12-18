import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/incidencia.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_incidencia.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class IncidenciaServices {
  final _dio = Dio();
  String apiUrl = Config.APIURL;
  int? statusCode;

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }
  
  Future getIncidencias(BuildContext context,String token) async {
    String link = '${apiUrl}api/v1/incidencias/?sort=descripcion';
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
      final List<dynamic> metodosList = resp.data;

      return metodosList.map((obj) => Incidencia.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future<Incidencia?> createIncidencia(
    BuildContext context, 
    String token, 
    Incidencia incidencia
  ) async {
    String link = '${apiUrl}api/v1/incidencias/';
    try {
      var headers = {
        'Authorization': token,
        'Content-Type': 'application/json'
      };
      
      // Enviamos solo la descripción en el body como solicitado
      var body = {
        "descripcion": incidencia.descripcion,
      };
      
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: body,
      );

      statusCode = 1;
      return Incidencia.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<Incidencia?> updateIncidencia(
    BuildContext context, 
    String token, 
    int incidenciaId, 
    Incidencia incidencia
  ) async {
    String link = '${apiUrl}api/v1/incidencias/$incidenciaId';
    try {
      var headers = {
        'Authorization': token,
        'Content-Type': 'application/json'
      };
      
      // Solo enviamos la descripción en el body
      var body = {
        "descripcion": incidencia.descripcion,
      };
      
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: body,
      );

      statusCode = 1;
      return Incidencia.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<bool> deleteIncidencia(
    BuildContext context, 
    String token, 
    int incidenciaId
  ) async {
    String link = '${apiUrl}api/v1/incidencias/$incidenciaId';
    try {
      var headers = {
        'Authorization': token,
      };
      
      await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );

      statusCode = 1;
      return true;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return false;
    }
  }

  Future postRevisionIncidencia(BuildContext context, Orden orden, RevisionIncidencia inc, String token) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias';
    var data = inc.toMap();
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 201) {
        
        
      }
      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putRevisionIncidencia(BuildContext context, Orden orden, RevisionIncidencia inc, String token) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias/${inc.otIncidenciaId}';
    var data = inc.toMap();
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        
      }
      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getRevisionIncidencia(BuildContext context, Orden orden, String token) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias';

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
      final List incidenciaList = resp.data;
      var retorno = incidenciaList.map((e) => Incidencia.fromJson(e)).toList();

      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }
}