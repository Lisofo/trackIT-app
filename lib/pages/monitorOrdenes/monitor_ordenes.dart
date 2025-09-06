import 'package:app_tec_sedel/models/cliente_chapa_pintura.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'detlla_piezas_screen.dart';

class MonitorOrdenes extends StatefulWidget {
  const MonitorOrdenes({super.key});

  @override
  State<MonitorOrdenes> createState() => _MonitorOrdenesState();
}

class _MonitorOrdenesState extends State<MonitorOrdenes> {
  // Usamos SharedData en lugar de lista local
  List<ClienteCP> get clientes => SharedData.clientes;
  
  List<Vehiculo> vehiculos = [];
  
  // Controladores
  DateTime fecha = DateTime.now();
  bool condIva = true;
  ClienteCP? clienteSeleccionado;
  Vehiculo? vehiculoSeleccionado;
  String? selectedMarca;
  List<String> modelosDisponibles = [];
  bool tipoDocumentoCI = true;

  @override
  void initState() {
    super.initState();
    // Inicializar vehículos si hay un cliente seleccionado por defecto
    if (clientes.isNotEmpty) {
      clienteSeleccionado = clientes.first;
      vehiculos = _getVehiculosPorCliente(clienteSeleccionado!.id);
    }
  }

  void _actualizarModelos(String? marca) {
    setState(() {
      selectedMarca = marca;
      if (marca != null) {
        final marcaObj = SharedData.marcas.firstWhere(
          (m) => m.nombre == marca,
          orElse: () => Marca(id: 0, nombre: '', modelos: []),
        );
        modelosDisponibles = marcaObj.modelos;
      } else {
        modelosDisponibles = [];
      }
    });
  }

  bool _telefonoExiste(String telefono) {
    return clientes.any((c) => c.telefono == telefono);
  }

