// services/excel_consumo_service.dart
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/material_consumo.dart';
import 'package:app_tec_sedel/models/orden.dart';

class ExcelConsumoService {
  
  TablaConsumoExcel procesarDatosReales(List<Linea> lineas, List<Orden> ordenesSeleccionadas) {
    final tabla = TablaConsumoExcel();
    tabla.ordenesColumnas = ordenesSeleccionadas;
    
    // Filtrar líneas que son materiales (itemId == piezaId)
    final lineasMateriales = lineas.where((linea) => 
      linea.itemId == linea.piezaId && linea.itemId != 0
    ).toList();

    // Agrupar por material y procesar datos reales
    tabla.filas = _crearFilasConDatosReales(lineasMateriales, ordenesSeleccionadas);
    tabla.calcularTotales();
    
    return tabla;
  }

  List<FilaConsumoExcel> _crearFilasConDatosReales(
    List<Linea> lineasMateriales, 
    List<Orden> ordenesSeleccionadas
  ) {
    final List<FilaConsumoExcel> filas = [];
    final materialesAgrupados = _agruparMateriales(lineasMateriales);
    
    for (var entry in materialesAgrupados.entries) {
      final lineasMaterial = entry.value;
      final primeraLinea = lineasMaterial.first;
      
      // Usar datos reales de las líneas
      final consumosAnteriores = _calcularConsumosAnteriores(lineasMaterial);
      final consumosPorOrden = _calcularConsumosPorOrden(lineasMaterial, ordenesSeleccionadas);
      
      // Calcular totales
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
        consumoCalculado: consumoCalculado, // Nuevo campo
        descripcionS: primeraLinea.descripcion,
        descripcionT: primeraLinea.lote,
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

  Map<String, double> _calcularConsumosAnteriores(List<Linea> lineasMaterial) {
    // Columnas fijas de consumos anteriores (4 columnas)
    return {
      'ant_1': 0.0,
      'ant_2': 0.0, 
      'ant_3': 0.0,
      'ant_4': 0.0,
    };
  }

  Map<String, double> _calcularConsumosPorOrden(
    List<Linea> lineasMaterial, 
    List<Orden> ordenesSeleccionadas
  ) {
    final consumos = <String, double>{};
    
    // Inicializar todas las órdenes en 0
    for (var orden in ordenesSeleccionadas) {
      consumos[orden.ordenTrabajoId.toString()] = 0.0;
    }
    
    // Sumar las cantidades por orden
    for (var linea in lineasMaterial) {
      final ordenId = linea.ordenTrabajoId.toString();
      if (consumos.containsKey(ordenId)) {
        consumos[ordenId] = consumos[ordenId]! + linea.control;
      }
    }
    
    return consumos;
  }
}