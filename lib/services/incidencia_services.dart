import 'dart:typed_data';
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
      
      var body = {
        "descripcion": incidencia.descripcion,
        "sinGarantia": incidencia.sinGarantia,
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
      
      var body = {
        "descripcion": incidencia.descripcion,
        "sinGarantia": incidencia.sinGarantia,
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

  Future<RevisionIncidencia?> postRevisionIncidencia(BuildContext context, Orden orden, RevisionIncidencia inc, String token) async {
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
        return RevisionIncidencia.fromJson(resp.data);
      }
      return null;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<RevisionIncidencia?> putRevisionIncidencia(BuildContext context, Orden orden, RevisionIncidencia inc, String token) async {
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
        return RevisionIncidencia.fromJson(resp.data);
      }
      return null;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
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
      var retorno = incidenciaList.map((e) => RevisionIncidencia.fromJson(e)).toList();

      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future<List<IncidenciaAdjunto>?> getAdjuntosIncidencia(
    BuildContext context,
    Orden orden,
    int incidenciaId,
    String token
  ) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias/$incidenciaId/adjuntos';

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
      
      if (resp.statusCode == 200) {
        final List<dynamic> adjuntosList = resp.data;
        return adjuntosList.map((adjunto) => IncidenciaAdjunto.fromJson(adjunto)).toList();
      }
      return [];
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<IncidenciaAdjunto?> postAdjuntoIncidencia(
    BuildContext context,
    Orden orden,
    int incidenciaId,
    String filePath,
    String md5Hash,
    String token
  ) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias/$incidenciaId/adjuntos';

    try {
      var formData = FormData.fromMap({
        'adjuntos': await MultipartFile.fromFile(filePath),
        'adjuntosMD5': md5Hash,
      });

      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: formData,
      );
      
      statusCode = 1;
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        // La API devuelve una lista de adjuntos, no un objeto individual
        if (resp.data is List) {
          List<dynamic> dataList = resp.data;
          if (dataList.isNotEmpty) {
            // Tomamos el primer adjunto de la lista
            return IncidenciaAdjunto.fromJson(dataList[0]);
          }
        } else if (resp.data is Map<String, dynamic>) {
          // Si la API devuelve un objeto individual (fallback)
          return IncidenciaAdjunto.fromJson(resp.data);
        }
      }
      return null;

    } catch (e) {
      statusCode = 0;
      print('El error es: $e');
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<Uint8List?> getAdjuntoIncidenciaArchivo(
    BuildContext context,
    Orden orden,
    int incidenciaId,
    String fileName,
    String token
  ) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias/$incidenciaId/adjuntos/$fileName';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );
      
      statusCode = 1;
      if (resp.statusCode == 200 && resp.data is List<int>) {
        return Uint8List.fromList(resp.data.cast<int>());
      }
      return null;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<List<IncidenciaAdjunto>?> getAdjuntosPorRevisionIncidencia(
    BuildContext context,
    RevisionIncidencia revisionIncidencia,
    String token
  ) async {
    String link = apiUrl;
    link += 'api/v1/ordenes/${revisionIncidencia.ordenTrabajoId}/revisiones/${revisionIncidencia.otRevisionId}/incidencias/${revisionIncidencia.otIncidenciaId}/adjuntos';

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
      
      if (resp.statusCode == 200) {
        final List<dynamic> adjuntosList = resp.data;
        return adjuntosList.map((adjunto) => IncidenciaAdjunto.fromJson(adjunto)).toList();
      }
      return [];
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future<bool> deleteAdjuntoIncidencia(
    BuildContext context,
    Orden orden,
    int incidenciaId,
    String fileName,
    String token
  ) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/incidencias/$incidenciaId/adjuntos/$fileName';
    
    try {
      var headers = {'Authorization': token};
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
}