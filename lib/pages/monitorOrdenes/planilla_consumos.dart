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
    if (_ordenesSeleccionadas.isEmpty) return;
    
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
    
    return '${fecha.day}-${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planilla de Consumos - RESYMAS 1248'),
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
          Text(
            'CONSUMOS DE PRODUCCIÓN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
          ),
          const SizedBox(height: 4),
          const Text(
            'Producto: RESYMAS 1248',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            'Total a embarcar: ${_tablaConsumo.totalEmbarcar} kg',
            style: const TextStyle(fontSize: 12),
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
              'Seleccionar Órdenes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : DropdownSearch<Orden>.multiSelection(
                    items: _ordenes,
                    compareFn: (item1, item2) => item1.ordenTrabajoId == item2.ordenTrabajoId,
                    onChanged: (List<Orden> nuevasSeleccionadas) {
                      setState(() {
                        _ordenesSeleccionadas = nuevasSeleccionadas;
                      });
                      _cargarMateriales();
                    },
                    dropdownBuilder: (context, selectedItems) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '${selectedItems.length} órdenes seleccionadas',
                          style: const TextStyle(fontSize: 16),
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
                          title: Text('${item.numeroOrdenTrabajo} - ${item.producto ?? "Sin producto"}'),
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
    return Card(
      margin: const EdgeInsets.all(8),
      child: _cargandoMateriales
          ? const Center(child: CircularProgressIndicator())
          : _tablaConsumo.filas.isEmpty
              ? const Center(child: Text('No hay datos para mostrar'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 4,
                      dataRowHeight: 35,
                      headingRowHeight: 60,
                      columns: _buildColumnasDinamicas(),
                      rows: _buildFilasDinamicas(),
                    ),
                  ),
                ),
    );
  }

  List<DataColumn> _buildColumnasDinamicas() {
    final List<DataColumn> columnas = [
      const DataColumn(label: Text('Código'), numeric: false),
      const DataColumn(label: Text('Artículo'), numeric: false),
      const DataColumn(label: Text('AT'), numeric: false),
      // Columnas fijas de consumos anteriores (4 columnas)
      const DataColumn(label: Text('ANTERIORES'), numeric: true),
      const DataColumn(label: Text('ANTERIORES'), numeric: true),
      const DataColumn(label: Text('ANTERIORES'), numeric: true),
      const DataColumn(label: Text('ANTERIORES'), numeric: true),
    ];

    // Columnas dinámicas por orden seleccionada
    for (var orden in _ordenesSeleccionadas) {
      columnas.add(DataColumn(
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              orden.numeroOrdenTrabajo ?? 'OT${orden.ordenTrabajoId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              _formatearFecha(orden.fechaOrdenTrabajo),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        numeric: true,
      ));
    }

    // Columnas fijas al final
    columnas.addAll([
      const DataColumn(label: Text('TOTAL'), numeric: true),
      const DataColumn(label: Text('DESCRIPCIÓN'), numeric: false),
      const DataColumn(label: Text('LOTE'), numeric: false),
    ]);

    return columnas;
  }

  List<DataRow> _buildFilasDinamicas() {
    final List<DataRow> filas = [];
    
    // Filas de materiales
    for (var fila in _tablaConsumo.filas) {
      final celdas = <DataCell>[
        DataCell(Text(fila.codigo)),
        DataCell(
          Tooltip(
            message: fila.articulo,
            child: SizedBox(
              width: 150,
              child: Text(
                fila.articulo,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        DataCell(Text(fila.at)),
        // Consumos anteriores (4 columnas fijas)
        DataCell(Text(fila.consumosAnteriores['ant_1']?.toStringAsFixed(0) ?? '0')),
        DataCell(Text(fila.consumosAnteriores['ant_2']?.toStringAsFixed(0) ?? '0')),
        DataCell(Text(fila.consumosAnteriores['ant_3']?.toStringAsFixed(0) ?? '0')),
        DataCell(Text(fila.consumosAnteriores['ant_4']?.toStringAsFixed(0) ?? '0')),
      ];

      // Columnas dinámicas por orden
      for (var orden in _ordenesSeleccionadas) {
        final ordenId = orden.ordenTrabajoId.toString();
        final cantidad = fila.consumosPorOrden[ordenId] ?? 0.0;
        celdas.add(DataCell(Text(cantidad.toStringAsFixed(0))));
      }

      // Columnas fijas al final
      celdas.addAll([
        DataCell(
          Text(
            fila.totalFila.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(fila.descripcionS)),
        DataCell(Text(fila.descripcionT)),
      ]);

      filas.add(DataRow(cells: celdas));
    }
    
    // Fila de totales
    final celdasTotales = <DataCell>[
      const DataCell(Text('')),
      const DataCell(
        Text(
          'TOTAL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataCell(Text('')),
      // Totales consumos anteriores
      DataCell(Text(_tablaConsumo.totalesColumnas['ant_1']?.toStringAsFixed(0) ?? '0')),
      DataCell(Text(_tablaConsumo.totalesColumnas['ant_2']?.toStringAsFixed(0) ?? '0')),
      DataCell(Text(_tablaConsumo.totalesColumnas['ant_3']?.toStringAsFixed(0) ?? '0')),
      DataCell(Text(_tablaConsumo.totalesColumnas['ant_4']?.toStringAsFixed(0) ?? '0')),
    ];

    // Totales por orden (columnas dinámicas)
    for (var orden in _ordenesSeleccionadas) {
      final ordenId = orden.ordenTrabajoId.toString();
      final total = _tablaConsumo.totalesColumnas[ordenId] ?? 0.0;
      celdasTotales.add(
        DataCell(
          Text(
            total.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Totales finales
    celdasTotales.addAll([
      DataCell(
        Text(
          _tablaConsumo.totalesColumnas['total']?.toStringAsFixed(0) ?? '0',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
      const DataCell(Text('')),
      const DataCell(Text('')),
    ]);

    filas.add(DataRow(
      cells: celdasTotales,
      color: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) => Colors.grey[100],
      ),
    ));
    
    return filas;
  }

  Widget _buildTotalesYMermas() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'RESUMEN DE PRODUCCIÓN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItemTotal('Total Embarcar', '${_tablaConsumo.totalEmbarcar} kg', Colors.blue),
                _buildItemTotal('Total Envasado', '${_tablaConsumo.totalEnvasado.toStringAsFixed(0)} kg', Colors.green),
                _buildItemTotal('Merma Proceso', '${_tablaConsumo.mermaProceso.toStringAsFixed(0)} kg', Colors.orange),
                _buildItemTotal('% Merma', '${_tablaConsumo.porcentajeMerma.toStringAsFixed(2)}%', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTotal(String titulo, String valor, Color color) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}