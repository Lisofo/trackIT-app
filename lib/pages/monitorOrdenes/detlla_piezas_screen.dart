import 'package:app_tec_sedel/models/cliente_chapa_pintura.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Agregar esta clase al final del archivo, antes del cierre de la última llave
class DetallePiezasScreen extends StatefulWidget {
  final ClienteCP cliente;
  final Vehiculo vehiculo;
  final DateTime fecha;
  final bool condIva;

  const DetallePiezasScreen({
    super.key,
    required this.cliente,
    required this.vehiculo,
    required this.fecha,
    required this.condIva,
  });

  @override
  State<DetallePiezasScreen> createState() => _DetallePiezasScreenState();
}

class _DetallePiezasScreenState extends State<DetallePiezasScreen> {
  // Lista para almacenar los detalles de las piezas
  List<Map<String, dynamic>> piezas = [];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Detalle de Piezas', style: TextStyle(color: colors.onPrimary)),
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de información del cliente y vehículo
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cliente: ${widget.cliente.nombreCompleto}', 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Vehículo: ${widget.vehiculo.displayInfo}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Fecha: ${DateFormat('dd/MM/yyyy').format(widget.fecha)}'),
                        const SizedBox(width: 16),
                        Text('Cond. IVA: ${widget.condIva ? 'Sí' : 'No'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tabla de detalles de piezas
            const Text(
              'Detalle de Piezas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DataTable(
                    dividerThickness: 1.0,
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 60,
                    headingRowHeight: 50,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                    columns: const [
                      DataColumn(label: Text('Acción', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Pieza', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Chapa (H)', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Chapa (M)', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Pintura', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Mec. (H)', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Mec. (M)', textAlign: TextAlign.center)),
                      DataColumn(label: Text('Repto. s/iva', textAlign: TextAlign.center)),
                    ],
                    rows: piezas.isEmpty
                        ? [
                            const DataRow(cells: [
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                            ])
                          ]
                        : piezas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final pieza = entry.value;
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  return index.isEven ? Colors.grey.shade50 : null;
                                },
                              ),
                              cells: [
                                DataCell(Center(child: Text(pieza['accion']?.toString() ?? '-'))),
                                DataCell(Text(pieza['pieza']?.toString() ?? '-')),
                                DataCell(Center(child: Text(pieza['chapaH']?.toStringAsFixed(1) ?? '0.0'))),
                                DataCell(Center(child: Text(pieza['chapaM']?.toStringAsFixed(2) ?? '0.00'))),
                                DataCell(Center(child: Text(pieza['pintura']?.toStringAsFixed(2) ?? '0.00'))),
                                DataCell(Center(child: Text(pieza['mecH']?.toStringAsFixed(1) ?? '0.0'))),
                                DataCell(Center(child: Text(pieza['mecM']?.toStringAsFixed(2) ?? '0.00'))),
                                DataCell(Center(child: Text(pieza['repto']?.toStringAsFixed(2) ?? '0.00'))),
                              ],
                            );
                          }).toList(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para agregar nueva pieza
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _mostrarDialogoNuevaPieza(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar Pieza'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Totales presupuestados
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Totales presupuestados',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTotalItem('Chapa:', '\$0.00'),
                        _buildTotalItem('Pintura:', '\$0.00'),
                        _buildTotalItem('Mecánica:', '\$0.00'),
                        _buildTotalItem('Repuestos:', '\$0.00'),
                        _buildTotalItem('TOTAL:', '\$0.00', isTotal: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Costos reales
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Costos reales',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTotalItem('Chapa:', '\$0.00'),
                        _buildTotalItem('Pintura:', '\$0.00'),
                        _buildTotalItem('Mecánica:', '\$0.00'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
        )),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.green : Colors.black,
        )),
      ],
    );
  }

  void _mostrarDialogoNuevaPieza(BuildContext context) {
    // Lista de acciones predefinidas
    final List<String> acciones = [
      'Reparar',
      'Resetear',
      'Revisar',
      'Rotar',
      'S/Acción',
      'Sac y Colocar',
      'Sac/Col/Reparar',
      'Sacabollos'
    ];
    
    // Lista de piezas de auto predefinidas
    final List<String> piezasAuto = [
      'Capot',
      'Paragolpes delantero',
      'Paragolpes trasero',
      'Puerta delantera derecha',
      'Puerta delantera izquierda',
      'Puerta trasera derecha',
      'Puerta trasera izquierda',
      'Tapa de baúl',
      'Guardabarro delantero derecho',
      'Guardabarro delantero izquierdo',
      'Guardabarro trasero derecho',
      'Guardabarro trasero izquierdo',
      'Techo',
      'Espejo retrovisor derecho',
      'Espejo retrovisor izquierdo',
      'Farol delantero derecho',
      'Farol delantero izquierdo',
      'Farol trasero derecho',
      'Farol trasero izquierdo',
      'Ventanilla derecha',
      'Ventanilla izquierda',
      'Luna delantera',
      'Luna trasera'
    ];
    
    String? accionSeleccionada;
    String? piezaSeleccionada;
    final chapaHorasController = TextEditingController();
    final chapaMontoController = TextEditingController();
    final pinturaController = TextEditingController();
    final mechHorasController = TextEditingController();
    final mechMontoController = TextEditingController();
    final reptoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Pieza', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para Acción
                DropdownButtonFormField<String>(
                  value: accionSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Acción',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: acciones.map((String accion) {
                    return DropdownMenuItem<String>(
                      value: accion,
                      child: Text(accion),
                    );
                  }).toList(),
                  onChanged: (String? nuevaAccion) {
                    accionSeleccionada = nuevaAccion;
                  },
                ),
                const SizedBox(height: 12),
                
                // Dropdown para Pieza
                DropdownButtonFormField<String>(
                  value: piezaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Pieza',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: piezasAuto.map((String pieza) {
                    return DropdownMenuItem<String>(
                      value: pieza,
                      child: Text(pieza),
                    );
                  }).toList(),
                  onChanged: (String? nuevaPieza) {
                    piezaSeleccionada = nuevaPieza;
                  },
                ),
                const SizedBox(height: 12),
                
                // Campos en fila para Chapa (Horas y Monto)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: chapaHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Chapa (H)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: chapaMontoController,
                        decoration: const InputDecoration(
                          labelText: 'Chapa (M)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Campo para Pintura
                TextFormField(
                  controller: pinturaController,
                  decoration: const InputDecoration(
                    labelText: 'Pintura',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                
                // Campos en fila para Mecánica (Horas y Monto)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: mechHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Mec. (H)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: mechMontoController,
                        decoration: const InputDecoration(
                          labelText: 'Mec. (M)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Campo para Precio Rep. s/iva
                TextFormField(
                  controller: reptoController,
                  decoration: const InputDecoration(
                    labelText: 'Rep. s/iva',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (accionSeleccionada == null || piezaSeleccionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debe seleccionar una acción y una pieza')),
                  );
                  return;
                }
                
                final nuevaPieza = {
                  'accion': accionSeleccionada,
                  'pieza': piezaSeleccionada,
                  'chapaH': double.tryParse(chapaHorasController.text),
                  'chapaM': double.tryParse(chapaMontoController.text),
                  'pintura': double.tryParse(pinturaController.text),
                  'mecH': double.tryParse(mechHorasController.text),
                  'mecM': double.tryParse(mechMontoController.text),
                  'repto': double.tryParse(reptoController.text),
                };
                
                setState(() {
                  piezas.add(nuevaPieza);
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pieza agregada correctamente')),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}