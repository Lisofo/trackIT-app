// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';

class LoginServices {
  int? statusCode;
  String apiUrl = Config.APIURL;
  late String apiLink = '${apiUrl}api/auth/login-pin';
  late String apiLink2 = '${apiUrl}api/auth/pin';

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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> login(String login, pin2, BuildContext context) async {
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({"login": login, "pin2": pin2});
    var dio = Dio();
    String link = apiLink;
    try {
      var response = await dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;

      if (statusCode == 1) {
        print(response.data['token']);
        Provider.of<OrdenProvider>(context, listen: false).setToken(response.data['token']);
        Provider.of<OrdenProvider>(context, listen: false).setUsuarioId(response.data['uid']);
        Provider.of<OrdenProvider>(context, listen: false).setNombreUsuario(response.data['name']);
        // Provider.of<OrdenProvider>(context, listen: false).setTecnicoId(response.data['tecnicoId']);
      } else {
        print(response.statusMessage);
      }
    } catch (e) {
      // statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          statusCode = e.response!.statusCode;
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            // } else{
            //   final errors = responseData['errors'] as List<dynamic>;
            //   final errorMessages = errors.map((error) {
            //   return "Error: ${error['message']}";
            // }).toList();
            // showErrorDialog(context, errorMessages.join('\n'));
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

  Future<void> pin2(pin2, BuildContext context) async {
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({"pin2": pin2});
    var dio = Dio();
    String link = apiLink2;
    try {
      var response = await dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;

      if (statusCode == 1) {
        print(response.data['token']);
        Provider.of<OrdenProvider>(context, listen: false).setToken(response.data['token']);
        Provider.of<OrdenProvider>(context, listen: false).setUsuarioId(response.data['uid']);
        Provider.of<OrdenProvider>(context, listen: false).setNombreUsuario(response.data['name']);
        Provider.of<OrdenProvider>(context, listen: false).setTecnicoId(response.data['tecnicoId']);
      } else {
        print(response.statusMessage);
      }
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          statusCode = e.response!.statusCode;
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            // } else{
            //   final errors = responseData['errors'] as List<dynamic>;
            //   final errorMessages = errors.map((error) {
            //   return "Error: ${error['message']}";
            // }).toList();
            // showErrorDialog(context, errorMessages.join('\n'));
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

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }
}
