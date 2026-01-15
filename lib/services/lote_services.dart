// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/lote.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LoteServices {
  final Dio _dio = Dio();
  String apiLink = Config.APIURL;
  int? statusCode = 0;

  // 1. Obtener lista de lotes (similar a getOrden)
  Future<List<Lote>> getLotes(
    BuildContext context,
    String token, {
    int? tecnicoId,
    int? ordenTrabajoId,
    String? estado,
    Map<String, dynamic>? queryParams,
  }) async {
    String link = '${apiLink}api/v1/lotes';

    try {
      var headers = {'Authorization': token};
      
      // Agregar parámetros de consulta si existen
      final Map<String, dynamic> finalQueryParams = {};

      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: finalQueryParams.isNotEmpty ? finalQueryParams : null,
      );

      statusCode = 1;
      final List<dynamic> loteList = resp.data;
      return loteList.map((obj) => Lote.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 2. Obtener lote por ID
  Future<Lote> getLotePorId(
    BuildContext context,
    int loteId,
    String token,
  ) async {
    String link = '${apiLink}api/v1/lotes/$loteId';

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
      return Lote.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 3. Crear un nuevo lote (POST)
  Future<Lote> createLote(
    BuildContext context,
    String token,
    Lote lote,
    List<int> ordenesIds,
  ) async {
    String link = '${apiLink}api/v1/lotes';

    try {
      var headers = {'Authorization': token};
      
      // Formatear la fecha al formato que espera la API (YYYY-MM-DD)
      String fechaFormateada = lote.fechaLote != null 
        ? lote.fechaLote!.toIso8601String().split('T')[0]
        : DateTime.now().toIso8601String().split('T')[0];

      var data = {
        "pedidoId": null,
        "lote": lote.lote,
        "totalEmbarcar": lote.totalEmbarcar,
        "nvporc": lote.nvporc,
        "visc": lote.visc,
        "fechaLote": fechaFormateada,
        "observaciones": lote.observaciones,
        "estado": lote.estado,
        "ordenes": ordenesIds,
        // NUEVOS ATRIBUTOS AÑADIDOS
        "picoProduccion": lote.picoProduccion,
        "cantTambores": lote.cantTambores,
        "kgTambor": lote.kgTambor,
        "mermaProceso": lote.mermaProceso,
        "porcentajeMerma": lote.porcentajeMerma,
        "cantPallets": lote.cantPallets,
      };

      print('Datos a enviar: $data');

      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;
      return Lote.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 4. Modificar un lote existente (PUT)
  Future<Lote> updateLote(
    BuildContext context,
    String token,
    Lote lote,
    List<int> ordenesIds,
  ) async {
    String link = '${apiLink}api/v1/lotes/${lote.loteId}';

    try {
      var headers = {'Authorization': token};
      
      // Formatear la fecha al formato que espera la API (YYYY-MM-DD)
      String fechaFormateada = lote.fechaLote != null 
        ? lote.fechaLote!.toIso8601String().split('T')[0]
        : DateTime.now().toIso8601String().split('T')[0];

      var data = {
        "pedidoId": lote.pedidoId,
        "lote": lote.lote,
        "totalEmbarcar": lote.totalEmbarcar,
        "nvporc": lote.nvporc,
        "visc": lote.visc,
        "fechaLote": fechaFormateada,
        "observaciones": lote.observaciones,
        "estado": lote.estado,
        "ordenes": ordenesIds,
        // NUEVOS ATRIBUTOS AÑADIDOS
        "picoProduccion": lote.picoProduccion,
        "cantTambores": lote.cantTambores,
        "kgTambor": lote.kgTambor,
        "mermaProceso": lote.mermaProceso,
        "porcentajeMerma": lote.porcentajeMerma,
        "cantPallets": lote.cantPallets,
      };

      print('Datos a actualizar: $data');

      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;
      return Lote.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 5. Obtener líneas de un lote
  Future<List<LineaLote>> getLineasLote(
    BuildContext context,
    int loteId,
    String token,
  ) async {
    String link = '${apiLink}api/v1/lotes/$loteId/lineas';

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
      return lineasList.map((obj) => LineaLote.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 6. Agregar una línea a un lote (POST)
  Future<LineaLote> createLineaLote(
    BuildContext context,
    String token,
    int loteId,
    LineaLote linea,
  ) async {
    String link = '${apiLink}api/v1/lotes/$loteId/lineas';

    try {
      var headers = {'Authorization': token};
      
      var data = {
        "itemId": linea.itemId,
        "ordinal": linea.ordinal,
        "cantidad": linea.cantidad,
        "costoUnitario": linea.costoUnitario ?? 0.0,
        "comentario": linea.comentario,
        "accionId": linea.accionId ?? 0,
        "piezaId": linea.piezaId,
        "control": linea.control,
        "lote": linea.lote ?? '',
        "referencia": linea.referencia,
        "agrupador": linea.agrupador,
      };

      print('Datos de línea a crear: $data');

      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;
      return LineaLote.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 7. Modificar una línea de un lote (PUT)
  Future<LineaLote> updateLineaLote(
    BuildContext context,
    String token,
    int loteId,
    LineaLote linea,
  ) async {
    String link = '${apiLink}api/v1/lotes/$loteId/lineas/${linea.lineaId}';

    try {
      var headers = {'Authorization': token};
      
      var data = {
        "loteId": linea.loteId,
        "itemId": linea.itemId,
        "ordinal": linea.ordinal,
        "cantidad": linea.cantidad,
        "costoUnitario": linea.costoUnitario ?? 0.0,
        "comentario": linea.comentario,
        "accionId": linea.accionId ?? 0,
        "piezaId": linea.piezaId,
        "control": linea.control,
        "lote": linea.lote ?? '',
        "referencia": linea.referencia,
        "agrupador": linea.agrupador,
      };

      print('Datos de línea a actualizar: $data');

      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;
      return LineaLote.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 8. Eliminar una línea de un lote (DELETE)
  Future<void> deleteLineaLote(
    BuildContext context,
    String token,
    int loteId,
    int lineaId,
  ) async {
    String link = '${apiLink}api/v1/lotes/$loteId/lineas/$lineaId';

    try {
      var headers = {'Authorization': token};
      
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );

      statusCode = 1;
      if (resp.statusCode == 204) {
        print('Línea eliminada exitosamente');
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al eliminar la línea');
      }
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  // 9. Métodos auxiliares para manejo de estado
  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }
}