import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:app_tec_sedel/services/codigueras_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/widgets/dialogo_cliente.dart';
import 'package:app_tec_sedel/widgets/dialogo_unidad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/delegates/cliente_search_delegate.dart';
import 'package:provider/provider.dart';
import 'detlla_piezas_screen.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';

class MonitorOrdenes extends StatefulWidget {
  const MonitorOrdenes({super.key});

  @override
  State<MonitorOrdenes> createState() => _MonitorOrdenesState();
}

class _MonitorOrdenesState extends State<MonitorOrdenes> {
  // Variables compartidas
  String token = '';
  final ClientServices clientServices = ClientServices();
  final UnidadesServices unidadesServices = UnidadesServices();
  final CodiguerasServices codiguerasServices = CodiguerasServices();
  
  // Variables para ambos flavors
  List<Cliente> clientesLocales = [];
  List<Unidad> unidades = [];
  DateTime fecha = DateTime.now();
  bool condIva = true;
  Cliente? clienteSeleccionado;
  Unidad? unidadSeleccionada;
  final TextEditingController _numOrdenController = TextEditingController();
  final TextEditingController _comentClienteController = TextEditingController();
  final TextEditingController _comentTrabajoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  late Orden ordenExistente = Orden.empty();
  bool _isEditMode = false;
  Orden? _ordenExistente;

  // Variables específicas para resysol (producción química)
  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _productoController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _pedidoController = TextEditingController();
  final TextEditingController _envaseController = TextEditingController();
  final TextEditingController _totTambController = TextEditingController();
  final TextEditingController _batchesController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  late String flavor = "";

  @override
  void initState() {
    super.initState();
    token = context.read<AuthProvider>().token;
    flavor = context.read<AuthProvider>().flavor;
    
    // Inicializar controladores de Resysol con valores vacíos
    if (flavor == 'resysol') {
      _fechaEmisionController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
    // Cargar orden existente para ambos flavors
    _cargarOrdenExistente();
  }

  Future<void> _cargarOrdenExistente() async {
    final ordenProvider = context.read<OrdenProvider>();
    ordenExistente = ordenProvider.orden;

    // Verificar si hay una orden cargada desde la lista
    if (ordenExistente.ordenTrabajoId != null && ordenExistente.ordenTrabajoId != 0) {
      setState(() {
        _isEditMode = true;
        _ordenExistente = ordenExistente;
      });

      // Cargar datos según el flavor
      if (ordenExistente.cliente?.clienteId != null) {
        await _cargarClienteDesdeAPI(ordenExistente.cliente!.clienteId);
        
        // Para automotora, cargar unidades también
        if (flavor == 'automotoraargentina' && ordenExistente.unidad?.unidadId != null) {
          await _cargarUnidadesYSeleccionar(ordenExistente.cliente!.clienteId, ordenExistente.unidad!.unidadId);
        }
      }
      
      _cargarDatosComunesDesdeOrden();
      
      // Cargar datos específicos del flavor
      if (flavor == 'resysol') {
        _cargarDatosResysolDesdeOrden();
      }
    }
  }

  Future<void> _cargarClienteDesdeAPI(int clienteId) async {
    try {
      final clientes = await clientServices.getClientes(
        context, 
        ordenExistente.cliente?.nombre ?? '',
        '',
        '',
        '',
        token
      );

      if (clientes != null && clientes is List<Cliente>) {
        final clienteEncontrado = clientes.firstWhere(
          (cliente) => cliente.clienteId == clienteId,
          orElse: () => Cliente.empty(),
        );

        if (clienteEncontrado.clienteId != 0) {
          setState(() {
            clienteSeleccionado = clienteEncontrado;
          });
        }
      }
    } catch (e) {
      print('Error cargando cliente desde API: $e');
    }
  }

  Future<void> _cargarUnidadesYSeleccionar(int clienteId, int unidadId) async {
    try {
      List<Unidad> unidadesDelCliente = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteId, 
        token
      );

      Unidad? unidadDeOrden;
      try {
        unidadDeOrden = unidadesDelCliente.firstWhere(
          (unidad) => unidad.unidadId == unidadId
        );
      } catch (e) {
        if (ordenExistente.matricula != null) {
          try {
            unidadDeOrden = unidadesDelCliente.firstWhere(
              (unidad) => unidad.matricula == ordenExistente.matricula
            );
          } catch (e) {
            print('No se encontró la unidad por matrícula: ${ordenExistente.matricula}');
          }
        }
      }

      setState(() {
        unidades = unidadesDelCliente;
        unidadSeleccionada = unidadDeOrden;
      });
    } catch (e) {
      print('Error cargando unidades: $e');
    }
  }

