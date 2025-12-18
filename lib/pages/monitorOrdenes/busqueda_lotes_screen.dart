// screens/busqueda_lotes_screen.dart
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/lote.dart';
import 'package:app_tec_sedel/models/orden.dart'; // Añadir import
import 'package:app_tec_sedel/services/lote_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart'; // Añadir import
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Añadir import

class BusquedaLotesScreen extends StatefulWidget {
  const BusquedaLotesScreen({super.key});

  @override
  State<BusquedaLotesScreen> createState() => _BusquedaLotesScreenState();
}

class _BusquedaLotesScreenState extends State<BusquedaLotesScreen> {
  final LoteServices _loteServices = LoteServices();
  final OrdenServices _ordenServices = OrdenServices(); // Añadir servicio de órdenes
  List<Lote> _lotes = [];
  List<Lote> _lotesFiltrados = [];
  bool _cargando = false;
  String _filtroEstado = 'TODOS';
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarLotes();
  }

  Future<void> _cargarLotes() async {
    setState(() => _cargando = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      
      _lotes = await _loteServices.getLotes(context, token);
      _aplicarFiltros();
    } catch (e) {
      print('Error cargando lotes: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _lotesFiltrados = _lotes.where((lote) {
        // Filtrar por estado
        if (_filtroEstado != 'TODOS') {
          if (_filtroEstado == 'ABIERTO' && !lote.estaAbierto) return false;
          if (_filtroEstado == 'CERRADO' && !lote.estaCerrado) return false;
        }
        
        // Filtrar por búsqueda
        if (_filtroBusqueda.isNotEmpty) {
          final busqueda = _filtroBusqueda.toLowerCase();
          final contieneLote = lote.lote?.toLowerCase().contains(busqueda) ?? false;
          final contieneObservaciones = lote.observaciones?.toLowerCase().contains(busqueda) ?? false;
          
          if (!contieneLote && !contieneObservaciones) return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _navegarAConsumos(Lote lote) {
    // Usando GoRouter para navegar y pasar el lote como extra
    context.push(
      '/planilla',
      extra: lote,
    );
  }

  void _mostrarDialogoCrearLote() {
    showDialog(
      context: context,
      builder: (context) => _DialogoCrearEditarLote(
        loteServices: _loteServices,
        ordenServices: _ordenServices, // Pasar el servicio de órdenes
        onLoteCreado: (nuevoLote) {
          // Navegar directamente a la planilla de consumos con el nuevo lote
          _navegarAConsumos(nuevoLote);
        },
      ),
    ).then((_) {
      // Recargar la lista si se creó un lote
      _cargarLotes();
    });
  }

  void _mostrarDialogoEditarLote(Lote lote) {
    showDialog(
      context: context,
      builder: (context) => _DialogoCrearEditarLote(
        loteServices: _loteServices,
        ordenServices: _ordenServices, // Pasar el servicio de órdenes
        loteExistente: lote,
        onLoteActualizado: (loteActualizado) {
          _cargarLotes();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUSQUEDA DE LOTES'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearLote,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),
          
          // Lista de lotes
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _lotesFiltrados.isEmpty
                    ? const Center(
                        child: Text('No se encontraron lotes'),
                      )
                    : ListView.builder(
                        itemCount: _lotesFiltrados.length,
                        itemBuilder: (context, index) {
                          final lote = _lotesFiltrados[index];
                          return _buildCardLote(lote);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      _filtroBusqueda = value;
                      _aplicarFiltros();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Buscar por lote u observaciones...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filtroEstado,
                  items: ['TODOS', 'ABIERTO', 'CERRADO']
                      .map((estado) => DropdownMenuItem(
                            value: estado,
                            child: Text(estado),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value!;
                      _aplicarFiltros();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _cargarLotes,
                  tooltip: 'Recargar',
                ),
                Text('${_lotesFiltrados.length} lotes encontrados'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLote(Lote lote) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _navegarAConsumos(lote),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lote: ${lote.lote ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: lote.estaAbierto ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lote.estado ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Fecha: ${lote.fechaLoteFormatted ?? "N/A"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.inventory, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Embarcar: ${lote.totalEmbarcar ?? 0} kg',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.description, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lote.observaciones ?? 'Sin observaciones',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.list_alt, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Órdenes: ${lote.ordenes?.length ?? 0}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _mostrarDialogoEditarLote(lote),
                    tooltip: 'Editar lote',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoCrearEditarLote extends StatefulWidget {
  final LoteServices loteServices;
  final OrdenServices ordenServices; // Añadir servicio de órdenes
  final Lote? loteExistente;
  final Function(Lote)? onLoteCreado;
  final Function(Lote)? onLoteActualizado;

  const _DialogoCrearEditarLote({
    required this.loteServices,
    required this.ordenServices, // Añadir parámetro requerido
    this.loteExistente,
    this.onLoteCreado,
    this.onLoteActualizado,
  });

  @override
  State<_DialogoCrearEditarLote> createState() => __DialogoCrearEditarLoteState();
}

class __DialogoCrearEditarLoteState extends State<_DialogoCrearEditarLote> {
  final _formKey = GlobalKey<FormState>();
  late Lote _lote;
  bool _cargando = false;
  bool _esEdicion = false;
  
  // Nuevas variables para manejar órdenes
  List<Orden> _ordenesDisponibles = [];
  List<Orden> _ordenesSeleccionadas = [];
  bool _cargandoOrdenes = false;

  final TextEditingController _loteController = TextEditingController();
  final TextEditingController _pedidoIdController = TextEditingController();
  final TextEditingController _totalEmbarcarController = TextEditingController();
  final TextEditingController _nvporcController = TextEditingController();
  final TextEditingController _viscController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  DateTime? _fechaLote;
  String _estado = 'ABIERTO';

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.loteExistente != null;
    
    if (_esEdicion) {
      _lote = widget.loteExistente!;
      _loteController.text = _lote.lote ?? '';
      _pedidoIdController.text = _lote.pedidoId?.toString() ?? '';
      _totalEmbarcarController.text = _lote.totalEmbarcar?.toString() ?? '';
      _nvporcController.text = _lote.nvporc ?? '';
      _viscController.text = _lote.visc ?? '';
      _observacionesController.text = _lote.observaciones ?? '';
      _fechaLote = _lote.fechaLote;
      _estado = _lote.estado ?? 'ABIERTO';
      
      // Inicializar órdenes seleccionadas desde el lote existente
      _inicializarOrdenesDesdeLote();
    } else {
      _lote = Lote.empty();
      _fechaLote = DateTime.now();
    }
    
    // Cargar órdenes disponibles
    _cargarOrdenes();
  }

  Future<void> _cargarOrdenes() async {
    setState(() => _cargandoOrdenes = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      String tecnicoId = authProvider.tecnicoId.toString();
      
      _ordenesDisponibles = await widget.ordenServices.getOrden(context, tecnicoId, token);
      
      // Si estamos en modo edición, ya tenemos las órdenes seleccionadas inicializadas
      // Si no, inicializar selección vacía
      if (!_esEdicion) {
        _ordenesSeleccionadas = [];
      }
    } catch (e) {
      print('Error cargando órdenes: $e');
    } finally {
      setState(() => _cargandoOrdenes = false);
    }
  }

  void _inicializarOrdenesDesdeLote() {
    // Convertir las OrdenTrabajo del lote a objetos Orden básicos para la selección
    if (_lote.ordenes != null && _lote.ordenes!.isNotEmpty) {
      _ordenesSeleccionadas = _lote.ordenes!.map((ordenTrabajo) {
        return Orden(
          ordenTrabajoId: ordenTrabajo.ordenTrabajoId,
          numeroOrdenTrabajo: ordenTrabajo.numeroOrdenTrabajo,
          descripcion: ordenTrabajo.descripcion,
          fechaOrdenTrabajo: DateTime.now(), // Fecha por defecto
        );
      }).toList();
    }
  }

  Future<void> _guardarLote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;

      // Construir el objeto lote
      final loteActualizado = _lote.copyWith(
        lote: _loteController.text.isNotEmpty ? _loteController.text : null,
        pedidoId: int.tryParse(_pedidoIdController.text),
        totalEmbarcar: int.tryParse(_totalEmbarcarController.text),
        nvporc: _nvporcController.text.isNotEmpty ? _nvporcController.text : null,
        visc: _viscController.text.isNotEmpty ? _viscController.text : null,
        fechaLote: _fechaLote,
        estado: _estado,
        observaciones: _observacionesController.text.isNotEmpty ? _observacionesController.text : null,
      );

      // Obtener IDs de las órdenes seleccionadas
      List<int> ordenesIds = _ordenesSeleccionadas
          .map((orden) => orden.ordenTrabajoId ?? 0)
          .where((id) => id > 0)
          .toList();

      Lote resultado;
      if (_esEdicion) {
        resultado = await widget.loteServices.updateLote(
          context, token, loteActualizado, ordenesIds,
        );
        widget.onLoteActualizado?.call(resultado);
      } else {
        resultado = await widget.loteServices.createLote(
          context, token, loteActualizado, ordenesIds,
        );
        widget.onLoteCreado?.call(resultado);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error guardando lote: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  // Función para formatear fecha (similar a la de ConsumosScreen)
  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    
    return '${fecha.day}-${meses[fecha.month - 1]}-${fecha.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar Lote' : 'Crear Nuevo Lote'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.5 : MediaQuery.of(context).size.width,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _loteController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Lote',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el número de lote';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalEmbarcarController,
                        decoration: const InputDecoration(
                          labelText: 'Total a Embarcar (kg)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese cantidad';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nvporcController,
                        decoration: const InputDecoration(
                          labelText: 'NV%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _viscController,
                        decoration: const InputDecoration(
                          labelText: 'Viscosidad',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final fechaSeleccionada = await showDatePicker(
                      context: context,
                      initialDate: _fechaLote ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (fechaSeleccionada != null) {
                      setState(() {
                        _fechaLote = fechaSeleccionada;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha del Lote',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fechaLote != null
                              ? '${_fechaLote!.day}/${_fechaLote!.month}/${_fechaLote!.year}'
                              : 'Seleccionar fecha',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                
                // NUEVA SECCIÓN: Selección de Órdenes
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Órdenes Asociadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _cargandoOrdenes
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownSearch<Orden>.multiSelection(
                        items: _ordenesDisponibles,
                        compareFn: (item1, item2) => item1.ordenTrabajoId == item2.ordenTrabajoId,
                        selectedItems: _ordenesSeleccionadas,
                        onChanged: (List<Orden> nuevasSeleccionadas) {
                          setState(() {
                            // Mantener el orden de selección
                            final Map<int?, Orden> nuevaMap = {
                              for (var o in nuevasSeleccionadas) o.ordenTrabajoId: o
                            };
                            final List<Orden> mantenidas = _ordenesSeleccionadas.where((o) => nuevaMap.containsKey(o.ordenTrabajoId)).toList();
                            final Set<int?> mantenidasIds = mantenidas.map((o) => o.ordenTrabajoId).toSet();
                            final List<Orden> nuevasAniadidas = nuevasSeleccionadas.where((o) => !mantenidasIds.contains(o.ordenTrabajoId)).toList();
                            _ordenesSeleccionadas = [...mantenidas, ...nuevasAniadidas];
                          });
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
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _ordenesSeleccionadas.length,
                              itemBuilder: (context, index) {
                                final orden = _ordenesSeleccionadas[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  color: Colors.blue[50],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'OT: ${orden.numeroOrdenTrabajo ?? orden.ordenTrabajoId}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800]
                                          ),
                                        ),
                                      ],
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
                              title: Text('OT: ${item.numeroOrdenTrabajo ?? item.ordenTrabajoId}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.descripcion != null && item.descripcion!.isNotEmpty)
                                    Text(
                                      item.descripcion!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    'Fecha: ${_formatearFecha(item.fechaOrdenTrabajo)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Seleccionar órdenes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
                Text(
                  '${_ordenesSeleccionadas.length} órdenes seleccionadas',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _guardarLote,
          child: _cargando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}