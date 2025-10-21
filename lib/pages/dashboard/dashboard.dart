import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final OrdenServices _ordenServices = OrdenServices();
  DateTime _selectedDate = DateTime.now();
  List<Orden> _ordenes = [];
  bool _isLoading = true;

  // Estadísticas con los nuevos estados
  int _totalOrders = 0;
  int _pendientes = 0;
  int _recibidos = 0;
  int _aprobados = 0;
  int _facturados = 0;
  int _finalizados = 0;
  int _descartados = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final token = context.read<OrdenProvider>().token;

    // Ajustar las fechas para el día seleccionado (desde las 00:00 hasta las 23:59)
    DateTime startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    DateTime endDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    // Formatear las fechas a String en formato ISO8601

    final result = await _ordenServices.getOrden(
      context,
      context.read<OrdenProvider>().tecnicoId.toString(), // tecnicoId - puedes ajustar esto según tu necesidad
      token,
      queryParams: {
        'fechaDesde': DateFormat('yyyy-MM-dd').format(startDate),
        'fechaHasta': DateFormat('yyyy-MM-dd').format(endDate),
      },
    );

    if (result != null && _ordenServices.statusCode == 1) {
      setState(() {
        _ordenes = result;
        _calculateStats();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    _totalOrders = _ordenes.length;
    _pendientes = _ordenes.where((orden) => orden.estado == 'PENDIENTE').length;
    _recibidos = _ordenes.where((orden) => orden.estado == 'RECIBIDO').length;
    _aprobados = _ordenes.where((orden) => orden.estado == 'APROBADO').length;
    _facturados = _ordenes.where((orden) => orden.estado == 'FACTURADO').length;
    _finalizados = _ordenes.where((orden) => orden.estado == 'FINALIZADO').length;
    _descartados = _ordenes.where((orden) => orden.estado == 'DESCARTADO').length;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ), 
            dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  List<Map<String, dynamic>> getChartData() {
    return [
      {'status': 'Pendientes', 'value': _pendientes, 'color': Colors.orange},
      {'status': 'Recibidos', 'value': _recibidos, 'color': Colors.blue},
      {'status': 'Aprobados', 'value': _aprobados, 'color': Colors.green},
      {'status': 'Facturados', 'value': _facturados, 'color': Colors.purple},
      {'status': 'Finalizados', 'value': _finalizados, 'color': Colors.teal},
      {'status': 'Descartados', 'value': _descartados, 'color': Colors.red},
    ];
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isLargeScreen ? 180 : 160,
        height: isLargeScreen ? 140 : 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String status, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  late bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    
    isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        iconTheme: IconThemeData(color: colors.onPrimary),
        title: Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onPrimary,
          ),
        ),
        backgroundColor: colors.primary,
        actions: [
          IconButton(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con selector de fecha
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withOpacity(0.05),
                            colors.primary.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen del Día',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDate),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('Cambiar fecha'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Wrap de estadísticas principales
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatCard('Total', _totalOrders, colors.primary, Icons.list_alt),
                        _buildStatCard('Pendientes', _pendientes, Colors.orange, Icons.schedule),
                        _buildStatCard('Recibidos', _recibidos, Colors.blue, Icons.play_arrow),
                        _buildStatCard('Aprobados', _aprobados, Colors.green, Icons.check_circle),
                        _buildStatCard('Facturados', _facturados, Colors.purple, Icons.inventory_2),
                        _buildStatCard('Finalizados', _finalizados, Colors.teal, Icons.done_all),
                        _buildStatCard('Descartados', _descartados, Colors.red, Icons.cancel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLargeScreen) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Detalles de estado
                        Expanded(
                          flex: 1,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bar_chart, color: colors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Detalles de Estado',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  Column(
                                    children: [
                                      _buildStatusRow('Pendientes', _pendientes, Colors.orange),
                                      _buildStatusRow('Recibidos', _recibidos, Colors.blue),
                                      _buildStatusRow('Aprobados', _aprobados, Colors.green),
                                      _buildStatusRow('Facturados', _facturados, Colors.purple),
                                      _buildStatusRow('Finalizados', _finalizados, Colors.teal),
                                      _buildStatusRow('Descartados', _descartados, Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gráfico
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pie_chart, color: colors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Distribución de Órdenes',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 180,
                                    child: Chart(
                                      data: getChartData(),
                                      variables: {
                                        'status': Variable(
                                          accessor: (Map map) => map['status'] as String,
                                        ),
                                        'value': Variable(
                                          accessor: (Map map) => map['value'] as num,
                                        ),
                                      },
                                      marks: [
                                        IntervalMark(
                                          color: ColorEncode(
                                            variable: 'status',
                                            values: getChartData().map((e) => e['color'] as Color).toList(),
                                          ),
                                        )
                                      ],
                                      axes: [
                                        Defaults.horizontalAxis,
                                        Defaults.verticalAxis,
                                      ],
                                      coord: RectCoord(
                                        transposed: screenWidth < 400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Diseño para pantallas pequeñas
                    // Detalles de estado
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bar_chart, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Detalles de Estado',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                _buildStatusRow('Pendientes', _pendientes, Colors.orange),
                                _buildStatusRow('Recibidos', _recibidos, Colors.blue),
                                _buildStatusRow('Aprobados', _aprobados, Colors.green),
                                _buildStatusRow('Facturados', _facturados, Colors.purple),
                                _buildStatusRow('Finalizados', _finalizados, Colors.teal),
                                _buildStatusRow('Descartados', _descartados, Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gráfico
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pie_chart, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Distribución de Órdenes',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: isLandscape ? 250 : 300,
                              child: Chart(
                                data: getChartData(),
                                variables: {
                                  'status': Variable(
                                    accessor: (Map map) => map['status'] as String,
                                  ),
                                  'value': Variable(
                                    accessor: (Map map) => map['value'] as num,
                                  ),
                                },
                                marks: [
                                  IntervalMark(
                                    color: ColorEncode(
                                      variable: 'status',
                                      values: getChartData().map((e) => e['color'] as Color).toList(),
                                    ),
                                  )
                                ],
                                axes: [
                                  Defaults.horizontalAxis,
                                  Defaults.verticalAxis,
                                ],
                                coord: RectCoord(
                                  transposed: screenWidth < 400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}