  void _cargarDatosComunesDesdeOrden() {
    if (_ordenExistente == null) return;

    setState(() {
      // Datos comunes para ambos flavors
      _numOrdenController.text = _ordenExistente!.numeroOrdenTrabajo ?? '';
      _comentClienteController.text = _ordenExistente!.comentarioCliente ?? '';
      _comentTrabajoController.text = _ordenExistente!.comentarioTrabajo ?? '';
      _descripcionController.text = _ordenExistente!.descripcion ?? '';
      
      if (_ordenExistente!.fechaOrdenTrabajo != null) {
        fecha = _ordenExistente!.fechaOrdenTrabajo!;
      }
    });
  }

  void _cargarDatosResysolDesdeOrden() {
    if (_ordenExistente == null) return;

    setState(() {
      // Datos específicos de Resysol
      _numeroController.text = _ordenExistente!.numeroOrdenTrabajo ?? '';
      _productoController.text = _ordenExistente!.producto ?? _ordenExistente!.descripcion ?? '';
      _pedidoController.text = _ordenExistente!.pedido.toString();
      _envaseController.text = _ordenExistente!.envase.toString();
      _totTambController.text = _ordenExistente!.totalTambores?.toString() ?? '';
      _batchesController.text = _ordenExistente!.batches?.toString() ?? '';
      _observacionesController.text = _ordenExistente!.comentarioTrabajo ?? _ordenExistente!.comentarioCliente ?? '';
      
      // Si no hay fecha específica, usar la fecha de la orden
      if (_ordenExistente!.fechaOrdenTrabajo != null) {
        _fechaEmisionController.text = DateFormat('dd/MM/yyyy').format(_ordenExistente!.fechaOrdenTrabajo!);
      }
    });
  }

  void _abrirBusquedaCliente(BuildContext context) async {
    final Cliente? resultado = await showSearch<Cliente>(
      context: context,
      delegate: ClienteSearchDelegate(
        token: token,
        clientService: clientServices,
      ),
    );

    if (resultado != null && resultado.clienteId != 0) {
      // Para automotora, cargar unidades también
      if (flavor == 'automotoraargentina') {
        List<Unidad> unidadesDelCliente = await unidadesServices.getUnidadesDeCliente(
          context, 
          resultado.clienteId, 
          token
        );
        setState(() {
          clienteSeleccionado = resultado;
          unidades = unidadesDelCliente;
          unidadSeleccionada = null;
        });
      } else {
        setState(() {
          clienteSeleccionado = resultado;
        });
      }
    }
  }

  int getTipoOrden() {
    switch (flavor.toLowerCase()) {
      case 'automotoraargentina':
        return 5;
      case 'parabrisasejido':
        return 6;
      case 'resysol':
        return 7;
      default:
      return 7;
    }
  }

