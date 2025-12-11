// models/material_consumo.dart
import 'package:app_tec_sedel/models/orden.dart';

class MaterialConsumo {
  final int itemId;
  final String codItem;
  final String descripcion;
  final String macroFamilia;
  final String familia;
  final double cantidad;
  final String lote;
  final int ordenTrabajoId;
  final String numeroOrdenTrabajo;
  
  // Campos para cálculos
  double porcentajeConMerma = 0.0;
  double porcentajeSinMerma = 0.0;
  double mermaProceso = 0.0;
  double porcentajeMerma = 0.0;

  MaterialConsumo({
    required this.itemId,
    required this.codItem,
    required this.descripcion,
    required this.macroFamilia,
    required this.familia,
    required this.cantidad,
    required this.lote,
    required this.ordenTrabajoId,
    required this.numeroOrdenTrabajo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialConsumo &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId;

  @override
  int get hashCode => itemId.hashCode;
}

// models/consumo_excel.dart
class FilaConsumoExcel {
  final String codigo;
  final String articulo;
  final String at;
  Map<String, double> consumosAnteriores; // Cambiado a mutable
  Map<String, double> consumosPorOrden; // Cambiado a mutable
  double totalFila; // Cambiado a mutable
  double consumoCalculado; // Nuevo campo: sum(ordenes) - sum(anteriores)
  final String descripcionS;
  final String descripcionT;

  FilaConsumoExcel({
    required this.codigo,
    required this.articulo,
    required this.at,
    required this.consumosAnteriores,
    required this.consumosPorOrden,
    required this.totalFila,
    required this.consumoCalculado, // Nuevo campo
    required this.descripcionS,
    required this.descripcionT,
  });
}

class TablaConsumoExcel {
  List<FilaConsumoExcel> filas = [];
  List<Orden> ordenesColumnas = [];
  Map<String, double> totalesColumnas = {};
  Map<String, double> totalesFilas = {};
  Map<String, double> totalesConsumo = {}; // Nuevo: totales por fila para consumo
  double totalEmbarcar = 18720.0;
  double totalEnvasado = 0.0;
  double mermaProceso = 0.0;
  double porcentajeMerma = 0.0;
  double totalConsumoGeneral = 0.0; // Nuevo: total de la columna consumo

  void calcularTotales() {
    totalesColumnas = {};
    totalesFilas = {};
    totalesConsumo = {};
    totalConsumoGeneral = 0.0;
    
    // Inicializar columnas fijas (4 columnas de anteriores)
    for (int i = 1; i <= 4; i++) {
      totalesColumnas['ant_$i'] = 0.0;
    }
    
    // Inicializar columnas dinámicas por orden
    for (var orden in ordenesColumnas) {
      totalesColumnas[orden.ordenTrabajoId.toString()] = 0.0;
    }
    
    totalesColumnas['total'] = 0.0;
    totalesColumnas['consumo'] = 0.0; // Nueva columna

    // Calcular totales por fila y por columna
    for (var fila in filas) {
      double totalFila = 0.0;
      double sumaAnteriores = 0.0;
      double sumaOrdenes = 0.0;
      
      // Sumar consumos anteriores (4 columnas)
      fila.consumosAnteriores.forEach((columna, valor) {
        totalesColumnas[columna] = (totalesColumnas[columna] ?? 0) + valor;
        totalFila += valor;
        sumaAnteriores += valor;
      });
      
      // Sumar consumos por orden
      fila.consumosPorOrden.forEach((ordenId, valor) {
        totalesColumnas[ordenId] = (totalesColumnas[ordenId] ?? 0) + valor;
        totalFila += valor;
        sumaOrdenes += valor;
      });
      
      // Calcular consumo: suma de órdenes - suma de anteriores
      double consumoFila = sumaOrdenes - sumaAnteriores;
      fila.consumoCalculado = consumoFila;
      totalesColumnas['consumo'] = (totalesColumnas['consumo'] ?? 0) + consumoFila;
      totalesConsumo[fila.codigo] = consumoFila;
      totalConsumoGeneral += consumoFila;
      
      // Actualizar el totalFila de la fila
      fila.totalFila = totalFila;
      
      // Guardar total de la fila
      totalesFilas[fila.codigo] = totalFila;
      
      // Acumular total general
      totalesColumnas['total'] = (totalesColumnas['total'] ?? 0) + totalFila;
    }

    totalEnvasado = totalesColumnas['total'] ?? 0.0;
    mermaProceso = totalEmbarcar - totalEnvasado;
    porcentajeMerma = totalEnvasado > 0 ? (mermaProceso / totalEnvasado) * 100 : 0.0;
  }

  // Nuevo método para actualizar un valor específico
  void actualizarValor(String codigoMaterial, String columna, double nuevoValor) {
    for (var fila in filas) {
      if (fila.codigo == codigoMaterial) {
        if (columna.startsWith('ant_')) {
          fila.consumosAnteriores[columna] = nuevoValor;
        } else {
          fila.consumosPorOrden[columna] = nuevoValor;
        }
        break;
      }
    }
    calcularTotales();
  }

  // Método para obtener un valor específico
  double? obtenerValor(String codigoMaterial, String columna) {
    for (var fila in filas) {
      if (fila.codigo == codigoMaterial) {
        if (columna.startsWith('ant_')) {
          return fila.consumosAnteriores[columna];
        } else {
          return fila.consumosPorOrden[columna];
        }
      }
    }
    return null;
  }

  // Método para obtener el consumo calculado de una fila
  double obtenerConsumoFila(String codigoMaterial) {
    for (var fila in filas) {
      if (fila.codigo == codigoMaterial) {
        return fila.consumoCalculado;
      }
    }
    return 0.0;
  }
}