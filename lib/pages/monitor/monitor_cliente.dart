// monitor_cliente.dart
import 'package:app_tec_sedel/models/cliente_chapa_pintura.dart';
import 'package:flutter/material.dart';

class MonitorClientes extends StatefulWidget {
  const MonitorClientes({super.key});

  @override
  MonitorClientesState createState() => MonitorClientesState();
}

class MonitorClientesState extends State<MonitorClientes> {
  List<ClienteCP> clientes = SharedData.clientes;
  List<ClienteCP> clientesFiltrados = [];
  TextEditingController searchController = TextEditingController();
  bool tipoDocumentoCI = true;

  @override
  void initState() {
    super.initState();
    clientesFiltrados = clientes;
    searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filtrarClientes() {
    final query = searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        clientesFiltrados = clientes;
      });
      return;
    }

    setState(() {
      clientesFiltrados = clientes.where((cliente) {
        return cliente.nombre.toLowerCase().contains(query) ||
            cliente.apellido.toLowerCase().contains(query) ||
            cliente.direccion.toLowerCase().contains(query) ||
            cliente.telefono.toLowerCase().contains(query) ||
            cliente.documento.toLowerCase().contains(query) ||
            cliente.correo.toLowerCase().contains(query) ||
            cliente.nombreCompleto.toLowerCase().contains(query);
      }).toList();
    });
  }

  bool _telefonoExiste(String telefono) {
    return clientes.any((c) => c.telefono == telefono);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Lista de Clientes', style: TextStyle(color: colors.onPrimary)),
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
                labelText: 'Buscar cliente',
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
            child: clientesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: colors.onSurface.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No hay clientes registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: clientesFiltrados.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: colors.outline.withOpacity(0.3)),
                    itemBuilder: (context, index) {
                      final cliente = clientesFiltrados[index];
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
                            cliente.nombreCompleto,
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
                                '${cliente.tipoDocumento}: ${cliente.documento}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Correo: ${cliente.correo}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Teléfono: ${cliente.telefono}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dirección: ${cliente.direccion}',
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
                              cliente.nombre[0],
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogoNuevoCliente(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) {
    final telefonoController = TextEditingController();
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final documentoController = TextEditingController();
    final correoController = TextEditingController();
    final direccionController = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final formKey = GlobalKey<FormState>();
    bool tipoDocumentoCI = true;

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
                          Icon(Icons.person_add, size: 28, color: colors.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Nuevo Cliente',
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
                            // Teléfono (primer campo)
                            TextFormField(
                              controller: telefonoController,
                              decoration: InputDecoration(
                                labelText: 'Teléfono/Celular',
                                prefixIcon: Icon(Icons.phone_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                            const SizedBox(height: 16),
                            
                            // Nombre
                            TextFormField(
                              controller: nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese un nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Apellido
                            TextFormField(
                              controller: apellidoController,
                              decoration: InputDecoration(
                                labelText: 'Apellido',
                                prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese un apellido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Documento con Switch
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: documentoController,
                                    decoration: InputDecoration(
                                      labelText: 'Documento',
                                      prefixIcon: Icon(Icons.badge_outlined, color: colors.primary),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colors.primary, width: 2),
                                      ),
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
                            const SizedBox(height: 16),
                            
                            // Correo
                            TextFormField(
                              controller: correoController,
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                            const SizedBox(height: 16),
                            
                            // Dirección (último campo)
                            TextFormField(
                              controller: direccionController,
                              decoration: InputDecoration(
                                labelText: 'Dirección',
                                prefixIcon: Icon(Icons.location_on_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
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
                                  clientes = SharedData.clientes;
                                  clientesFiltrados = clientes;
                                });
                                
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Cliente agregado correctamente'),
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
                            child: const Text('Guardar Cliente'),
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