// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LineasServices {
  final _dio = Dio();
  String apiLink = Config.APIURL;
  int? statusCode = 0;

  // GET - Obtener todas las líneas de una orden
  Future<List<Linea>> getLineasDeOrden(
    BuildContext context, 
    int ordenTrabajoId, 
    String token
  ) async {
    String link = '${apiLink}api/v1/ordenes/$ordenTrabajoId/lineas/';

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
      final List<dynamic> lineasList = resp.data;
      
      // Usar tu factory method lineaFromJson
      var retorno = lineasList.map((json) => Linea.fromJson(json)).toList();
      print('Líneas obtenidas: ${retorno.length}');
      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // POST - Crear una nueva línea en una orden
  Future<Linea> crearLinea(
    BuildContext context, 
    int ordenTrabajoId, 
    Linea linea, 
    String token
  ) async {
    String link = '${apiLink}api/v1/ordenes/$ordenTrabajoId/lineas';

    try {
      var headers = {'Authorization': token};
      // Usar toJsonCyP() que incluye los campos específicos
      var data = linea.toJsonCyP();

      
      print('Creando línea con datos: $data');
      
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      
      statusCode = 1;
      print('Línea creada: ${resp.data}');
      
      // Usar fromJson para crear el objeto desde la respuesta
      var retorno = Linea.fromJson(resp.data);
      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // PUT - Actualizar una línea existente
  Future<Linea> actualizarLinea(
    BuildContext context, 
    int ordenTrabajoId, 
    Linea linea, 
    String token
  ) async {
    String link = '${apiLink}api/v1/ordenes/$ordenTrabajoId/lineas/${linea.lineaId}';

    try {
      var headers = {'Authorization': token};
      // Usar toJsonCyP() que incluye los campos específicos
      var data = linea.toJsonCyP();
      
      print('Actualizando línea ${linea.lineaId} con datos: $data');
      
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data
      );
      
      statusCode = 1;
      print('Línea actualizada: ${resp.data}');
      
      var retorno = Linea.fromJson(resp.data);
      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // DELETE - Eliminar una línea
  Future<bool> eliminarLinea(
    BuildContext context, 
    int ordenTrabajoId, 
    int lineaId, 
    String token
  ) async {
    String link = '${apiLink}api/v1/ordenes/$ordenTrabajoId/lineas/$lineaId';

    try {
      var headers = {'Authorization': token};
      
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );
      statusCode = resp.statusCode;
      statusCode = 1;
      print('Línea $lineaId eliminada correctamente');
      return true;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // Método para crear múltiples líneas en lote
  Future<List<Linea>> crearLineasEnLote(
    BuildContext context, 
    int ordenTrabajoId, 
    List<Linea> lineas, 
    String token
  ) async {
    List<Linea> lineasCreadas = [];
    
    for (var linea in lineas) {
      try {
        final lineaCreada = await crearLinea(context, ordenTrabajoId, linea, token);
        lineasCreadas.add(lineaCreada);
      } catch (e) {
        print('Error creando línea: $e');
        // Continuar con las siguientes líneas aunque falle una
      }
    }
    
    return lineasCreadas;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }
}