import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetallePiezasScreen extends StatefulWidget {
  final Cliente cliente;
  final Unidad vehiculo;
  final DateTime fecha;
  final bool condIva;
  final Orden ordenPrevia;

  const DetallePiezasScreen({
    super.key,
    required this.cliente,
    required this.vehiculo,
    required this.fecha,
    required this.condIva,
    required this.ordenPrevia,
  });

  @override
  State<DetallePiezasScreen> createState() => _DetallePiezasScreenState();
}

class _DetallePiezasScreenState extends State<DetallePiezasScreen> {
  List<Linea> lineas = []; // Cambiado de Map<String, dynamic> a Linea
  List<Tarea> tareas = [];
  List<Materiales> materiales = [];
  bool isLoadingTareas = false;
  bool isLoadingMateriales = false;
  int ordinalCounter = 1; // Contador para el ordinal de las líneas

  // Métodos para calcular totales - ahora basados en Linea
  double get _totalChapa {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.chapaMonto ?? 0).toDouble();
    }
    return total;
  }

  double get _totalPintura {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.pinturaMonto ?? 0).toDouble();
    }
    return total;
  }

  double get _totalMecanica {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.mecanicaMonto ?? 0).toDouble();
    }
    return total;
  }

  double get _totalRepuestos {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.repSinIva ?? 0).toDouble();
    }
    return total;
  }

  double get _totalGeneral {
    return _totalChapa + _totalPintura + _totalMecanica + _totalRepuestos;
  }

  // Métodos para calcular costos reales
  double get _costoRealChapa {
    return _totalChapa * 1.0;
  }

  double get _costoRealPintura {
    return _totalPintura * 1.0;
  }

  double get _costoRealMecanica {
    return _totalMecanica * 1.0;
  }

  @override
  void initState() {
    super.initState();
    _cargarTareasYMateriales();
  }

  Future<void> _cargarTareasYMateriales() async {
    final token = context.read<OrdenProvider>().token;
    
    setState(() {
      isLoadingTareas = true;
      isLoadingMateriales = true;
    });

    try {
      final tareasService = TareasServices();
      final materialesService = MaterialesServices();
      
      final tareasList = await tareasService.getTareas(context, token);
      final materialesList = await materialesService.getMateriales(context, token);
      
      setState(() {
        tareas = tareasList;
        materiales = materialesList;
        isLoadingTareas = false;
        isLoadingMateriales = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTareas = false;
        isLoadingMateriales = false;
      });
    }
  }

  void _actualizarOrdenConLineas() {
    // Actualizar la descripción con información de las líneas
    if (lineas.isNotEmpty) {
      final descripcionLineas = lineas.map((linea) => 
        linea.descripcion
      ).join(', ');
      
      widget.ordenPrevia.descripcion = 'Reparación: $descripcionLineas';
    }
    
    // Actualizar el total con la suma de todos los montos
    widget.ordenPrevia.totalOrdenTrabajo = _totalGeneral;
    
    // Agregar comentarios sobre los trabajos
    final comentariosTrabajo = '''
Chapa: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_totalChapa)}
Pintura: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_totalPintura)}
Mecánica: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_totalMecanica)}
Repuestos: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_totalRepuestos)}
Total: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_totalGeneral)}
''';
    
    widget.ordenPrevia.comentarioTrabajo = comentariosTrabajo;
  }

  Future<void> _crearOrden() async {
    try {
      // Actualizar la orden con los datos de las líneas
      _actualizarOrdenConLineas();
      
      final ordenServices = OrdenServices();
      final token = context.read<OrdenProvider>().token;
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Llamar al servicio para crear la orden
      final ordenCreada = await ordenServices.postOrden(
        context, 
        token, 
        widget.ordenPrevia
      );
      
      // Cerrar el diálogo de carga
      Navigator.of(context).pop();
      
      if (ordenCreada != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Orden #${ordenCreada.numeroOrdenTrabajo} creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar al inicio
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
    } catch (e) {
      // Cerrar el diálogo de carga en caso de error
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la orden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
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
                    Text('Cliente: ${widget.cliente.nombre}', 
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
            
            // Tabla de detalles de líneas
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
                      DataColumn(label: Text('Eliminar', textAlign: TextAlign.center)),
                    ],
                    rows: lineas.isEmpty
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
                              DataCell(Center(child: Text('-'))),
                            ])
                          ]
                        : lineas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final linea = entry.value;
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  return index.isEven ? Colors.grey.shade50 : null;
                                },
                              ),
                              cells: [
                                DataCell(Center(child: Text(linea.descripcion))), // Acción
                                DataCell(Text(linea.comentario)), // Pieza
                                DataCell(Center(child: Text(linea.chapaHs?.toStringAsFixed(1) ?? '0.0'))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.chapaMonto ?? 0)))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.pinturaMonto ?? 0)))),
                                DataCell(Center(child: Text(linea.mecanicaHs?.toStringAsFixed(1) ?? '0.0'))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.mecanicaMonto ?? 0)))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.repSinIva ?? 0)))),
                                DataCell(
                                  Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _eliminarLinea(index);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para agregar nueva línea
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _mostrarDialogoNuevaLinea(context);
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
                        _buildTotalItem('Chapa:', formatCurrency.format(_totalChapa)),
                        _buildTotalItem('Pintura:', formatCurrency.format(_totalPintura)),
                        _buildTotalItem('Mecánica:', formatCurrency.format(_totalMecanica)),
                        _buildTotalItem('Repuestos:', formatCurrency.format(_totalRepuestos)),
                        _buildTotalItem('TOTAL:', formatCurrency.format(_totalGeneral), isTotal: true),
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
                        _buildTotalItem('Chapa:', formatCurrency.format(_costoRealChapa)),
                        _buildTotalItem('Pintura:', formatCurrency.format(_costoRealPintura)),
                        _buildTotalItem('Mecánica:', formatCurrency.format(_costoRealMecanica)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón para crear la orden
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Finalizar Orden',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _crearOrden,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Crear Orden'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
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

  void _eliminarLinea(int index) {
    setState(() {
      lineas.removeAt(index);
      // Recalcular ordinales si es necesario
      for (int i = 0; i < lineas.length; i++) {
        lineas[i].ordinal = i + 1;
      }
      ordinalCounter = lineas.length + 1;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Línea eliminada correctamente')),
    );
  }

  void _mostrarDialogoNuevaLinea(BuildContext context) {
    int? accionIdSeleccionado;
    int? piezaIdSeleccionado;
    String? accionDescripcionSeleccionada;
    String? piezaDescripcionSeleccionada;
    
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
                // Dropdown para Acción (Tareas)
                if (isLoadingTareas)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: accionDescripcionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Acción',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: tareas.map((Tarea tarea) {
                      return DropdownMenuItem<String>(
                        value: tarea.descripcion,
                        child: Text(tarea.descripcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevaAccion) {
                      final tareaSeleccionada = tareas.firstWhere(
                        (t) => t.descripcion == nuevaAccion,
                        orElse: () => Tarea.empty()
                      );
                      if (tareaSeleccionada.tareaId != 0) {
                        accionIdSeleccionado = tareaSeleccionada.tareaId;
                        accionDescripcionSeleccionada = tareaSeleccionada.descripcion;
                      }
                    },
                  ),
                const SizedBox(height: 12),
                
                // Dropdown para Pieza (Materiales)
                if (isLoadingMateriales)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: piezaDescripcionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Pieza',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: materiales.map((Materiales material) {
                      return DropdownMenuItem<String>(
                        value: material.descripcion,
                        child: Text(material.descripcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevaPieza) {
                      final materialSeleccionado = materiales.firstWhere(
                        (m) => m.descripcion == nuevaPieza,
                        orElse: () => Materiales.empty()
                      );
                      if (materialSeleccionado.materialId != 0) {
                        piezaIdSeleccionado = materialSeleccionado.materialId;
                        piezaDescripcionSeleccionada = materialSeleccionado.descripcion;
                      }
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
                if (accionIdSeleccionado == null || piezaIdSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debe seleccionar una acción y una pieza')),
                  );
                  return;
                }
                
                final nuevaLinea = Linea(
                  lineaId: 0,
                  ordenTrabajoId: 0,
                  itemId: 0,
                  codItem: '',
                  descripcion: accionDescripcionSeleccionada ?? '',
                  macroFamilia: '',
                  familia: '',
                  grupoInventario: '',
                  ordinal: ordinalCounter++,
                  cantidad: 1.0,
                  costoUnitario: 0.0,
                  descuento1: 0,
                  descuento2: 0,
                  descuento3: 0,
                  precioVenta: 0.0,
                  comentario: piezaDescripcionSeleccionada ?? '',
                  ivaId: 0,
                  iva: '',
                  valor: 0,
                  codGruInv: '',
                  gruInvId: 0,
                  avance: 0,
                  mo: '',
                )
                ..accionId = accionIdSeleccionado
                ..piezaId = piezaIdSeleccionado
                ..chapaHs = double.tryParse(chapaHorasController.text) ?? 0.0
                ..chapaMonto = double.tryParse(chapaMontoController.text) ?? 0.0
                ..pinturaMonto = double.tryParse(pinturaController.text) ?? 0.0
                ..mecanicaHs = double.tryParse(mechHorasController.text) ?? 0.0
                ..mecanicaMonto = double.tryParse(mechMontoController.text) ?? 0.0
                ..repSinIva = double.tryParse(reptoController.text) ?? 0.0;
                
                setState(() {
                  lineas.add(nuevaLinea);
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Línea agregada correctamente')),
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