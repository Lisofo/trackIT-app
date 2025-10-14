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

class MonitorOrdenes extends StatefulWidget {

  const MonitorOrdenes({
    super.key,
  });

  @override
  State<MonitorOrdenes> createState() => _MonitorOrdenesState();
}

class _MonitorOrdenesState extends State<MonitorOrdenes> {
  List<Cliente> clientesLocales = [];
  List<Unidad> unidades = [];
  
  DateTime fecha = DateTime.now();
  bool condIva = true;
  Cliente? clienteSeleccionado;
  Unidad? unidadSeleccionada;
  final ClientServices clientServices = ClientServices();
  final UnidadesServices unidadesServices = UnidadesServices();
  final CodiguerasServices codiguerasServices = CodiguerasServices();
  String token = '';
  final TextEditingController _numOrdenController = TextEditingController();
  final TextEditingController _comentClienteController = TextEditingController();
  final TextEditingController _comentTrabajoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  late Orden ordenExistente = Orden.empty();

  // Variables para controlar si estamos editando una orden existente
  bool _isEditMode = false;
  Orden? _ordenExistente;

  @override
  void initState() {
    super.initState();
    token = context.read<OrdenProvider>().token;
    _cargarOrdenExistente();
  }

  Future<void> _cargarOrdenExistente() async {
    final ordenProvider = context.read<OrdenProvider>();
    ordenExistente = ordenProvider.orden;

    if (ordenExistente.ordenTrabajoId != 0) {
      setState(() {
        _isEditMode = true;
        _ordenExistente = ordenExistente;
      });

      // Cargar datos del cliente desde la API
      await _cargarClienteDesdeAPI(ordenExistente.cliente.clienteId);
      
      // Cargar unidades del cliente y seleccionar la correcta
      await _cargarUnidadesYSeleccionar(ordenExistente.cliente.clienteId, ordenExistente.unidad.unidadId);
      
      // Cargar el resto de los datos de la orden
      _cargarDatosOrdenExistente();
    }
  }

