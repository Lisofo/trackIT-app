import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class UnidadesServices {
  String apiUrl = Config.APIURL;
  final _dio = Dio();
  int? statusCode;

  Future<int?> getStatusCode () async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }
  
  Future<List<Unidad>> getUnidades(BuildContext context, String token) async {
    String link = '${apiUrl}api/v1/unidades';
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
      final List<dynamic> unidadesList = resp.data;
      return unidadesList.map((json) => Unidad.fromJson(json)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return [];
    }
  }

  Future crearUnidad(BuildContext context, Unidad unidad, String token) async {
    String link = '${apiUrl}api/v1/unidades';
    try {
      var headers = {'Authorization': token};
      var data = unidad.toJson();
      var resp = await _dio.request(
        link,
        data: data,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
      );

      statusCode = 1;
      return resp.data;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }

  Future editarUnidad(BuildContext context, Unidad unidad, String token) async {
    String link = '${apiUrl}api/v1/unidades/${unidad.unidadId}';

    try {
      var headers = {'Authorization': token};
      var data = unidad.toJson();
      var resp = await _dio.request(
        link,
        data: data,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
      );

      statusCode = 1;
      return resp.data;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return null;
    }
  }
}