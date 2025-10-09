// ignore_for_file: unnecessary_string_interpolations, avoid_print, use_build_context_synchronously, dead_code

// import 'dart:convert';
import 'dart:typed_data';

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/tecnico.dart';

class TecnicosServices {
  final _dio = Dio();
  int? statusCode;
  String apiUrl = Config.APIURL;

  Future<int?> getStatusCode () async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }

  Future getTecnicoById(BuildContext context, String id, String token) async {
    String link = '${apiUrl}api/v1/tecnicos/';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link += '$id',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      statusCode = 1;
      final Tecnico tecnico = Tecnico.fromJson(resp.data);

      return tecnico;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getTecnicos(BuildContext context, String documento, String codTecnico, String nombre, String token) async {
    String link = '${apiUrl}api/v1/tecnicos/?sort=nombre';
    // if (documento != '') {
    //   link += '?documento=$documento';
    //   yaTieneFiltro = true;
    // }
    // if (codTecnico != '') {
    //   yaTieneFiltro ? link += '&' : link += '?';
    //   link += 'codTecnico=$codTecnico';
    //   yaTieneFiltro = true;
    // }
    if (nombre != '') {
      // yaTieneFiltro ? link += '&' : link += '?';
      link += '&nombre=$nombre';
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
      final List<dynamic> tecnicoList = resp.data;

      return tecnicoList.map((obj) => Tecnico.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future postTecnico(BuildContext context, Tecnico tecnico, String token) async {
    String link = '${apiUrl}api/v1/tecnicos/';

    try {
      var headers = {'Authorization': token};
      final resp = await _dio.request(
        link,
        data: tecnico.toMap(),
        options: Options(
          method: 'POST', 
          headers: headers
        )
      );

      statusCode = 1;
      tecnico.tecnicoId = resp.data['tecnicoId'];

      // if (resp.statusCode == 201) {
      //   showErrorDialog(context, 'Tecnico creado correctamente');
      // }

      return Tecnico.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putTecnico(BuildContext context, Tecnico tecnico, String token) async {
    String link = '${apiUrl}api/v1/tecnicos/${tecnico.tecnicoId}/';

    try {
      var headers = {'Authorization': token};
      //var xx = tecnico.toMap();
      final resp = await _dio.request(
        link,
        data: tecnico.toMap(),
        options: Options(
          method: 'PUT', 
          headers: headers
        )
      );

      statusCode = 1;
      if (resp.statusCode == 200) {
        // showErrorDialog(context, 'Tecnico actualizado correctamente');
      }

      return Tecnico.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future deleteTecnico(BuildContext context, Tecnico tecnico, String token) async {
    String link = '${apiUrl}api/v1/tecnicos/${tecnico.tecnicoId}/';

    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link += tecnico.tecnicoId.toString(),
        options: Options(
          method: 'DELETE', 
          headers: headers
        )
      );

      statusCode = 1;
      if (resp.statusCode == 204) {
        // showDialogs(context, 'Tecnico borrado correctamente', true, true);
      }
      return resp.statusCode;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putTecnicoFirma(BuildContext context, int id, String token, Uint8List? firma, String? fileName, String md5) async {
    String link = '${apiUrl}api/v1/tecnicos/$id/firma';
    FormData formData = FormData.fromMap({
      'firma': MultipartFile.fromBytes(firma as List<int>, filename: fileName),
      'firmaMD5': md5,
    });

    try {
      var headers = {'Authorization': token};
      print(formData);
      var resp = await _dio.put(
        link,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: headers,
        ),
      );

      statusCode = 1;
      // if (resp.statusCode == 201) {
      //   showDialogs(context, 'PDF subido', false, false);
      // }
      return resp;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putTecnicoAvatar(BuildContext context, int id, String token, Uint8List? avatar, String? fileName, String md5) async {
    String link = '${apiUrl}api/v1/tecnicos/$id/foto';
    FormData formData = FormData.fromMap({
      'foto': MultipartFile.fromBytes(avatar as List<int>, filename: 'avatarTecnico.jpg'),
      'fotoMD5': md5,
    });

    try {
      var headers = {'Authorization': token};
      print(formData);
      var resp = await _dio.put(
        link,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: headers,
        ),
      );

      statusCode = 1;
      // if (resp.statusCode == 201) {
      //   showDialogs(context, 'PDF subido', false, false);
      // }
      return resp;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }
}
