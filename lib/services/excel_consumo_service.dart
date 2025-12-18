// services/excel_consumo_service.dart
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/lote.dart';
import 'package:app_tec_sedel/models/material_consumo.dart';
import 'package:app_tec_sedel/models/orden.dart';

class ExcelConsumoService {
  
  TablaConsumoExcel procesarDatosReales(
    List<Linea> lineas, 
    List<Orden> ordenesSeleccionadas,
    List<LineaLote> lineasLote, // NUEVO PARÁMETRO
  ) {
    final tabla = TablaConsumoExcel();
    tabla.ordenesColumnas = ordenesSeleccionadas;
    
    final lineasMateriales = lineas.where((linea) => 
      linea.itemId == linea.piezaId && linea.itemId != 0
    ).toList();

    tabla.filas = _crearFilasConDatosReales(
      lineasMateriales, 
      ordenesSeleccionadas,
      lineasLote, // Pasar líneas de lote
    );
    tabla.calcularTotales();
    
    return tabla;
  }

  List<FilaConsumoExcel> _crearFilasConDatosReales(
    List<Linea> lineasMateriales, 
    List<Orden> ordenesSeleccionadas,
    List<LineaLote> lineasLote,
  ) {
    final List<FilaConsumoExcel> filas = [];
    final materialesAgrupados = _agruparMateriales(lineasMateriales);
    
    for (var entry in materialesAgrupados.entries) {
      final lineasMaterial = entry.value;
      final primeraLinea = lineasMaterial.first;
      
      final consumosAnteriores = _calcularConsumosAnteriores(
        lineasMaterial, 
        lineasLote
      );
      
      final consumosPorOrden = _calcularConsumosPorOrden(
        lineasMaterial, 
        ordenesSeleccionadas
      );
      
      double sumaAnteriores = consumosAnteriores.values.fold(0.0, (sum, valor) => sum + valor);
      double sumaOrdenes = consumosPorOrden.values.fold(0.0, (sum, valor) => sum + valor);
      double totalFila = sumaAnteriores + sumaOrdenes;
      double consumoCalculado = sumaOrdenes - sumaAnteriores;
      
      final fila = FilaConsumoExcel(
        codigo: primeraLinea.codItem,
        articulo: primeraLinea.descripcion,
        at: primeraLinea.macroFamilia,
        consumosAnteriores: consumosAnteriores,
        consumosPorOrden: consumosPorOrden,
        totalFila: totalFila,
        consumoCalculado: consumoCalculado,
        descripcionS: primeraLinea.descripcion,
        descripcionT: primeraLinea.lote,
        itemId: primeraLinea.itemId, // Pasar itemId
      );
      
      filas.add(fila);
    }
    
    return filas;
  }

  Map<int, List<Linea>> _agruparMateriales(List<Linea> lineas) {
    final Map<int, List<Linea>> agrupados = {};
    
    for (var linea in lineas) {
      if (!agrupados.containsKey(linea.itemId)) {
        agrupados[linea.itemId] = [];
      }
      agrupados[linea.itemId]!.add(linea);
    }
    
    return agrupados;
  }

  Map<String, double> _calcularConsumosAnteriores(
    List<Linea> lineasMaterial,
    List<LineaLote> lineasLote,
  ) {
    final consumos = <String, double>{
      'ant_1': 0.0,
      'ant_2': 0.0,
      'ant_3': 0.0,
      'ant_4': 0.0,
    };
    
    if (lineasMaterial.isEmpty) return consumos;
    
    final itemId = lineasMaterial.first.itemId;
    
    final lineasLoteItem = lineasLote.where((linea) => linea.itemId == itemId);
    
    for (var lineaLote in lineasLoteItem) {
      // USAR REFERENCIA PARA MAPEAR A LA COLUMNA CORRECTA
      if (lineaLote.referencia != null && consumos.containsKey(lineaLote.referencia)) {
        final valor = lineaLote.control ?? '0';
        consumos[lineaLote.referencia!] = valor.toString().isNotEmpty 
          ? double.parse(valor.toString()) 
          : 0.0;
      }
    }
    
    return consumos;
  }

  Map<String, double> _calcularConsumosPorOrden(
    List<Linea> lineasMaterial, 
    List<Orden> ordenesSeleccionadas
  ) {
    final consumos = <String, double>{};
    
    for (var orden in ordenesSeleccionadas) {
      consumos[orden.ordenTrabajoId.toString()] = 0.0;
    }
    
    for (var linea in lineasMaterial) {
      final ordenId = linea.ordenTrabajoId.toString();
      if (consumos.containsKey(ordenId)) {
        consumos[ordenId] = consumos[ordenId]! + linea.control;
      }
    }
    
    return consumos;
  }
}