  Future<void> _cargarClienteDesdeAPI(int clienteId) async {
    try {
      // Obtener el cliente completo desde la API
      final clientes = await clientServices.getClientes(
        context, 
        ordenExistente.cliente.nombre, // nombre
        '', // codCliente
        '', // estado
        '', // tecnicoId
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
      // Obtener unidades del cliente desde la API
      List<Unidad> unidadesDelCliente = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteId, 
        token
      );

      // Buscar la unidad específica de la orden
      Unidad? unidadDeOrden;
      try {
        unidadDeOrden = unidadesDelCliente.firstWhere(
          (unidad) => unidad.unidadId == unidadId
        );
      } catch (e) {
        // Si no encuentra por ID, intentar por matrícula como fallback
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

  void _cargarDatosOrdenExistente() {
    if (_ordenExistente == null) return;

    setState(() {
      _numOrdenController.text = _ordenExistente!.numeroOrdenTrabajo;
      _comentClienteController.text = _ordenExistente!.comentarioCliente;
      _comentTrabajoController.text = _ordenExistente!.comentarioTrabajo;
      _descripcionController.text = _ordenExistente!.descripcion;
      
      if (_ordenExistente!.fechaOrdenTrabajo != null) {
        fecha = _ordenExistente!.fechaOrdenTrabajo!;
      }
      
      // Nota: condIva no está disponible en el modelo Orden, se mantiene el valor por defecto
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
      // Obtener las unidades del cliente desde la API
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
    }
  }

  Orden _crearOrdenEnMemoria() {
    final ordenProvider = context.read<OrdenProvider>();
    
    return Orden(
      ordenTrabajoId: _isEditMode ? _ordenExistente!.ordenTrabajoId : 0,
      numeroOrdenTrabajo: _numOrdenController.text,
      descripcion: _descripcionController.text,
      fechaOrdenTrabajo: fecha,
      fechaVencimiento: _isEditMode ? _ordenExistente!.fechaVencimiento : null,
      fechaEntrega: _isEditMode ? _ordenExistente!.fechaEntrega : null,
      fechaDesde: _isEditMode ? _ordenExistente!.fechaDesde : fecha,
      fechaHasta: _isEditMode ? _ordenExistente!.fechaHasta : fecha,
      ruc: clienteSeleccionado!.ruc,
      monedaId: 1,
      codMoneda: 'UYU',
      descMoneda: 'Peso Uruguayo',
      signo: '\$',
      totalOrdenTrabajo: _isEditMode ? _ordenExistente!.totalOrdenTrabajo : 0.0,
      comentarioCliente: _comentClienteController.text,
      comentarios: _isEditMode ? _ordenExistente!.comentarios : '',
      comentarioTrabajo: _comentTrabajoController.text,
      estado: _isEditMode ? _ordenExistente!.estado : 'PENDIENTE',
      presupuestoIdPlantilla: _isEditMode ? _ordenExistente!.presupuestoIdPlantilla : null,
      numeroPresupuesto: _isEditMode ? _ordenExistente!.numeroPresupuesto : null,
      descripcionPresupuesto: _isEditMode ? _ordenExistente!.descripcionPresupuesto : null,
      totalPresupuesto: _isEditMode ? _ordenExistente!.totalPresupuesto : null,
      plantilla: _isEditMode ? _ordenExistente!.plantilla : false,
      unidadId: unidadSeleccionada!.unidadId,
      matricula: unidadSeleccionada!.matricula,
      km: _isEditMode ? _ordenExistente!.km ?? unidadSeleccionada?.km : 0,
      regHs: _isEditMode ? _ordenExistente!.regHs ?? false : false,
      instrucciones: _isEditMode ? _ordenExistente!.instrucciones : '',
      tipoOrden: _isEditMode ? _ordenExistente!.tipoOrden : TipoOrden.empty(),
      cliente: clienteSeleccionado!,
      tecnico: _isEditMode ? _ordenExistente!.tecnico : Tecnico.empty(),
      unidad: unidadSeleccionada!,
      servicio: _isEditMode ? _ordenExistente!.servicio : [],
      otRevisionId: _isEditMode ? _ordenExistente!.otRevisionId : 0,
      planoId: _isEditMode ? _ordenExistente!.planoId : 0,
      alerta: _isEditMode ? _ordenExistente!.alerta : false,
      tecnicoId: ordenProvider.tecnicoId,
      clienteId: clienteSeleccionado!.clienteId,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          _isEditMode ? 'Editar Orden ${ordenExistente.numeroOrdenTrabajo}' : 'Registro de Orden', 
          style: TextStyle(color: colors.onPrimary),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila con fecha y condición IVA
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
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _numOrdenController,
                    decoration: const InputDecoration(
                      labelText: 'N° Orden',
                      border: OutlineInputBorder(),
                    ),
                  )
                ),
                // const SizedBox(width: 16),
                // const Text('Cond. IVA:'),
                // const SizedBox(width: 8),
                // Row(
                //   children: [
                //     Radio<bool>(
                //       value: true,
                //       groupValue: condIva,
                //       onChanged: (bool? value) {
                //         setState(() {
                //           condIva = value ?? true;
                //         });
                //       },
                //     ),
                //     const Text('Sí'),
                //     Radio<bool>(
                //       value: false,
                //       groupValue: condIva,
                //       onChanged: (bool? value) {
                //         setState(() {
                //           condIva = value ?? false;
                //         });
                //       },
                //     ),
                //     const Text('No'),
                //   ],
                // ),
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
            
            // Datos del cliente - SearchDelegate
            const Text(
              'Datos del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Campo de búsqueda de cliente
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
            
            // Botón para agregar nuevo cliente
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
            
            // Campos de visualización del cliente
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
            
            // Datos del vehículo
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
            
            // Campos de visualización del vehículo
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
              child: ElevatedButton(
                onPressed: () async {
                  if (clienteSeleccionado == null || unidadSeleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                    );
                    return;
                  }
                  
                  // Crear la orden en memoria
                  final ordenCreada = _crearOrdenEnMemoria();
                  
                  // Mostrar indicador de carga
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
                    
                    // Cerrar el diálogo de carga
                    Navigator.of(context).pop();
                    
                    if (ordenGuardada != null) {
                      // Limpiar la orden del provider después de guardar
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

                      // Si recibimos una orden de vuelta, actualizar el estado
                      if (result != null && result is Orden) {
                        setState(() {
                          ordenExistente = result;
                          _isEditMode = true;
                          _ordenExistente = result;
                        });
                        
                        // Recargar los datos de la orden
                        await _cargarClienteDesdeAPI(result.cliente.clienteId);
                        await _cargarUnidadesYSeleccionar(result.cliente.clienteId, result.unidad.unidadId);
                        _cargarDatosOrdenExistente();
                      }
                    }
                  } catch (e) {
                    // Cerrar el diálogo de carga en caso de error
                    Navigator.of(context).pop();
                  }
                },
                child: Text(_isEditMode ? 'Actualizar Orden' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) async {
    final clienteGuardado = await showDialog<Cliente>(
      context: context,
      builder: (BuildContext context) {
        return DialogoCliente(
          clientServices: clientServices,
          token: token,
          // Asegúrate de que el diálogo pueda cerrarse correctamente
        );
      },
    );

    if (clienteGuardado != null && mounted) {
      // Actualizar el estado con el nuevo cliente
      setState(() {
        clienteSeleccionado = clienteGuardado;
        clientesLocales.add(clienteGuardado);
        unidades = []; // Limpiar unidades ya que es un cliente nuevo
        unidadSeleccionada = null;
      });

      // Opcional: Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${clienteGuardado.nombre} creado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Debug: Verificar por qué clienteGuardado es null
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
          permitirBusquedaMatricula: true, // Habilitar búsqueda por matrícula
        );
      },
    );

    if (unidadGuardada != null) {
      // Actualizar la lista de unidades desde la API
      List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteSeleccionado!.clienteId, 
        token
      );

      setState(() {
        unidades = unidadesActualizadas;
        // Seleccionar la unidad recién creada
        try {
          unidadSeleccionada = unidades.firstWhere(
            (u) => u.matricula == unidadGuardada.matricula
          );
        } catch (e) {
          // Si no encuentra la unidad, seleccionar la primera si existe
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

      // Recargar unidades del cliente editado
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
      // Actualizar la lista de unidades desde la API
      List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteSeleccionado!.clienteId, 
        token
      );

      setState(() {
        unidades = unidadesActualizadas;
        // Seleccionar la unidad editada
        try {
          unidadSeleccionada = unidades.firstWhere(
            (u) => u.unidadId == unidadEditada.unidadId
          );
        } catch (e) {
          // Si no encuentra la unidad, seleccionar la primera si existe
          unidadSeleccionada = unidades.isNotEmpty ? unidades.first : null;
        }
      });
    }
  }
}