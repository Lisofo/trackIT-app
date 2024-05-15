// ignore_for_file: avoid_print

import 'package:app_track_it/config/config.dart';
import 'package:app_track_it/models/tarea.dart';
import 'package:app_track_it/models/tareaXtpi.dart';
import 'package:app_track_it/models/tipos_ptos_inspeccion.dart';
import 'package:dio/dio.dart';

class TareasServices {
  final _dio = Dio();
  String apiLink = Config.APIURL;

  Future getTareas(String token) async {
    String link = '${apiLink}api/v1/tareas/';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      final List<dynamic> tareaList = resp.data;

      return tareaList.map((obj) => Tarea.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }
  Future getTareasXTPI(TipoPtosInspeccion tPI,String modo, String token) async {
    String link = '${apiLink}api/v1/tipos/puntos/${tPI.tipoPuntoInspeccionId}/tareas?modo=$modo';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      final List<dynamic> tareaXPTIList = resp.data;

      return tareaXPTIList.map((obj) => TareaXtpi.fromJson(obj)).toList();
    } catch (e) {
      print(e);
    }
  }
}
