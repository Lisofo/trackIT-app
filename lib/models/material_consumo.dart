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
  Map<String, double> consumosAnteriores;
  Map<String, double> consumosPorOrden;
  double totalFila;
  double consumoCalculado;
  final String descripcionS;
  final String descripcionT;
  final int itemId; // NUEVO CAMPO

  FilaConsumoExcel({
    required this.codigo,
    required this.articulo,
    required this.at,
    required this.consumosAnteriores,
    required this.consumosPorOrden,
    required this.totalFila,
    required this.consumoCalculado,
    required this.descripcionS,
    required this.descripcionT,
    required this.itemId, // NUEVO PARÁMETRO
  });
}

class TablaConsumoExcel {
  List<FilaConsumoExcel> filas = [];
  List<Orden> ordenesColumnas = [];
  Map<String, double> totalesColumnas = {};
  Map<String, double> totalesFilas = {};
  Map<String, double> totalesConsumo = {};
  double totalEmbarcar = 18720.0;
  double totalEnvasado = 0.0;
  double mermaProceso = 0.0;
  double porcentajeMerma = 0.0;
  double totalConsumoGeneral = 0.0;

  void calcularTotales() {
    totalesColumnas = {};
    totalesFilas = {};
    totalesConsumo = {};
    totalConsumoGeneral = 0.0;
    
    for (int i = 1; i <= 4; i++) {
      totalesColumnas['ant_$i'] = 0.0;
    }
    
    for (var orden in ordenesColumnas) {
      totalesColumnas[orden.ordenTrabajoId.toString()] = 0.0;
    }
    
    totalesColumnas['total'] = 0.0;
    totalesColumnas['consumo'] = 0.0;

    for (var fila in filas) {
      double totalFila = 0.0;
      double sumaAnteriores = 0.0;
      double sumaOrdenes = 0.0;
      
      fila.consumosAnteriores.forEach((columna, valor) {
        totalesColumnas[columna] = (totalesColumnas[columna] ?? 0) + valor;
        totalFila += valor;
        sumaAnteriores += valor;
      });
      
      fila.consumosPorOrden.forEach((ordenId, valor) {
        totalesColumnas[ordenId] = (totalesColumnas[ordenId] ?? 0) + valor;
        totalFila += valor;
        sumaOrdenes += valor;
      });
      
      double consumoFila = sumaOrdenes - sumaAnteriores;
      fila.consumoCalculado = consumoFila;
      totalesColumnas['consumo'] = (totalesColumnas['consumo'] ?? 0) + consumoFila;
      totalesConsumo[fila.codigo] = consumoFila;
      totalConsumoGeneral += consumoFila;
      
      fila.totalFila = totalFila;
      totalesFilas[fila.codigo] = totalFila;
      totalesColumnas['total'] = (totalesColumnas['total'] ?? 0) + totalFila;
    }

    totalEnvasado = totalesColumnas['total'] ?? 0.0;
    mermaProceso = totalEmbarcar - totalEnvasado;
    porcentajeMerma = totalEnvasado > 0 ? (mermaProceso / totalEnvasado) * 100 : 0.0;
  }

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

  double obtenerConsumoFila(String codigoMaterial) {
    for (var fila in filas) {
      if (fila.codigo == codigoMaterial) {
        return fila.consumoCalculado;
      }
    }
    return 0.0;
  }

  // NUEVO MÉTODO: Obtener itemId de una fila
  int? obtenerItemIdFila(String codigoMaterial) {
    for (var fila in filas) {
      if (fila.codigo == codigoMaterial) {
        return fila.itemId;
      }
    }
    return null;
  }

  // NUEVO MÉTODO: Obtener fila completa
  FilaConsumoExcel? obtenerFila(String codigoMaterial) {
    for (var fila in filas) {
      if (fila.codigo == codigoMaterial) {
        return fila;
      }
    }
    return null;
  }

  // NUEVO MÉTODO: Calcular porcentajes de distribución
  Map<String, Map<String, double>> calcularPorcentajes() {
    final porcentajes = <String, Map<String, double>>{};
    
    // Calcular totales por columna primero
    final totalesPorColumna = <String, double>{};
    
    // Sumar ANT1-4
    for (int i = 1; i <= 4; i++) {
      final columna = 'ant_$i';
      totalesPorColumna[columna] = filas.fold(
        0.0, 
        (sum, fila) => sum + (fila.consumosAnteriores[columna] ?? 0.0)
      );
    }
    
    // Sumar órdenes
    for (var fila in filas) {
      for (var ordenId in fila.consumosPorOrden.keys) {
        totalesPorColumna[ordenId] = (totalesPorColumna[ordenId] ?? 0.0) + 
                                   (fila.consumosPorOrden[ordenId] ?? 0.0);
      }
    }
    
    // Calcular porcentaje para cada fila y columna
    for (var fila in filas) {
      porcentajes[fila.codigo] = {};
      
      // Porcentajes para ANT1-4
      for (int i = 1; i <= 4; i++) {
        final columna = 'ant_$i';
        final valor = fila.consumosAnteriores[columna] ?? 0.0;
        final totalColumna = totalesPorColumna[columna] ?? 1.0; // Evitar división por 0
        final porcentaje = totalColumna > 0 ? (valor / totalColumna) * 100 : 0.0;
        porcentajes[fila.codigo]![columna] = porcentaje;
      }
      
      // Porcentajes para órdenes
      for (var ordenId in fila.consumosPorOrden.keys) {
        final valor = fila.consumosPorOrden[ordenId] ?? 0.0;
        final totalColumna = totalesPorColumna[ordenId] ?? 1.0;
        final porcentaje = totalColumna > 0 ? (valor / totalColumna) * 100 : 0.0;
        porcentajes[fila.codigo]![ordenId] = porcentaje;
      }
    }
    
    return porcentajes;
  }
}