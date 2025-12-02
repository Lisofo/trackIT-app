// screens/consumos_screen.dart
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/material_consumo.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/linea_services.dart';
import 'package:app_tec_sedel/services/excel_consumo_service.dart';
import 'package:provider/provider.dart';

class ConsumosScreen extends StatefulWidget {
  const ConsumosScreen({super.key});

  @override
  ConsumosScreenState createState() => ConsumosScreenState();
}

class ConsumosScreenState extends State<ConsumosScreen> {
  final OrdenServices _ordenServices = OrdenServices();
  final LineasServices _lineasServices = LineasServices();
  final ExcelConsumoService _excelService = ExcelConsumoService();
  
  List<Orden> _ordenes = [];
  List<Orden> _ordenesSeleccionadas = [];
  TablaConsumoExcel _tablaConsumo = TablaConsumoExcel();
  bool _cargando = false;
  bool _cargandoMateriales = false;

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
  }

  Future<void> _cargarOrdenes() async {
    setState(() => _cargando = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      String tecnicoId = authProvider.tecnicoId.toString();
      
      _ordenes = await _ordenServices.getOrden(context, tecnicoId, token);
    } catch (e) {
      print('Error cargando órdenes: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMateriales() async {
    if (_ordenesSeleccionadas.isEmpty) {
      setState(() {
        _tablaConsumo = TablaConsumoExcel();
        _cargandoMateriales = false;
      });
      return;
    }
    
    setState(() => _cargandoMateriales = true);

    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      List<Linea> todasLineas = [];

      for (var orden in _ordenesSeleccionadas) {
        final lineas = await _lineasServices.getLineasDeOrden(
          context, 
          orden.ordenTrabajoId!, 
          token
        );
        todasLineas.addAll(lineas);
      }

      // Procesar datos con columnas dinámicas
      // El orden de las columnas dinámicas estará dado por _ordenesSeleccionadas
      _tablaConsumo = _excelService.procesarDatosReales(todasLineas, _ordenesSeleccionadas);
      
    } catch (e) {
      print('Error cargando materiales: $e');
    } finally {
      setState(() => _cargandoMateriales = false);
    }
  }

  void _seleccionarTodasOrdenes() {
    setState(() {
      _ordenesSeleccionadas = List.from(_ordenes);
    });
    _cargarMateriales();
  }

  void _deseleccionarTodasOrdenes() {
    setState(() {
      _ordenesSeleccionadas.clear();
      _tablaConsumo = TablaConsumoExcel();
    });
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    
    return '${fecha.day}-${meses[fecha.month - 1]}-${fecha.year.toString().substring(2)}';
  }
  
  // Función para reordenar las órdenes seleccionadas (reordena las columnas dinámicas)
  void _onReorderOrdenes(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Orden item = _ordenesSeleccionadas.removeAt(oldIndex);
      _ordenesSeleccionadas.insert(newIndex, item);
    });
    // Llamar a _cargarMateriales para que la tabla se regenere con el nuevo orden.
    // El DropdownSearch se actualizará automáticamente porque en dropdownBuilder 
    // y selectedItems usamos _ordenesSeleccionadas.
    _cargarMateriales(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONSUMOS DE PRODUCCIÓN - RESYMAS 1248'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _seleccionarTodasOrdenes,
            tooltip: 'Seleccionar todas',
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: _deseleccionarTodasOrdenes,
            tooltip: 'Deseleccionar todas',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderExcel(),
          _buildSelectorOrdenes(),
          Expanded(child: _buildTablaExcelDinamica()),
          _buildTotalesYMermas(),
        ],
      ),
    );
  }

  Widget _buildHeaderExcel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONSUMOS DE PRODUCCIÓN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Producto: ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'RESYMAS 1248',
                style: TextStyle(fontSize: 14, color: Colors.blue[800]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Total a embarcar: ',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                '${_tablaConsumo.totalEmbarcar} kg',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorOrdenes() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Órdenes (Arrastra para reordenar columnas):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : DropdownSearch<Orden>.multiSelection(
                    items: _ordenes,
                    compareFn: (item1, item2) => item1.ordenTrabajoId == item2.ordenTrabajoId,
                    // **CORREGIDO:** Usamos _ordenesSeleccionadas como la fuente de verdad.
                    selectedItems: _ordenesSeleccionadas, 
                    onChanged: (List<Orden> nuevasSeleccionadas) {
                      setState(() {
                        // Lógica más limpia para actualizar _ordenesSeleccionadas manteniendo el orden de las ya existentes
                        final Map<int?, Orden> nuevaMap = {for (var o in nuevasSeleccionadas) o.ordenTrabajoId: o};
                        
                        // 1. Mantener las que siguen seleccionadas en el orden actual
                        final List<Orden> mantenidas = _ordenesSeleccionadas.where((o) => nuevaMap.containsKey(o.ordenTrabajoId)).toList();
                        
                        // 2. Añadir las nuevas al final
                        final Set<int?> mantenidasIds = mantenidas.map((o) => o.ordenTrabajoId).toSet();
                        final List<Orden> nuevasAniadidas = nuevasSeleccionadas.where((o) => !mantenidasIds.contains(o.ordenTrabajoId)).toList();
                        
                        _ordenesSeleccionadas = [...mantenidas, ...nuevasAniadidas];
                      });
                      _cargarMateriales();
                    },
                    // Usamos el builder para mostrar el ReorderableListView
                    dropdownBuilder: (context, selectedItems) {
                      // **IMPORTANTE:** El selectedItems que recibimos aquí es una copia,
                      // pero el ReorderableListView manipulará _ordenesSeleccionadas directamente
                      // y forzará la reconstrucción del DropdownSearch.
                      
                      if (_ordenesSeleccionadas.isEmpty) {
                        return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '0 órdenes seleccionadas',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                      }
                      
                      return Container(
                          height: 60, // Altura fija para la fila de reordenamiento
                          alignment: Alignment.centerLeft,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            // **USAMOS EL ESTADO**
                            itemCount: _ordenesSeleccionadas.length, 
                            onReorder: _onReorderOrdenes,
                            itemBuilder: (context, index) {
                              // **USAMOS EL ESTADO**
                              final orden = _ordenesSeleccionadas[index];
                              return Tooltip(
                                // **CLAVE:** El ValueKey debe ser consistente e inmutable
                                key: ValueKey(orden.ordenTrabajoId), 
                                message: 'Arrastra para reordenar columna: ${orden.numeroOrdenTrabajo}',
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  color: Colors.blue[50],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Center(
                                      child: Text(
                                        'OT: ${orden.numeroOrdenTrabajo}',
                                        style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                    },
                    popupProps: PopupPropsMultiSelection.menu(
                      showSearchBox: true,
                      showSelectedItems: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Buscar órdenes...",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      itemBuilder: (context, item, isSelected) {
                        return ListTile(
                          title: Text('${item.numeroOrdenTrabajo}'),
                          subtitle: Text(
                            'Fecha: ${_formatearFecha(item.fechaOrdenTrabajo)}',
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.radio_button_unchecked),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaExcelDinamica() {
    if (_cargandoMateriales) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_tablaConsumo.filas.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar'));
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 1. Calculamos el ancho mínimo requerido para el scroll horizontal
          final int numOrdenes = _ordenesSeleccionadas.length;
          // Ancho estimado: Código(80) + Art(150) + Ant(60) + Ordenes(90 c/u) + Total(70) + Desc(150)
          final double anchoMinimoRequerido = 80 + 150 + 60 + (numOrdenes * 90) + 70 + 150 + 20; 
          
          // 2. Usamos el ancho de pantalla si es suficiente, sino usamos el mínimo requerido
          final double anchoAUsar = constraints.maxWidth > anchoMinimoRequerido 
              ? constraints.maxWidth 
              : anchoMinimoRequerido;
          
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // ConstrainedBox asegura que si hay espacio de sobra, la tabla se estire al 100%
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SizedBox(
                  width: anchoAUsar, // Forzamos el ancho calculado
                  child: DataTable(
                    columnSpacing: 8,
                    horizontalMargin: 8,
                    dataRowHeight: 50,
                    headingRowHeight: 60,
                    columns: _buildColumnasDinamicas(),
                    rows: _buildFilasDinamicas(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataColumn> _buildColumnasDinamicas() {
    // Definimos anchos fijos para asegurar el centrado y que calcen con las filas
    const double widthAnt = 60;
    const double widthOrden = 90; 
    const double widthTotal = 70; 

    return [
      const DataColumn(
        label: Center(
          child: Text(
            'Código', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      const DataColumn(
        label: Center(
          child: Text(
            'Artículo', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      // Columna única de ANTERIORES con ancho fijo (60)
      const DataColumn(
        label: SizedBox( 
          width: widthAnt,
          child: Center(
            child: Text(
              'ANT', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      // Columnas dinámicas por orden seleccionada con ancho fijo (90)
      // El orden de estas columnas sigue el orden de _ordenesSeleccionadas, que es reordenable.
      for (var orden in _ordenesSeleccionadas)
        DataColumn(
          label: SizedBox( 
            width: widthOrden,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    orden.numeroOrdenTrabajo ?? 'OT${orden.ordenTrabajoId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatearFecha(orden.fechaOrdenTrabajo),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      // Columna TOTAL con ancho fijo (70)
      const DataColumn(
        label: SizedBox( 
          width: widthTotal,
          child: Center(
            child: Text(
              'TOTAL', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      // Columna ARTÍCULO (Descripción S en la fila)
      const DataColumn(
        label: Center(
          child: Text(
            'DESCRIPCIÓN', // Cambiado para mayor claridad
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildFilasDinamicas() {
    final List<DataRow> filas = [];

    // 1. FILAS DE MATERIALES
    for (var fila in _tablaConsumo.filas) {
      // Re-calcular total de anteriores (suma de las 4 columnas "ant")
      double totalAnteriores = (fila.consumosAnteriores['ant_1'] ?? 0.0) +
                              (fila.consumosAnteriores['ant_2'] ?? 0.0) +
                              (fila.consumosAnteriores['ant_3'] ?? 0.0) +
                              (fila.consumosAnteriores['ant_4'] ?? 0.0);

      final celdas = <DataCell>[
        // Código
        DataCell(Align(alignment: Alignment.centerLeft, child: Text(fila.codigo, style: const TextStyle(fontSize: 16)))),
        // Artículo
        DataCell(Align(alignment: Alignment.centerLeft, child: Tooltip(message: fila.articulo, child: SizedBox(width: 150, child: Text(fila.articulo, style: const TextStyle(fontSize: 16), overflow: TextOverflow.visible))))),
        
        // --- CELDA ANT (width: 60) ---
        DataCell(
          SizedBox(
            width: 60, 
            child: Center(
              child: Text(totalAnteriores.toStringAsFixed(0), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ];

      double totalFila = totalAnteriores;

      // --- CELDAS ORDENES (width: 90) ---
      // Se itera sobre _ordenesSeleccionadas para mantener el orden reordenado.
      for (var orden in _ordenesSeleccionadas) {
        final ordenId = orden.ordenTrabajoId.toString();
        // Usamos el Map de la fila, que contiene todos los consumos, y accedemos por la ID de la OT
        final cantidad = fila.consumosPorOrden[ordenId] ?? 0.0;
        totalFila += cantidad;
        
        celdas.add(
          DataCell(
            SizedBox(
              width: 90, // MISMO ANCHO QUE EL HEADER
              child: Center(
                child: Text(cantidad.toStringAsFixed(0), style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        );
      }

      // --- CELDA TOTAL (width: 70) ---
      celdas.add(
        DataCell(
          SizedBox(
            width: 70, 
            child: Center(
              // Usamos el total calculado al iterar, aunque la fila ya tiene totalFila
              child: Text(totalFila.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ),
        ),
      );

      // Descripción final
      celdas.add(DataCell(Align(alignment: Alignment.centerLeft, child: Tooltip(message: fila.descripcionS, child: SizedBox(width: 150, child: Text(fila.descripcionS, style: const TextStyle(fontSize: 16), overflow: TextOverflow.visible))))));

      filas.add(DataRow(cells: celdas));
    }
    
    // 2. FILA DE TOTALES (Aplicar la misma lógica de anchos y orden)
    if (_tablaConsumo.filas.isNotEmpty) {
      // Re-calcular total de anteriores de la fila de totales
      double totalAntGeneral = (_tablaConsumo.totalesColumnas['ant_1'] ?? 0.0) + 
                              (_tablaConsumo.totalesColumnas['ant_2'] ?? 0.0) + 
                              (_tablaConsumo.totalesColumnas['ant_3'] ?? 0.0) + 
                              (_tablaConsumo.totalesColumnas['ant_4'] ?? 0.0);
                              
      final celdasTotales = <DataCell>[
        const DataCell(Align(alignment: Alignment.centerLeft, child: Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        const DataCell(SizedBox.shrink()),
        
        // Total ANTERIORES (width: 60)
        DataCell(
          SizedBox(
            width: 60, 
            child: Center(
              child: Text(
                totalAntGeneral.toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ];

      double totalGeneral = totalAntGeneral;

      // Totales por orden (width: 90)
      // Se itera sobre _ordenesSeleccionadas para mantener el orden reordenado.
      for (var orden in _ordenesSeleccionadas) {
        final ordenId = orden.ordenTrabajoId.toString();
        final totalColumna = _tablaConsumo.totalesColumnas[ordenId] ?? 0.0;
        totalGeneral += totalColumna;
        
        celdasTotales.add(
          DataCell(
            SizedBox(
              width: 90, 
              child: Center(
                child: Text(totalColumna.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );
      }

      // Total General (width: 70)
      celdasTotales.add(
        DataCell(
          SizedBox(
            width: 70, 
            child: Center(
              child: Text(totalGeneral.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        ),
      );

      celdasTotales.add(const DataCell(SizedBox.shrink()));

      filas.add(DataRow(cells: celdasTotales, color: MaterialStateProperty.resolveWith<Color?>((states) => Colors.grey[200])));
    }
    
    return filas;
  }

  Widget _buildTotalesYMermas() {
    double totalEmbarcar = _tablaConsumo.totalEmbarcar;
    double totalConsumido = _tablaConsumo.totalEnvasado; 
    double mermaProceso = _tablaConsumo.mermaProceso;
    double porcentajeMerma = _tablaConsumo.porcentajeMerma;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'RESUMEN DE PRODUCCIÓN - RESYMAS 1248',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsivo: en pantallas pequeñas, mostrar en columna
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildItemResumen('Total Embarcar', '$totalEmbarcar kg', Colors.blue[800]!),
                      const SizedBox(height: 8),
                      _buildItemResumen('Total Consumido', '${totalConsumido.toStringAsFixed(0)} kg', Colors.green),
                      const SizedBox(height: 8),
                      _buildItemResumen('Diferencia', '${mermaProceso.toStringAsFixed(0)} kg', 
                        mermaProceso > 0 ? Colors.orange : Colors.red),
                      const SizedBox(height: 8),
                      _buildItemResumen('% Merma', '${porcentajeMerma.toStringAsFixed(2)}%', 
                        porcentajeMerma > 5 ? Colors.red : Colors.green),
                    ],
                  );
                }
                
                // En pantallas más grandes, mostrar en fila
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildItemResumen('Total Embarcar', '$totalEmbarcar kg', Colors.blue[800]!),
                    _buildItemResumen('Total Consumido', '${totalConsumido.toStringAsFixed(0)} kg', Colors.green),
                    _buildItemResumen('Diferencia', '${mermaProceso.toStringAsFixed(0)} kg', 
                      mermaProceso > 0 ? Colors.orange : Colors.red),
                    _buildItemResumen('% Merma', '${porcentajeMerma.toStringAsFixed(2)}%', 
                      porcentajeMerma > 5 ? Colors.red : Colors.green),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            if (mermaProceso > 0)
              Text(
                'Nota: Se produjo una merma de ${mermaProceso.toStringAsFixed(0)} kg (${porcentajeMerma.toStringAsFixed(2)}%)',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemResumen(String titulo, String valor, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Text(
                valor,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}