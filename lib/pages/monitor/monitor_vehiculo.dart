// monitor_vehiculo.dart
import 'package:app_tec_sedel/models/cliente_chapa_pintura.dart';
import 'package:flutter/material.dart';

class MonitorVehiculos extends StatefulWidget {
  const MonitorVehiculos({super.key});

  @override
  MonitorVehiculosState createState() => MonitorVehiculosState();
}

class MonitorVehiculosState extends State<MonitorVehiculos> {
  
  List<Vehiculo> vehiculos = SharedData.vehiculos;
  List<Vehiculo> vehiculosFiltrados = [];
  TextEditingController searchController = TextEditingController();
  String? selectedMarca;
  List<String> modelosDisponibles = [];

  @override
  void initState() {
    super.initState();
    vehiculosFiltrados = vehiculos;
    searchController.addListener(_filtrarVehiculos);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filtrarVehiculos() {
    final query = searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        vehiculosFiltrados = vehiculos;
      });
      return;
    }

    setState(() {
      vehiculosFiltrados = vehiculos.where((vehiculo) {
        return vehiculo.marca.toLowerCase().contains(query) ||
            vehiculo.matricula.toLowerCase().contains(query) ||
            vehiculo.modelo.toLowerCase().contains(query) ||
            vehiculo.ano.toString().contains(query) ||
            vehiculo.nroMotor.toLowerCase().contains(query) ||
            vehiculo.nroChasis.toLowerCase().contains(query) ||
            vehiculo.displayInfo.toLowerCase().contains(query);
      }).toList();
    });
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

  bool _matriculaExiste(String matricula) {
    return vehiculos.any((v) => v.matricula.toLowerCase() == matricula.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Lista de Vehículos', style: TextStyle(color: colors.onPrimary)),
        iconTheme: IconThemeData(color: colors.onPrimary),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar vehículo',
                prefixIcon: Icon(Icons.search, color: colors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: vehiculosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 64, color: colors.onSurface.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No hay vehículos registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: vehiculosFiltrados.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: colors.outline.withOpacity(0.3)),
                    itemBuilder: (context, index) {
                      final vehiculo = vehiculosFiltrados[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            vehiculo.displayInfo,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Año: ${vehiculo.ano}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Motor: ${vehiculo.nroMotor}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chasis: ${vehiculo.nroChasis}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colors.primary.withOpacity(0.2),
                            child: Text(
                              vehiculo.marca[0],
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogoNuevoVehiculo(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }

  void _mostrarDialogoNuevoVehiculo(BuildContext context) {
    final matriculaController = TextEditingController();
    final anoController = TextEditingController();
    final nroMotorController = TextEditingController();
    final nroChasisController = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final formKey = GlobalKey<FormState>();
    
    String? selectedMarcaLocal;
    String? selectedModelo;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_car, size: 28, color: colors.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Nuevo Vehículo',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            // Matrícula (primer campo)
                            TextFormField(
                              controller: matriculaController,
                              decoration: InputDecoration(
                                labelText: 'Matrícula',
                                prefixIcon: Icon(Icons.confirmation_number_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                            const SizedBox(height: 16),
                            
                            // Marca (Dropdown)
                            DropdownButtonFormField<String>(
                              value: selectedMarcaLocal,
                              decoration: InputDecoration(
                                labelText: 'Marca',
                                prefixIcon: Icon(Icons.branding_watermark_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                            const SizedBox(height: 16),
                            
                            // Modelo (Dropdown dependiente de la marca)
                            DropdownButtonFormField<String>(
                              value: selectedModelo,
                              decoration: InputDecoration(
                                labelText: 'Modelo',
                                prefixIcon: Icon(Icons.model_training_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                            const SizedBox(height: 16),
                            
                            // Año
                            TextFormField(
                              controller: anoController,
                              decoration: InputDecoration(
                                labelText: 'Año',
                                prefixIcon: Icon(Icons.calendar_today_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                            const SizedBox(height: 16),
                            
                            // Número de Motor
                            TextFormField(
                              controller: nroMotorController,
                              decoration: InputDecoration(
                                labelText: 'Número de Motor',
                                prefixIcon: Icon(Icons.engineering_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el número de motor';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Número de Chasis
                            TextFormField(
                              controller: nroChasisController,
                              decoration: InputDecoration(
                                labelText: 'Número de Chasis',
                                prefixIcon: Icon(Icons.build_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.onSurface,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(color: colors.outline),
                            ),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final nuevoVehiculo = Vehiculo(
                                  id: SharedData.vehiculos.length + 1,
                                  matricula: matriculaController.text,
                                  marca: selectedMarcaLocal!,
                                  modelo: selectedModelo!,
                                  ano: int.parse(anoController.text),
                                  nroMotor: nroMotorController.text,
                                  nroChasis: nroChasisController.text, 
                                  clienteId: 0,
                                );
                                
                                setState(() {
                                  SharedData.vehiculos.add(nuevoVehiculo);
                                  vehiculos = SharedData.vehiculos;
                                  vehiculosFiltrados = vehiculos;
                                });
                                
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Vehículo agregado correctamente'),
                                    backgroundColor: colors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Guardar Vehículo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}