  bool _matriculaExiste(String matricula) {
    return SharedData.vehiculos.any((v) => v.matricula.toLowerCase() == matricula.toLowerCase());
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Registro de Vehículo', style: TextStyle(color: colors.onPrimary),),
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
            
            // Datos del cliente
            const Text(
              'Datos del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ClienteCP>(
              value: clienteSeleccionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Seleccione un cliente',
              ),
              items: clientes.map((ClienteCP cliente) {
                return DropdownMenuItem<ClienteCP>(
                  value: cliente,
                  child: Text(cliente.nombreCompleto),
                );
              }).toList(),
              onChanged: (ClienteCP? nuevoCliente) {
                setState(() {
                  clienteSeleccionado = nuevoCliente;
                  // Filtrar vehículos por cliente seleccionado
                  vehiculos = _getVehiculosPorCliente(nuevoCliente?.id ?? 0);
                  vehiculoSeleccionado = null;
                });
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
                initialValue: clienteSeleccionado!.telefono,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: clienteSeleccionado!.correo,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: '${clienteSeleccionado!.tipoDocumento}: ${clienteSeleccionado!.documento}',
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
                  child: DropdownButtonFormField<Vehiculo>(
                    value: vehiculoSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Seleccione un vehículo',
                    ),
                    items: vehiculos.map((Vehiculo vehiculo) {
                      return DropdownMenuItem<Vehiculo>(
                        value: vehiculo,
                        child: Text(vehiculo.displayInfo),
                      );
                    }).toList(),
                    onChanged: (Vehiculo? nuevoVehiculo) {
                      setState(() {
                        vehiculoSeleccionado = nuevoVehiculo;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _mostrarDialogoNuevoVehiculo(context);
                  },
                ),
              ],
            ),
            
            // Campos de visualización del vehículo
            if (vehiculoSeleccionado != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      initialValue: vehiculoSeleccionado!.marca,
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
                      initialValue: vehiculoSeleccionado!.modelo,
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
                initialValue: vehiculoSeleccionado!.matricula,
                decoration: const InputDecoration(
                  labelText: 'Matrícula',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: vehiculoSeleccionado!.nroMotor,
                decoration: const InputDecoration(
                  labelText: 'Número de Motor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: vehiculoSeleccionado!.nroChasis,
                decoration: const InputDecoration(
                  labelText: 'Número de Chasis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: vehiculoSeleccionado!.ano.toString(),
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
                  if (clienteSeleccionado == null || vehiculoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetallePiezasScreen(
                        cliente: clienteSeleccionado!,
                        vehiculo: vehiculoSeleccionado!,
                        fecha: fecha,
                        condIva: condIva,
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

  List<Vehiculo> _getVehiculosPorCliente(int clienteId) {
    // Usamos SharedData para obtener los vehículos
    return SharedData.vehiculos.where((vehiculo) => vehiculo.clienteId == clienteId).toList();
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) {
    final telefonoController = TextEditingController();
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final documentoController = TextEditingController();
    final correoController = TextEditingController();
    final direccionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool tipoDocumentoCI = true;
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Cliente'),
              content: SingleChildScrollView(
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
                      
                      // Apellido
                      TextFormField(
                        controller: apellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un apellido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Documento con Switch
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: documentoController,
                              decoration: const InputDecoration(
                                labelText: 'Documento',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese un documento';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Text(
                                tipoDocumentoCI ? 'CI' : 'RUT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                              Switch(
                                value: tipoDocumentoCI,
                                onChanged: (value) {
                                  setState(() {
                                    tipoDocumentoCI = value;
                                  });
                                },
                                activeColor: colors.primary,
                              ),
                            ],
                          ),
                        ],
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
                      
                      // Dirección (último campo)
                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una dirección';
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
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final nuevoCliente = ClienteCP(
                        id: SharedData.clientes.length + 1,
                        nombre: nombreController.text,
                        apellido: apellidoController.text,
                        direccion: direccionController.text,
                        telefono: telefonoController.text,
                        documento: documentoController.text,
                        tipoDocumento: tipoDocumentoCI ? 'CI' : 'RUT',
                        correo: correoController.text,
                      );
                      
                      setState(() {
                        SharedData.clientes.add(nuevoCliente);
                        clienteSeleccionado = nuevoCliente;
                        vehiculos = _getVehiculosPorCliente(nuevoCliente.id);
                        vehiculoSeleccionado = null;
                      });
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cliente agregado correctamente')),
                      );
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

  void _mostrarDialogoNuevoVehiculo(BuildContext context) {
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
    final formKey = GlobalKey<FormState>();
    String? selectedMarcaLocal;
    String? selectedModelo;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Vehículo'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cliente: ${clienteSeleccionado!.nombreCompleto}'),
                      const SizedBox(height: 16),
                      
                      // Matrícula (primer campo)
                      TextFormField(
                        controller: matriculaController,
                        decoration: const InputDecoration(
                          labelText: 'Matrícula',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una matrícula';
                          }
                          if (_matriculaExiste(value)) {
                            return 'Esta matrícula ya existe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Marca (Dropdown)
                      DropdownButtonFormField<String>(
                        value: selectedMarcaLocal,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                        ),
                        items: SharedData.marcas.map((marca) {
                          return DropdownMenuItem<String>(
                            value: marca.nombre,
                            child: Text(marca.nombre),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMarcaLocal = value;
                            selectedModelo = null;
                            _actualizarModelos(value);
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione una marca';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Modelo (Dropdown dependiente de la marca)
                      DropdownButtonFormField<String>(
                        value: selectedModelo,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                        ),
                        items: modelosDisponibles.map((modelo) {
                          return DropdownMenuItem<String>(
                            value: modelo,
                            child: Text(modelo),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedModelo = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione un modelo';
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
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final nuevoVehiculo = Vehiculo(
                        id: SharedData.vehiculos.length + 1,
                        clienteId: clienteSeleccionado!.id,
                        matricula: matriculaController.text,
                        marca: selectedMarcaLocal!,
                        modelo: selectedModelo!,
                        ano: int.parse(anoController.text),
                        nroMotor: nroMotorController.text,
                        nroChasis: nroChasisController.text,
                      );
                      
                      setState(() {
                        SharedData.vehiculos.add(nuevoVehiculo);
                        vehiculos = _getVehiculosPorCliente(clienteSeleccionado!.id);
                        vehiculoSeleccionado = nuevoVehiculo;
                      });
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vehículo agregado correctamente')),
                      );
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