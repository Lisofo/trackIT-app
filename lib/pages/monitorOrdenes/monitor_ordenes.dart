import 'package:app_tec_sedel/models/cliente_chapa_pintura.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonitorOrdenes extends StatefulWidget {
  const MonitorOrdenes({super.key});

  @override
  State<MonitorOrdenes> createState() => _MonitorOrdenesState();
}

class _MonitorOrdenesState extends State<MonitorOrdenes> {
  final List<ClienteCP> clientes = [
    ClienteCP(id: 1, nombre: 'GOMEZ', apellido: 'HECTOR', direccion: 'SOLFERINO 3900', telefono: '5069884'),
    ClienteCP(id: 2, nombre: 'PEREZ', apellido: 'JUAN', direccion: 'AV. LIBERTADOR 123', telefono: '1234567'),
    ClienteCP(id: 3, nombre: 'LOPEZ', apellido: 'MARIA', direccion: 'CALLE 45 #67-89', telefono: '7654321'),
  ];

  List<Vehiculo> vehiculos = [];
  
  // Controladores
  DateTime fecha = DateTime.now();
  bool condIva = true;
  ClienteCP? clienteSeleccionado;
  Vehiculo? vehiculoSeleccionado;
  
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
            ],
          ],
        ),
      ),
    );
  }

  List<Vehiculo> _getVehiculosPorCliente(int clienteId) {
    // Simulación de datos - en una app real esto vendría de una base de datos
    if (clienteId == 1) {
      return [
        Vehiculo(id: 1, clienteId: 1, marca: 'Toyota', modelo: 'Corolla', matricula: 'ABC123', ano: 2020),
        Vehiculo(id: 2, clienteId: 1, marca: 'Ford', modelo: 'Focus', matricula: 'DEF456', ano: 2018),
      ];
    } else if (clienteId == 2) {
      return [
        Vehiculo(id: 3, clienteId: 2, marca: 'Volkswagen', modelo: 'Golf', matricula: 'GHI789', ano: 2019),
      ];
    } else if (clienteId == 3) {
      return [
        Vehiculo(id: 4, clienteId: 3, marca: 'Fiat', modelo: 'Cronos', matricula: 'JKL012', ano: 2021),
        Vehiculo(id: 5, clienteId: 3, marca: 'Chevrolet', modelo: 'Onix', matricula: 'MNO345', ano: 2022),
      ];
    }
    return [];
  }

  void _mostrarDialogoNuevoVehiculo(BuildContext context) {
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe seleccionar un cliente')),
      );
      return;
    }

    final marcaController = TextEditingController();
    final modeloController = TextEditingController();
    final matriculaController = TextEditingController();
    final anoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuevo Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cliente: ${clienteSeleccionado!.nombreCompleto}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: marcaController,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: matriculaController,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: anoController,
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                final nuevoVehiculo = Vehiculo(
                  id: vehiculos.length + 1,
                  clienteId: clienteSeleccionado!.id,
                  marca: marcaController.text,
                  modelo: modeloController.text,
                  matricula: matriculaController.text,
                  ano: int.tryParse(anoController.text) ?? 0,
                );
                
                setState(() {
                  vehiculos.add(nuevoVehiculo);
                  vehiculoSeleccionado = nuevoVehiculo;
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehículo agregado correctamente')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}