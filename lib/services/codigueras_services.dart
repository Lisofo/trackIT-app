import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/marca.dart';
import 'package:app_tec_sedel/models/modelo.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CodiguerasServices {
  String apiUrl = Config.APIURL;
  final _dio = Dio();
  int? statusCode;

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }
  
  Future<List<Marca>> getMarcas(BuildContext context, String token) async {
    String link = '${apiUrl}api/v1/unidades-marcas/';
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
      final List<dynamic> marcasList = resp.data;
      return marcasList.map((json) => Marca.fromJson(json)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return [];
    }
  }

  Future<List<Modelo>> getModelos(BuildContext context, String token, {int? marcaId}) async {
    String link = '${apiUrl}api/v1/unidades-modelos/';
    
    // Agregar parámetro marcaId si viene
    if (marcaId != null) {
      link += '?marcaId=$marcaId';
    }
    
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
      final List<dynamic> modelosList = resp.data;
      return modelosList.map((json) => Modelo.fromJson(json)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      return [];
    }
  }
}