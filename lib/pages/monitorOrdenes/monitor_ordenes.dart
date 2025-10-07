import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
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
  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<OrdenProvider>().token;
  }

  bool _telefonoExiste(String telefono) {
    return clientesLocales.any((c) => c.telefono1 == telefono);
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
      ordenTrabajoId: 0,
      numeroOrdenTrabajo: 0, // Se asignará desde el servidor
      descripcion: 'Orden de trabajo para ${clienteSeleccionado!.nombre}',
      fechaOrdenTrabajo: fecha,
      fechaVencimiento: fecha.add(const Duration(days: 30)),
      fechaEntrega: null,
      fechaDesde: fecha,
      fechaHasta: fecha.add(const Duration(days: 7)),
      ruc: clienteSeleccionado!.ruc,
      monedaId: 1,
      codMoneda: 'PYG',
      descMoneda: 'Guaraní',
      signo: '₲',
      totalOrdenTrabajo: 0.0, // Se calculará en la siguiente pantalla
      comentarioCliente: '',
      comentarios: '',
      comentarioTrabajo: '',
      estado: 'PENDIENTE',
      presupuestoIdPlantilla: null,
      numeroPresupuesto: null,
      descripcionPresupuesto: null,
      totalPresupuesto: null,
      plantilla: false,
      unidadId: unidadSeleccionada!.unidadId,
      matricula: unidadSeleccionada!.matricula,
      km: 0,
      regHs: false,
      instrucciones: '',
      tipoOrden: TipoOrden.empty(),
      cliente: clienteSeleccionado!,
      tecnico: Tecnico.empty(),
      unidad: unidadSeleccionada!,
      servicio: [],
      otRevisionId: 0,
      planoId: 0,
      alerta: false,
      tecnicoId: ordenProvider.tecnicoId, // Obtener del provider
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Registro de Orden', style: TextStyle(color: colors.onPrimary),),
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
                const Text('Cond. IVA:'),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: condIva,
                      onChanged: (bool? value) {
                        setState(() {
                          condIva = value ?? true;
                        });
                      },
                    ),
                    const Text('Sí'),
                    Radio<bool>(
                      value: false,
                      groupValue: condIva,
                      onChanged: (bool? value) {
                        setState(() {
                          condIva = value ?? false;
                        });
                      },
                    ),
                    const Text('No'),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Datos del cliente - SearchDelegate
            const Text(
              'Datos del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Campo de búsqueda de cliente
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Buscar cliente...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              controller: TextEditingController(
                text: clienteSeleccionado != null 
                    ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}'
                    : '',
              ),
              onTap: () {
                _abrirBusquedaCliente(context);
              },
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
                initialValue: clienteSeleccionado!.direccion,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: clienteSeleccionado!.telefono1,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: clienteSeleccionado!.email,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: 'RUC: ${clienteSeleccionado!.ruc}',
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
                      initialValue: unidadSeleccionada!.marca,
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
                      initialValue: unidadSeleccionada!.modelo,
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
                initialValue: unidadSeleccionada!.matricula,
                decoration: const InputDecoration(
                  labelText: 'Matrícula',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: unidadSeleccionada!.motor,
                decoration: const InputDecoration(
                  labelText: 'Número de Motor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: unidadSeleccionada!.chasis,
                decoration: const InputDecoration(
                  labelText: 'Número de Chasis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: unidadSeleccionada!.anio.toString(),
                decoration: const InputDecoration(
                  labelText: 'Año',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (clienteSeleccionado == null || unidadSeleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                    );
                    return;
                  }
                  
                  // Crear la orden en memoria
                  final ordenCreada = _crearOrdenEnMemoria();
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetallePiezasScreen(
                        cliente: clienteSeleccionado!,
                        vehiculo: unidadSeleccionada!,
                        fecha: fecha,
                        condIva: condIva,
                        ordenPrevia: ordenCreada, // Pasar la orden creada
                      ),
                    ),
                  );
                },
                child: const Text('Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) {
    final telefonoController = TextEditingController();
    final nombreController = TextEditingController();
    final nombreFantasiaController = TextEditingController();
    final rucController = TextEditingController();
    final correoController = TextEditingController();
    final direccionController = TextEditingController();
    final barrioController = TextEditingController();
    final localidadController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Cliente'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *0.8,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Teléfono (primer campo)
                        TextFormField(
                          controller: telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono/Celular',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un teléfono';
                            }
                            if (_telefonoExiste(value)) {
                              return 'Este teléfono ya existe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Nombre
                        TextFormField(
                          controller: nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Nombre Fantasía
                        TextFormField(
                          controller: nombreFantasiaController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Fantasía',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // RUC
                        TextFormField(
                          controller: rucController,
                          decoration: const InputDecoration(
                            labelText: 'RUC',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el RUC';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Correo
                        TextFormField(
                          controller: correoController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese un correo electrónico';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Dirección
                        TextFormField(
                          controller: direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 1,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese una dirección';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Barrio
                        TextFormField(
                          controller: barrioController,
                          decoration: const InputDecoration(
                            labelText: 'Barrio',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Localidad
                        TextFormField(
                          controller: localidadController,
                          decoration: const InputDecoration(
                            labelText: 'Localidad',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final nuevoCliente = Cliente(
                        clienteId: 0,
                        codCliente: '',
                        nombre: nombreController.text,
                        nombreFantasia: nombreFantasiaController.text,
                        direccion: direccionController.text,
                        barrio: barrioController.text,
                        localidad: localidadController.text,
                        telefono1: telefonoController.text,
                        telefono2: '',
                        email: correoController.text,
                        ruc: rucController.text,
                        estado: 'ACTIVO',
                        coordenadas: null,
                        tecnico: Tecnico.empty(),
                        departamento: Departamento.empty(),
                        tipoCliente: TipoCliente.empty(),
                        notas: '',
                        pagoId: 1,
                        vendedorId: 1,
                      );
                      
                      try {
                        await clientServices.postCliente(
                          context, 
                          nuevoCliente, 
                          token
                        );

                        setState(() {
                          clienteSeleccionado = nuevoCliente;
                          clientesLocales.add(nuevoCliente);
                          unidades = [];
                          unidadSeleccionada = null;
                        });
                        
                        Navigator.of(context).pop();
                        
                      } catch (e) {
                        print('Error creando cliente: $e');
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoNuevaUnidad(BuildContext context) async {
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe seleccionar un cliente')),
      );
      return;
    }

    final matriculaController = TextEditingController();
    final anoController = TextEditingController();
    final nroMotorController = TextEditingController();
    final nroChasisController = TextEditingController();
    final marcaController = TextEditingController();
    final modeloController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Variable para almacenar la unidad encontrada
    Unidad? unidadEncontrada;

    // Función para buscar unidad por matrícula
    Future<void> buscarUnidadPorMatricula() async {
      if (matriculaController.text.isEmpty) return;

      try {
        List<Unidad> unidadesEncontradas = await unidadesServices.getUnidades(
          context, 
          token, 
          matricula: matriculaController.text
        );

        if (unidadesEncontradas.isNotEmpty) {
          unidadEncontrada = unidadesEncontradas.first;
          marcaController.text = unidadEncontrada!.marca;
          modeloController.text = unidadEncontrada!.modelo;
          anoController.text = unidadEncontrada!.anio.toString();
          nroMotorController.text = unidadEncontrada!.motor;
          nroChasisController.text = unidadEncontrada!.chasis;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unidad encontrada y cargada automáticamente')),
          );
        } else {
          unidadEncontrada = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró una unidad con esa matrícula')),
          );
        }
      } catch (e) {
        unidadEncontrada = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar la unidad: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) {
            return AlertDialog(
              title: const Text('Nueva Unidad'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cliente: ${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}'),
                      const SizedBox(height: 16),
                      
                      // Matrícula con búsqueda automática
                      TextFormField(
                        controller: matriculaController,
                        decoration: const InputDecoration(
                          labelText: 'Matrícula',
                          border: OutlineInputBorder(),
                          hintText: 'Presione Enter para buscar',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una matrícula';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          buscarUnidadPorMatricula();
                          setStateBd((){});
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Marca
                      TextFormField(
                        controller: marcaController,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la marca';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Modelo
                      TextFormField(
                        controller: modeloController,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el modelo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Año
                      TextFormField(
                        controller: anoController,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un año';
                          }
                          if (value.length != 4 || int.tryParse(value) == null) {
                            return 'Por favor ingrese un año válido de 4 dígitos';
                          }
                          final year = int.parse(value);
                          if (year < 1900 || year > DateTime.now().year + 1) {
                            return 'Año fuera del rango válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Número de Motor
                      TextFormField(
                        controller: nroMotorController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Motor',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el número de motor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Número de Chasis
                      TextFormField(
                        controller: nroChasisController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Chasis',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el número de chasis';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // Si se encontró una unidad durante la búsqueda, usar editar
                        if (unidadEncontrada != null) {
                          // Actualizar la unidad existente con los datos del formulario
                          unidadEncontrada!.marca = marcaController.text;
                          unidadEncontrada!.modelo = modeloController.text;
                          unidadEncontrada!.anio = int.parse(anoController.text);
                          unidadEncontrada!.motor = nroMotorController.text;
                          unidadEncontrada!.chasis = nroChasisController.text;
                          unidadEncontrada!.clienteId = clienteSeleccionado!.clienteId;
                          
                          await unidadesServices.editarUnidad(
                            context,
                            unidadEncontrada!,
                            token
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unidad actualizada correctamente')),
                          );
                        } else {
                          // Si no se encontró unidad, crear una nueva
                          final nuevaUnidad = Unidad(
                            unidadId: 0,
                            itemId: 0,
                            codItem: '',
                            descripcion: '',
                            modeloId: 0,
                            codModelo: '',
                            modelo: modeloController.text,
                            marcaId: 0,
                            codMarca: '',
                            marca: marcaController.text,
                            chasis: nroChasisController.text,
                            motor: nroMotorController.text,
                            anio: int.parse(anoController.text),
                            colorId: 0,
                            color: '',
                            consignado: false,
                            averias: false,
                            matricula: matriculaController.text,
                            km: 0,
                            comentario: '',
                            recibidoPorId: 0,
                            recibidoPor: '',
                            transportadoPor: '',
                            clienteId: clienteSeleccionado!.clienteId,
                            padron: null,
                          );
                          
                          await unidadesServices.crearUnidad(
                            context,
                            nuevaUnidad,
                            token
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unidad creada correctamente')),
                          );
                        }

                        // Actualizar la lista de unidades desde la API
                        List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
                          context, 
                          clienteSeleccionado!.clienteId, 
                          token
                        );

                        setState(() {
                          unidades = unidadesActualizadas;
                          // Seleccionar la unidad recién creada o editada
                          try {
                            unidadSeleccionada = unidades.firstWhere(
                              (u) => u.matricula == matriculaController.text
                            );
                          } catch (e) {
                            // Si no encuentra la unidad, seleccionar la primera si existe
                            unidadSeleccionada = unidades.isNotEmpty ? unidades.first : null;
                          }
                        });

                        Navigator.of(context).pop();
                        
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al guardar unidad: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}