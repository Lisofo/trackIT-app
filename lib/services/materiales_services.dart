// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/manuales_materiales.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/materialesTPI.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/models/tipos_ptos_inspeccion.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class MaterialesServices {
  final _dio = Dio();
  String apiUrl = Config.APIURL;
  int? statusCode;

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future getMateriales(BuildContext context,String token) async {
    String link = '${apiUrl}api/v1/materiales/';
    // String link = '${apiUrl}api/v1/materiales/?enAppTecnico=S&enUso=S&sort=descripcion';
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
      final List<dynamic> materialList = resp.data;

      return materialList.map((obj) => Materiales.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putMaterial(BuildContext context, Materiales material, String token) async {
    String link = '${apiUrl}api/v1/materiales/${material.materialId}';
    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        data: material.toMap(),
        options: Options(
          method: 'PUT', 
          headers: headers
        )
      );

      statusCode = 1;
      if (resp.statusCode == 200) {
        // showDialogs(context, 'Material actualizado correctamente', false, false);
      }
      return Materiales.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future postMaterial( BuildContext context, Materiales material, String token) async {
    String link = '${apiUrl}api/v1/materiales/';
    try {
      var headers = {'Authorization': token};

      final resp = await _dio.request(
        link,
        data: material.toMap(),
        options: Options(
          method: 'POST', 
          headers: headers
        )
      );

      statusCode = 1;
      material.materialId = resp.data['materialId'];

      if (resp.statusCode == 201) {
        // showDialogs(context, 'Material creado correctamente', false, false);
      }

      return Materiales.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future deleteMaterial(BuildContext context, Materiales material, String token) async {
    String link = '${apiUrl}api/v1/materiales/${material.materialId}';
    try {
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
        // showDialogs(context, 'Material borrado correctamente', true, true);
      }
      return resp.statusCode;

    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getMaterialesXTPI(BuildContext context,TipoPtosInspeccion tPI, String token) async {
    String link = '${apiUrl}api/v1/tipos/puntos/${tPI.tipoPuntoInspeccionId}/materiales?sort=descripcion';

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
      final List<dynamic> materialXPTIList = resp.data;

      return materialXPTIList.map((obj) => MaterialXtpi.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getLotes(BuildContext context,int materialId, String token) async {
    String link = '${apiUrl}api/v1/materiales/$materialId/lotes';

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
      final List<dynamic> lotesList = resp.data;

      return lotesList.map((obj) => Lote.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getMetodosAplicacion(BuildContext context,String token) async {
    String link = '${apiUrl}api/v1/metodos-aplicacion/?sort=descripcion';
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

      return metodosList.map((obj) => MetodoAplicacion.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getRevisionMateriales(BuildContext context,Orden orden, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales';

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
      final List<dynamic> revisionMaterialesList = resp.data;

      return revisionMaterialesList.map((obj) => RevisionMaterial.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future postRevisionMaterial(BuildContext context, Orden orden, List<int> plagasIds, RevisionMaterial revisionMaterial, String token) async {
    
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales';
    var data = ({
      "idsPlagas": plagasIds,
      "comentario": "",
      "cantidad": revisionMaterial.cantidad,
      "idMaterialLote": revisionMaterial.lote?.materialLoteId == 0 ? null : revisionMaterial.lote?.materialLoteId,
      "idMetodoAplicacion": revisionMaterial.metodoAplicacion.metodoAplicacionId,
      "ubicacion": revisionMaterial.ubicacion,
      "areaCobertura": revisionMaterial.areaCobertura,
      "idMaterial": revisionMaterial.material.materialId
    });

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      if (resp.statusCode == 201) {
        revisionMaterial.otMaterialId = resp.data["otMaterialId"];
        // await showDialogs(context, 'Material guardado', true, false);
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future putRevisionMaterial(BuildContext context, Orden orden, List<int> plagasIds, RevisionMaterial revisionMaterial, String token) async {
    
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales/${revisionMaterial.otMaterialId}';
    var data = ({
      "idsPlagas": plagasIds,
      "comentario": "",
      "cantidad": revisionMaterial.cantidad,
      "idMaterialLote": revisionMaterial.lote?.materialLoteId == 0 ? null : revisionMaterial.lote?.materialLoteId,
      "idMetodoAplicacion": revisionMaterial.metodoAplicacion.metodoAplicacionId,
      "ubicacion": revisionMaterial.ubicacion,
      "areaCobertura": revisionMaterial.areaCobertura,
      "idMaterial": revisionMaterial.material.materialId
    });

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );

      statusCode = 1;
      if (resp.statusCode == 200) {
        // await showDialogs(context, 'Material editado', true, false);
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future deleteRevisionMaterial(BuildContext context, Orden orden, RevisionMaterial revisionMaterial, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/revisiones/${orden.otRevisionId}/materiales/${revisionMaterial.otMaterialId}';
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
        // showDialogs(context, 'Material borrado', true, false);
      }
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getManualesMateriales(BuildContext context, int id, String token) async {
    String link = apiUrl += 'api/v1/materiales/$id/manuales';
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
      final List<dynamic> materialList = resp.data;

      return materialList.map((obj) => ManualesMateriales.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getRepuestos(BuildContext context, Orden orden, String token) async {
    String link = '${apiUrl}api/v1/ordenes/${orden.ordenTrabajoId}/lineas/?MO=MA';

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
      final List<dynamic> tareaList = resp.data;

      return tareaList.map((obj) => Linea.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }
}
