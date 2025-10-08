// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/tipo_clientes.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ClientServices {
  List posts = [];
  List pagina = [];
  String apiUrl = Config.APIURL;

  int limit = 20;
  bool isLoadingMore = false;
  final _dio = Dio();
  int? statusCode;

  Future<int?> getStatusCode () async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }

  Future getClientes(BuildContext context, String nombre, String codCliente, String? estado, String tecnicoId, String token) async {
    String link = '${apiUrl}api/v1/clientes/?offset=0&sort=nombre';
    bool yaTieneFiltro = true;
    if (nombre != '') {
      link += '&nombre=$nombre';
      yaTieneFiltro = true;
    }
    if (codCliente != '') {
      yaTieneFiltro ? link += '&' : link += '?';
      link += 'codCliente=$codCliente';
      yaTieneFiltro = true;
    }
    if (estado != '' && estado != null) {
      yaTieneFiltro ? link += '&' : link += '?';
      link += 'estado=$estado';
      yaTieneFiltro = true;
    }
    if (tecnicoId != '' && tecnicoId != '0') {
      yaTieneFiltro ? link += '&' : link += '?';
      link += 'tecnicoId=$tecnicoId';
      yaTieneFiltro = true;
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
      final List<dynamic> clienteList = resp.data;

      return clienteList.map((obj) => Cliente.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future getClientesDepartamentos(BuildContext context, String token) async {
    String link = '${apiUrl}api/v1/clientes/departamentos?sort=descripcion';

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
      final List departamentosClientesList = resp.data;

      return departamentosClientesList.map((obj) => Departamento.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future getTipoClientes(BuildContext context, String token) async {
    String link = '${apiUrl}api/v1/clientes/tipos';

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
      final List tiposClientesList = resp.data;

      return tiposClientesList.map((obj) => TipoClientes.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future putCliente(BuildContext context, Cliente cliente, String token) async {
    String link = '${apiUrl}api/v1/clientes/${cliente.clienteId}';
    var headers = {'Authorization': token};

    var map = cliente.toMap();

    try {
      final resp = await _dio.request(
        link,
        data: map, 
        options: Options(
          method: 'PUT', 
          headers: headers
        )
      );

      statusCode = 1;
      print(resp.statusCode);
      if (resp.statusCode == 200) {
        // await Carteles.showDialogs(context, 'Cliente actualizado correctamente', true, false, false);
      }
      return Cliente.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future postCliente(BuildContext context, Cliente cliente, String token) async {
    String link = '${apiUrl}api/v1/clientes/';
    print(cliente.toMap());

    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        data: cliente.toMap(),
        options: Options(
          method: 'POST', 
          headers: headers
        )
      );

      statusCode = 1;
      cliente.clienteId = resp.data['clienteId'];

      if (resp.statusCode == 201) {
        // Carteles.showDialogs(context, 'Cliente creado correctamente', true, false, false);
      }

      return Cliente.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }
  
  Future deleteCliente(BuildContext context, Cliente cliente, String token) async {
    try {
      String link = '${apiUrl}api/v1/clientes/${cliente.clienteId}';
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE', 
          headers: headers
        )
      );

      statusCode = 1;
      if (resp.statusCode == 204) {
        // Carteles.showDialogs(context, 'Cliente borrado correctamente', true, true, false);
      }
      return resp.statusCode;
      
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  void errorManagment(Object e, BuildContext context) {
    if (e is DioException) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData != null) {
          if (e.response!.statusCode == 403) {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
          }else if (e.response!.statusCode! >= 500) {
            Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
          } else {
            final errors = responseData['errors'] as List<dynamic>;
            final errorMessages = errors.map((error) {
              return "Error: ${error['message']}";
            }).toList();
            Carteles.showErrorDialog(context, errorMessages.join('\n'));
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
        }
      } else {
        Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
      }
    }
  }
}
