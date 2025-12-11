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
  
  // Controladores para los campos editables
  Map<String, Map<String, TextEditingController>> controllers = {};

  // Variables para almacenar las líneas originales y actuales
  Map<String, Linea> lineasOriginalesMap = {}; // key: "${ordenId}_${codItem}"
  List<Linea> lineasActuales = [];
  bool _hayCambiosSinGuardar = false;

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
  }

  @override
  void dispose() {
    // Limpiar todos los controladores
    controllers.forEach((codigo, map) {
      map.forEach((key, controller) {
        controller.dispose();
      });
    });
    super.dispose();
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
        lineasOriginalesMap.clear();
        lineasActuales.clear();
        _hayCambiosSinGuardar = false;
      });
      return;
    }
    
    setState(() => _cargandoMateriales = true);

    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      List<Linea> todasLineas = [];

      // Limpiar datos anteriores
      lineasOriginalesMap.clear();
      lineasActuales.clear();
      _hayCambiosSinGuardar = false;

      for (var orden in _ordenesSeleccionadas) {
        final lineas = await _lineasServices.getLineasDeOrden(
          context, 
          orden.ordenTrabajoId!, 
          token
        );
        todasLineas.addAll(lineas);
        
        // Guardar copia de las líneas originales
        for (var linea in lineas) {
          final key = "${linea.ordenTrabajoId}_${linea.codItem}";
          lineasOriginalesMap[key] = linea.copyWith();
          lineasActuales.add(linea.copyWith());
        }
      }

      // Procesar datos con columnas dinámicas
      _tablaConsumo = _excelService.procesarDatosReales(todasLineas, _ordenesSeleccionadas);
      
      // Inicializar controllers después de cargar datos
      _inicializarControllers();
      
    } catch (e) {
      print('Error cargando materiales: $e');
    } finally {
      setState(() => _cargandoMateriales = false);
    }
  }

  void _inicializarControllers() {
    controllers.clear();
    
    for (var fila in _tablaConsumo.filas) {
      controllers[fila.codigo] = {};
      
      // Controllers para consumos anteriores (4 columnas)
      for (var i = 1; i <= 4; i++) {
        final key = 'ant_$i';
        controllers[fila.codigo]![key] = TextEditingController(
          text: fila.consumosAnteriores[key]?.toStringAsFixed(0) ?? '0'
        );
      }
      
      // Controllers para consumos por orden
      for (var orden in _ordenesSeleccionadas) {
        final ordenId = orden.ordenTrabajoId.toString();
        controllers[fila.codigo]![ordenId] = TextEditingController(
          text: fila.consumosPorOrden[ordenId]?.toStringAsFixed(0) ?? '0'
        );
      }
    }
  }

  void _actualizarValorDesdeController(String codigoMaterial, String columna) {
    final controller = controllers[codigoMaterial]?[columna];
    if (controller != null) {
      final nuevoValor = double.tryParse(controller.text) ?? 0.0;
      final valorAnterior = _tablaConsumo.obtenerValor(codigoMaterial, columna) ?? 0.0;
      
      // Solo actualizar si hay cambio
      if (nuevoValor != valorAnterior) {
        _tablaConsumo.actualizarValor(codigoMaterial, columna, nuevoValor);
        
        // Actualizar la línea correspondiente en _lineasActuales
        if (!columna.startsWith('ant_')) {
          final ordenId = int.parse(columna);
          _actualizarLineaControl(codigoMaterial, ordenId, nuevoValor);
        }
        
        setState(() {
          _hayCambiosSinGuardar = true;
        });
      }
    }
  }

  void _actualizarLineaControl(String codigoMaterial, int ordenTrabajoId, double nuevoControl) {
    // Buscar la línea correspondiente
    for (int i = 0; i < lineasActuales.length; i++) {
      final linea = lineasActuales[i];
      if (linea.codItem == codigoMaterial && linea.ordenTrabajoId == ordenTrabajoId) {
        lineasActuales[i] = linea.copyWith(control: nuevoControl);
        break;
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_hayCambiosSinGuardar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
      return;
    }

    setState(() => _cargando = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      int actualizacionesExitosas = 0;
      int errores = 0;

      for (var lineaActual in lineasActuales) {
        final key = "${lineaActual.ordenTrabajoId}_${lineaActual.codItem}";
        final lineaOriginal = lineasOriginalesMap[key];
        
        // Solo actualizar si el control ha cambiado
        if (lineaOriginal != null && lineaActual.control != lineaOriginal.control) {
          try {
            final resultado = await _lineasServices.actualizarLinea(
              context, 
              lineaActual.ordenTrabajoId, 
              lineaActual, 
              token
            );
            
            if (_lineasServices.statusCode == 1) {
              actualizacionesExitosas++;
              // Actualizar la copia original con el nuevo valor
              lineasOriginalesMap[key] = resultado.copyWith();
            } else {
              errores++;
            }
          } catch (e) {
            print('Error actualizando línea ${lineaActual.lineaId}: $e');
            errores++;
          }
        }
      }

      setState(() {
        _hayCambiosSinGuardar = false;
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errores > 0 
              ? 'Guardado parcial: $actualizacionesExitosas actualizaciones, $errores errores'
              : 'Se guardaron $actualizacionesExitosas líneas correctamente',
          ),
          backgroundColor: errores > 0 ? Colors.orange : Colors.green,
        ),
      );

    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      controllers.clear();
      lineasOriginalesMap.clear();
      lineasActuales.clear();
      _hayCambiosSinGuardar = false;
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
        title: Row(
          children: [
            const Text('CONSUMOS DE PRODUCCIÓN - RESYMAS 1248'),
            if (_hayCambiosSinGuardar)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Cambios sin guardar',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Botón de guardar
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.save),
                if (_hayCambiosSinGuardar)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _cargando ? null : _guardarCambios,
            tooltip: 'Guardar cambios',
          ),
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
      body: Stack(
        children: [
          Column(
            children: [
              // Encabezado fijo
              _buildHeaderExcel(),
              // Tabla expandible sin scroll vertical
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Selector de órdenes
                      _buildSelectorOrdenes(),
                      // Tabla que se expande verticalmente
                      _buildTablaExcelDinamicaExpandida(),
                      
                      // Totales y mermas (fijo al fondo)
                      _buildTotalesYMermas(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_cargando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
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
                    selectedItems: _ordenesSeleccionadas, 
                    onChanged: (List<Orden> nuevasSeleccionadas) {
                      setState(() {
                        final Map<int?, Orden> nuevaMap = {for (var o in nuevasSeleccionadas) o.ordenTrabajoId: o};
                        final List<Orden> mantenidas = _ordenesSeleccionadas.where((o) => nuevaMap.containsKey(o.ordenTrabajoId)).toList();
                        final Set<int?> mantenidasIds = mantenidas.map((o) => o.ordenTrabajoId).toSet();
                        final List<Orden> nuevasAniadidas = nuevasSeleccionadas.where((o) => !mantenidasIds.contains(o.ordenTrabajoId)).toList();
                        _ordenesSeleccionadas = [...mantenidas, ...nuevasAniadidas];
                      });
                      _cargarMateriales();
                    },
                    dropdownBuilder: (context, selectedItems) {
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
                          height: 60,
                          alignment: Alignment.centerLeft,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _ordenesSeleccionadas.length, 
                            onReorder: _onReorderOrdenes,
                            itemBuilder: (context, index) {
                              final orden = _ordenesSeleccionadas[index];
                              return Tooltip(
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

  Widget _buildTablaExcelDinamicaExpandida() {
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
          // Calcular el ancho mínimo requerido
          final int numOrdenes = _ordenesSeleccionadas.length;
          final double anchoMinimoRequerido = 80 + 150 + (4 * 60) + (numOrdenes * 90) + 70 + 70 + 150 + 20;
          
          // Calcular la altura necesaria para todas las filas
          final int totalFilas = _tablaConsumo.filas.length + 1; // +1 para la fila de totales
          final double alturaTotal = totalFilas * 50 + 60; // 50 por fila de datos, 60 para el encabezado
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: alturaTotal,
              ),
              child: SizedBox(
                width: anchoMinimoRequerido > constraints.maxWidth 
                    ? anchoMinimoRequerido 
                    : constraints.maxWidth,
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
          );
        },
      ),
    );
  }

  List<DataColumn> _buildColumnasDinamicas() {
    const double widthAnt = 60;
    const double widthOrden = 90; 
    const double widthTotal = 70;
    const double widthConsumo = 70;

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
      // 4 columnas de ANT
      for (int i = 1; i <= 4; i++)
        DataColumn(
          label: SizedBox(
            width: widthAnt,
            child: Center(
              child: Text(
                'ANT$i', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      // Columnas dinámicas por orden
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
      // Columna TOTAL
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
      // NUEVA COLUMNA: CONSUMO
      const DataColumn(
        label: SizedBox(
          width: widthConsumo,
          child: Center(
            child: Text(
              'CONSUMO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      // Columna DESCRIPCIÓN
      const DataColumn(
        label: Center(
          child: Text(
            'DESCRIPCIÓN',
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
      final celdas = <DataCell>[
        DataCell(Align(alignment: Alignment.centerLeft, child: Text(fila.codigo, style: const TextStyle(fontSize: 16)))),
        DataCell(Align(alignment: Alignment.centerLeft, child: Tooltip(message: fila.articulo, child: SizedBox(width: 150, child: Text(fila.articulo, style: const TextStyle(fontSize: 16), overflow: TextOverflow.visible))))),
        
        // 4 celdas para ANT (ahora campos de texto editables)
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 60,
              child: Center(
                child: TextField(
                  controller: controllers[fila.codigo]?['ant_$i'],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onChanged: (value) {
                    _actualizarValorDesdeController(fila.codigo, 'ant_$i');
                  },
                ),
              ),
            ),
          ),

        // Celdas para órdenes (editables)
        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 90,
              child: Center(
                child: TextField(
                  controller: controllers[fila.codigo]?[orden.ordenTrabajoId.toString()],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onChanged: (value) {
                    _actualizarValorDesdeController(fila.codigo, orden.ordenTrabajoId.toString());
                  },
                ),
              ),
            ),
          ),

        // Celda TOTAL
        DataCell(
          SizedBox(
            width: 70, 
            child: Center(
              child: Text(fila.totalFila.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ),
        ),

        // NUEVA CELDA: CONSUMO (calculado automáticamente)
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                fila.consumoCalculado.toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
        ),

        // Celda DESCRIPCIÓN
        DataCell(Align(alignment: Alignment.centerLeft, child: Tooltip(message: fila.descripcionS, child: SizedBox(width: 150, child: Text(fila.descripcionS, style: const TextStyle(fontSize: 16), overflow: TextOverflow.visible))))),
      ];

      filas.add(DataRow(cells: celdas));
    }
    
    // 2. FILA DE TOTALES
    if (_tablaConsumo.filas.isNotEmpty) {
      // ignore: unused_local_variable
      double totalAntGeneral = 0.0;
      for (int i = 1; i <= 4; i++) {
        totalAntGeneral += (_tablaConsumo.totalesColumnas['ant_$i'] ?? 0.0);
      }
      
      final celdasTotales = <DataCell>[
        const DataCell(Align(alignment: Alignment.centerLeft, child: Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        const DataCell(SizedBox.shrink()),
        
        // 4 totales de ANT
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  (_tablaConsumo.totalesColumnas['ant_$i'] ?? 0.0).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        // Totales por orden
        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 90,
              child: Center(
                child: Text(
                  (_tablaConsumo.totalesColumnas[orden.ordenTrabajoId.toString()] ?? 0.0).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        // Total general
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                (_tablaConsumo.totalesColumnas['total'] ?? 0.0).toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
        ),

        // Total CONSUMO
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                _tablaConsumo.totalConsumoGeneral.toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
        ),

        const DataCell(SizedBox.shrink()),
      ];

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