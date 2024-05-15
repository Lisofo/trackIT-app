// ignore_for_file: avoid_print

import 'package:app_track_it/config/config.dart';
import 'package:app_track_it/models/plaga.dart';
import 'package:app_track_it/models/plagaXTPI.dart';
import 'package:app_track_it/models/plaga_objetivo.dart';
import 'package:app_track_it/models/tipos_ptos_inspeccion.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PlagaServices {
  final _dio = Dio();
  String apiUrl = Config.APIURL;
  late String apiLink = '${apiUrl}api/v1/plagas/';

  Future getPlagas(String token) async {
    String link = apiLink;

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      final List<dynamic> plagaList = resp.data;

      return plagaList.map((obj) => Plaga.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }

  Future getPlagasXTPI(TipoPtosInspeccion tPI, String token) async {
    String link =
        '${apiUrl}api/v1/tipos/puntos/${tPI.tipoPuntoInspeccionId}/plagas';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      final List<dynamic> plagaXTPIList = resp.data;

      return plagaXTPIList.map((obj) => PlagaXtpi.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }

  Future getPlagasObjetivo(BuildContext context, String token) async {
    String link = '${apiUrl}api/v1/plagas-objetivo/';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      final List<dynamic> plagaObjetivoList = resp.data;

      return plagaObjetivoList
          .map((obj) => PlagaObjetivo.fromJson(obj))
          .toList();
    } catch (e) {
      print(e);
    }
  }
}