  Orden _crearOrdenEnMemoria() {
    final authProvider = context.read<AuthProvider>();
    
    // Para resysol, crear una unidad vacía si no hay seleccionada
    Unidad unidadResysol = unidadSeleccionada ?? Unidad.empty();
    
    return Orden(
      ordenTrabajoId: _isEditMode ? _ordenExistente!.ordenTrabajoId : 0,
      numeroOrdenTrabajo: flavor == 'resysol' ? _numeroController.text : _numOrdenController.text,
      descripcion: flavor == 'resysol' ? _productoController.text : _descripcionController.text,
      fechaOrdenTrabajo: fecha,
      fechaVencimiento: _isEditMode ? _ordenExistente!.fechaVencimiento : null,
      fechaEntrega: _isEditMode ? _ordenExistente!.fechaEntrega : null,
      fechaDesde: _isEditMode ? _ordenExistente!.fechaDesde : fecha,
      fechaHasta: _isEditMode ? _ordenExistente!.fechaHasta : fecha,
      ruc: clienteSeleccionado?.ruc ?? '',
      monedaId: 1,
      codMoneda: 'UYU',
      descMoneda: 'Peso Uruguayo',
      signo: '\$',
      totalOrdenTrabajo: _isEditMode ? _ordenExistente!.totalOrdenTrabajo : 0.0,
      comentarioCliente: flavor == 'resysol' ? _observacionesController.text : _comentClienteController.text,
      comentarios: _isEditMode ? _ordenExistente!.comentarios : '',
      comentarioTrabajo: flavor == 'resysol' ? _observacionesController.text : _comentTrabajoController.text,
      estado: _isEditMode ? _ordenExistente!.estado : 'PENDIENTE',
      presupuestoIdPlantilla: _isEditMode ? _ordenExistente!.presupuestoIdPlantilla : null,
      numeroPresupuesto: _isEditMode ? _ordenExistente!.numeroPresupuesto : null,
      descripcionPresupuesto: _isEditMode ? _ordenExistente!.descripcionPresupuesto : null,
      totalPresupuesto: _isEditMode ? _ordenExistente!.totalPresupuesto : null,
      plantilla: _isEditMode ? _ordenExistente!.plantilla : false,
      unidadId: unidadResysol.unidadId,
      matricula: unidadResysol.matricula,
      km: _isEditMode ? _ordenExistente!.km ?? unidadSeleccionada?.km : 0,
      regHs: _isEditMode ? _ordenExistente!.regHs ?? false : false,
      instrucciones: _isEditMode ? _ordenExistente!.instrucciones : '',
      tipoOrden: _isEditMode ? _ordenExistente!.tipoOrden : TipoOrden.empty(),
      cliente: clienteSeleccionado ?? Cliente.empty(),
      tecnico: _isEditMode ? _ordenExistente!.tecnico : Tecnico.empty(),
      unidad: unidadResysol,
      servicio: _isEditMode ? _ordenExistente!.servicio : [],
      otRevisionId: _isEditMode ? _ordenExistente!.otRevisionId : 0,
      planoId: _isEditMode ? _ordenExistente!.planoId : 0,
      alerta: _isEditMode ? _ordenExistente!.alerta : false,
      tecnicoId: authProvider.tecnicoId,
      clienteId: clienteSeleccionado?.clienteId ?? 0,
      tipoOrdenId: getTipoOrden(),
      // Campos específicos para resysol
      producto: _productoController.text,
      pedido: int.tryParse(_pedidoController.text),
      envase: int.tryParse(_envaseController.text),
      totalTambores: int.tryParse(_totTambController.text),
      batches: int.tryParse(_batchesController.text),
      totalkgs: 0.0, // Se calculará después
      mermaKgs: 0.0, // Se calculará después
      mermaPorcentual: 0.0, // Se calculará después
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Map<String, dynamic> _crearDatosProduccion() {
    return {
      'fechaEmision': _fechaEmisionController.text,
      'numero': _numeroController.text,
      'producto': _productoController.text,
      'referencia': _refController.text,
      'pedido': _pedidoController.text,
      'envase': _envaseController.text,
      'totalTambores': _totTambController.text,
      'batches': _batchesController.text,
      'observaciones': _observacionesController.text,
      'fecha': DateTime.now(),
      'cliente': clienteSeleccionado?.toMap(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final flavor = context.read<AuthProvider>().flavor;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          flavor == 'resysol' 
            ? 'Planilla de Producción Química'
            : (_isEditMode ? 'Editar Orden ${ordenExistente.numeroOrdenTrabajo}' : 'Registro de Orden'),
          style: TextStyle(color: colors.onPrimary),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: flavor == 'resysol' 
          ? _buildResysolUI(context)
          : _buildAutomotoraUI(context),
    );
  }

  Widget _buildResysolUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SELECTOR DE CLIENTE PARA RESYSOL
          _buildClienteCardResysol(),
          const SizedBox(height: 20),
          _buildChemicalHeaderCard(),
          const SizedBox(height: 20),
          _buildChemicalProductionCard(),
          const SizedBox(height: 20),
          _buildChemicalPackagingCard(),
          const SizedBox(height: 24),
          _buildChemicalActionButtons(),
        ],
      ),
    );
  }

  // WIDGET PARA SELECTOR DE CLIENTE EN RESYSOL
  Widget _buildClienteCardResysol() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onDoubleTap: clienteSeleccionado != null ? _editarClienteSeleccionado : null,
              child: TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Buscar cliente...',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                controller: TextEditingController(
                  text: clienteSeleccionado != null ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' : '',
                ),
                onTap: () {
                  _abrirBusquedaCliente(context);
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _mostrarDialogoNuevoCliente(context);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Nuevo Cliente'),
              ),
            ),
            if (clienteSeleccionado != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: clienteSeleccionado!.direccion),
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: clienteSeleccionado!.telefono1),
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: clienteSeleccionado!.email),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: 'RUC: ${clienteSeleccionado!.ruc}'),
                decoration: const InputDecoration(
                  labelText: 'Documento',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutomotoraUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(fecha),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: fecha,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != fecha) {
                      setState(() {
                        fecha = picked;
                      });
                    }
                  },
                ),
              ),
              if (ordenExistente.numeroOrdenTrabajo != null && ordenExistente.numeroOrdenTrabajo!.isNotEmpty && ordenExistente.numeroOrdenTrabajo != '') ... [
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _numOrdenController,
                    decoration: const InputDecoration(
                      labelText: 'N° Orden',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  )
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descripcionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Datos del Cliente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          GestureDetector(
            onDoubleTap: clienteSeleccionado != null ? _editarClienteSeleccionado : null,
            child: TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Buscar cliente...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              controller: TextEditingController(
                text: clienteSeleccionado != null ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' : '',
              ),
              onTap: () {
                _abrirBusquedaCliente(context);
              },
            ),
          ),
          
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _mostrarDialogoNuevoCliente(context);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Nuevo Cliente'),
            ),
          ),
          
          if (clienteSeleccionado != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: clienteSeleccionado!.direccion),
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: clienteSeleccionado!.telefono1),
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: clienteSeleccionado!.email),
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: 'RUC: ${clienteSeleccionado!.ruc}'),
              decoration: const InputDecoration(
                labelText: 'Documento',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          const Text(
            'Datos del Vehículo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: unidadSeleccionada != null ? _editarUnidadSeleccionada : null,
                  child: DropdownButtonFormField<Unidad>(
                    value: unidadSeleccionada,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Seleccione un vehículo',
                    ),
                    items: unidades.map((Unidad unidad) {
                      return DropdownMenuItem<Unidad>(
                        value: unidad,
                        child: Text(unidad.displayInfo),
                      );
                    }).toList(),
                    onChanged: (Unidad? nuevaUnidad) {
                      setState(() {
                        unidadSeleccionada = nuevaUnidad;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _mostrarDialogoNuevaUnidad(context);
                },
              ),
            ],
          ),
          
          if (unidadSeleccionada != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: unidadSeleccionada!.marca),
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: unidadSeleccionada!.modelo),
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: unidadSeleccionada!.matricula),
              decoration: const InputDecoration(
                labelText: 'Matrícula',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: unidadSeleccionada!.motor),
              decoration: const InputDecoration(
                labelText: 'Número de Motor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: unidadSeleccionada!.chasis),
              decoration: const InputDecoration(
                labelText: 'Número de Chasis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: unidadSeleccionada!.anio.toString()),
              decoration: const InputDecoration(
                labelText: 'Año',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _comentClienteController,
                decoration: const InputDecoration(
                  labelText: 'Comentario Cliente',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 5
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comentTrabajoController,
                decoration: const InputDecoration(
                  labelText: 'Comentario Trabajo',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 5
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isEditMode) ... [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Descartar orden'),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton(
                  onPressed: () async {
                    if (clienteSeleccionado == null || unidadSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                      );
                      return;
                    }
                    
                    final ordenCreada = _crearOrdenEnMemoria();
                    
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      final ordenServices = OrdenServices();
                      final ordenGuardada = _isEditMode 
                          ? await ordenServices.actualizarOrden(context, token, ordenCreada)
                          : await ordenServices.postOrden(context, token, ordenCreada);
                      
                      Navigator.of(context).pop();
                      
                      if (ordenGuardada != null) {
                        context.read<OrdenProvider>().setOrden(Orden.empty());
                        
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetallePiezasScreen(
                              cliente: clienteSeleccionado!,
                              vehiculo: unidadSeleccionada!,
                              fecha: fecha,
                              condIva: condIva,
                              ordenPrevia: ordenGuardada,
                            ),
                          ),
                        );

                        if (result != null && result is Orden) {
                          setState(() {
                            ordenExistente = result;
                            _isEditMode = true;
                            _ordenExistente = result;
                          });
                          
                          await _cargarClienteDesdeAPI(result.cliente?.clienteId ?? 0);
                          await _cargarUnidadesYSeleccionar(result.cliente?.clienteId ?? 0, result.unidad?.unidadId ?? 0);
                          _cargarDatosComunesDesdeOrden();
                        }
                      }
                    } catch (e) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(_isEditMode ? 'Actualizar Orden' : 'Siguiente'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'DATOS DE PRODUCCIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Primera fila - Fecha y Número
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Fecha Emisión',
                  controller: _fechaEmisionController,
                  width: 200,
                  readOnly: true,
                  onTap: () => _selectDate(context, _fechaEmisionController),
                  icon: Icons.calendar_today,
                ),
                _buildLabeledTextField(
                  label: 'Número',
                  controller: _numeroController,
                  width: 150,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Segunda fila - Producto y Referencia
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Producto',
                  controller: _productoController,
                  width: 280,
                ),
                _buildLabeledTextField(
                  label: 'Referencia',
                  controller: _refController,
                  width: 120,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Tercera fila - Pedido y Envase
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Pedido (kg)',
                  controller: _pedidoController,
                  width: 180,
                  keyboardType: TextInputType.number,
                  suffixText: 'kg',
                ),
                _buildLabeledTextField(
                  label: 'Envase (kg)',
                  controller: _envaseController,
                  width: 180,
                  keyboardType: TextInputType.number,
                  suffixText: 'kg',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalProductionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'PRODUCCIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Batches',
                  controller: _batchesController,
                  width: 150,
                  keyboardType: TextInputType.number,
                ),
                _buildLabeledTextField(
                  label: 'Total Tambores',
                  controller: _totTambController,
                  width: 180,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observaciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _observacionesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'Ingrese observaciones de producción...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalPackagingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'ENVASADO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Información de envasado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen de Envasado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem('Total Tambores', _totTambController.text.isEmpty ? '0' : _totTambController.text),
                      _buildInfoItem('Capacidad Envase', '${_envaseController.text.isEmpty ? '0' : _envaseController.text} kg'),
                      _buildInfoItem('Total Producción', '${_pedidoController.text.isEmpty ? '0' : _pedidoController.text} kg'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MÉTODO PARA RESYSOL
  Widget _buildChemicalActionButtons() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ElevatedButton(
          onPressed: _crearOrdenResysol,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditMode ? 'CONTINUAR A DETALLE' : 'CREAR ORDEN Y CONTINUAR A DETALLE',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para campos de texto con etiqueta
  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required double width,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              filled: true,
              fillColor: readOnly ? Colors.grey[50] : Colors.white,
              suffixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
              suffixText: suffixText,
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para mostrar información en el resumen
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: const OutlineInputBorder(),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) async {
    final clienteGuardado = await showDialog<Cliente>(
      context: context,
      builder: (BuildContext context) {
        return DialogoCliente(
          clientServices: clientServices,
          token: token,
        );
      },
    );

    if (clienteGuardado != null && mounted) {
      setState(() {
        clienteSeleccionado = clienteGuardado;
        clientesLocales.add(clienteGuardado);
        unidades = [];
        unidadSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${clienteGuardado.nombre} creado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      print('Cliente guardado es null o diálogo cerrado sin guardar');
    }
  }

  void _mostrarDialogoNuevaUnidad(BuildContext context) async {
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe seleccionar un cliente')),
      );
      return;
    }

    final Unidad? unidadGuardada = await showDialog<Unidad>(
      context: context,
      builder: (BuildContext context) {
        return DialogoUnidad(
          token: token,
          clienteId: clienteSeleccionado!.clienteId,
          unidadesServices: unidadesServices,
          codiguerasServices: codiguerasServices,
          permitirBusquedaMatricula: true,
        );
      },
    );

    if (unidadGuardada != null) {
      List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteSeleccionado!.clienteId, 
        token
      );

      setState(() {
        unidades = unidadesActualizadas;
        try {
          unidadSeleccionada = unidades.firstWhere(
            (u) => u.matricula == unidadGuardada.matricula
          );
        } catch (e) {
          unidadSeleccionada = unidades.isNotEmpty ? unidades.first : null;
        }
      });
    }
  }

  void _editarClienteSeleccionado() async {
    if (clienteSeleccionado == null) return;

    final clienteEditado = await showDialog<Cliente>(
      context: context,
      builder: (BuildContext context) {
        return DialogoCliente(
          clientServices: clientServices,
          token: token,
          esEdicion: true,
          clienteEditar: clienteSeleccionado,
        );
      },
    );

    if (clienteEditado != null && mounted) {
      setState(() {
        clienteSeleccionado = clienteEditado;
      });

      await _cargarUnidadesYSeleccionar(clienteEditado.clienteId, unidadSeleccionada?.unidadId ?? 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${clienteEditado.nombre} actualizado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editarUnidadSeleccionada() async {
    if (unidadSeleccionada == null || clienteSeleccionado == null) return;

    final Unidad? unidadEditada = await showDialog<Unidad>(
      context: context,
      builder: (BuildContext context) {
        return DialogoUnidad(
          token: token,
          clienteId: clienteSeleccionado!.clienteId,
          unidadesServices: unidadesServices,
          codiguerasServices: codiguerasServices,
          permitirBusquedaMatricula: false,
          unidadExistente: unidadSeleccionada,
        );
      },
    );

    if (unidadEditada != null && mounted) {
      List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteSeleccionado!.clienteId, 
        token
      );

      setState(() {
        unidades = unidadesActualizadas;
        try {
          unidadSeleccionada = unidades.firstWhere(
            (u) => u.unidadId == unidadEditada.unidadId
          );
        } catch (e) {
          unidadSeleccionada = unidades.isNotEmpty ? unidades.first : null;
        }
      });
    }
  }

  // MÉTODO PARA CREAR O ACTUALIZAR ORDEN RESYSOL
  Future<void> _crearOrdenResysol() async {
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    final ordenCreada = _crearOrdenEnMemoria();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final ordenServices = OrdenServices();
      final ordenGuardada = _isEditMode 
          ? await ordenServices.actualizarOrden(context, token, ordenCreada)
          : await ordenServices.postOrden(context, token, ordenCreada);
      
      Navigator.of(context).pop();
      
      if (ordenGuardada != null) {
        // Navegar a DetallePiezasScreen con la orden creada/actualizada
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetallePiezasScreen(
              // Parámetros para resysol
              datosProduccion: _crearDatosProduccion(),
              // También pasamos la orden creada/actualizada
              ordenPrevia: ordenGuardada,
            ),
          ),
        );

        // Si estamos editando, actualizar el estado local
        if (_isEditMode && mounted) {
          setState(() {
            ordenExistente = ordenGuardada;
            _ordenExistente = ordenGuardada;
          });
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al ${_isEditMode ? 'actualizar' : 'crear'} la orden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}