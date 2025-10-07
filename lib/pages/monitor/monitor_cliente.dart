// monitor_cliente.dart
import 'dart:async';

import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorClientes extends StatefulWidget {
  const MonitorClientes({
    super.key,
  });

  @override
  MonitorClientesState createState() => MonitorClientesState();
}

class MonitorClientesState extends State<MonitorClientes> {
  List<Cliente> clientes = [];
  List<Cliente> clientesFiltrados = [];
  TextEditingController searchController = TextEditingController();
  
  // Variables para búsqueda en tiempo real
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  // Variables para paginación
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ClientServices clientServices = ClientServices();
  String token = '';

  @override
  void initState() {
    super.initState();
    _cargarClientesIniciales();
    // Corregir: obtener el token del provider correctamente
    token = context.read<OrdenProvider>().token;
    searchController.addListener(_filtrarClientesEnTiempoReal);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _cargarMasDatos();
    }
  }

  Future<void> _cargarMasDatos() async {
    if (_isLoadingMore || !_hasMore || searchController.text.isEmpty) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      // Incrementar el offset para la próxima página
      final nuevoOffset = _offset + _limit;
      
      final nuevosClientes = await clientServices.getClientes(
        context,
        searchController.text, // nombre
        '',    // codCliente
        null,  // estado
        '0',   // tecnicoId (0 para todos)
        token,
      );
      
      if (nuevosClientes != null && nuevosClientes.isNotEmpty) {
        setState(() {
          clientesFiltrados.addAll(nuevosClientes);
          _offset = nuevoOffset; // Actualizar el offset
          _hasMore = nuevosClientes.length == _limit;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      print('Error al cargar más clientes: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _cargarClientesIniciales() async {
    try {
      setState(() {
        _isLoading = true;
        _offset = 0; // Resetear offset al cargar inicialmente
      });
      
      final clientesIniciales = await clientServices.getClientes(
        context,
        '', // nombre vacío para traer todos
        '', // codCliente vacío
        null, // estado null
        '0', // tecnicoId 0 para todos
        token,
      );

      if (clientesIniciales != null) {
        setState(() {
          clientes = clientesIniciales;
          clientesFiltrados = clientesIniciales;
          _isLoading = false;
          _hasMore = clientesIniciales.length == _limit;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando clientes iniciales: $e');
    }
  }

  void _filtrarClientesEnTiempoReal() {
    final query = searchController.text;
    
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        clientesFiltrados = clientes;
        _isSearching = false;
        _hasMore = true;
        _offset = 0; // Resetear offset cuando se limpia la búsqueda
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
        _hasMore = true;
        _offset = 0; // Resetear offset para nueva búsqueda
      });
      
      try {
        final resultados = await clientServices.getClientes(
          context,
          query, // nombre
          '',    // codCliente
          null,  // estado
          '0',   // tecnicoId (0 para todos)
          token,
        );
        
        if (mounted) {
          setState(() {
            clientesFiltrados = resultados ?? [];
            _isSearching = false;
            _hasMore = (resultados?.length ?? 0) == _limit;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            clientesFiltrados = [];
            _isSearching = false;
          });
        }
        print('Error buscando clientes: $e');
      }
    });
  }

  Future<void> _recargarDatos() async {
    if (searchController.text.isEmpty) {
      await _cargarClientesIniciales();
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _offset = 0; // Resetear offset al recargar
      });
      
      final resultados = await clientServices.getClientes(
        context,
        searchController.text, // nombre
        '',    // codCliente
        null,  // estado
        '0',   // tecnicoId (0 para todos)
        token,
      );
      
      setState(() {
        clientesFiltrados = resultados ?? [];
        _isLoading = false;
        _hasMore = (resultados?.length ?? 0) == _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al recargar clientes: $e');
    }
  }

  void _limpiarBusqueda() {
    searchController.clear();
    FocusScope.of(context).unfocus();
  }

  bool _telefonoExiste(String telefono) {
    return clientes.any((c) => c.telefono1 == telefono);
  }

  Widget _buildLoadingMoreIndicator() {
    return _hasMore 
      ? const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        )
      : const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No hay más resultados',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargarDatos,
            tooltip: 'Recargar datos',
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _limpiarBusqueda,
              tooltip: 'Limpiar búsqueda',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar cliente...',
                hintText: 'Buscar por nombre, RUC, teléfono...',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : clientesFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: colors.onSurface.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'No hay clientes registrados'
                                      : 'No se encontraron resultados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colors.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            itemCount: clientesFiltrados.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) => Divider(height: 1, color: colors.outline.withOpacity(0.3)),
                            itemBuilder: (context, index) {
                              if (index == clientesFiltrados.length) {
                                return _buildLoadingMoreIndicator();
                              }
                              
                              final cliente = clientesFiltrados[index];
                              final nombreCompleto = '${cliente.nombre} ${cliente.nombreFantasia}';
                              
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
                                    nombreCompleto,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (cliente.ruc.isNotEmpty)
                                        Text(
                                          'RUC: ${cliente.ruc}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      if (cliente.ruc.isNotEmpty) const SizedBox(height: 2),
                                      if (cliente.email.isNotEmpty)
                                        Text(
                                          'Correo: ${cliente.email}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      if (cliente.email.isNotEmpty) const SizedBox(height: 2),
                                      if (cliente.telefono1.isNotEmpty)
                                        Text(
                                          'Teléfono: ${cliente.telefono1}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      if (cliente.telefono1.isNotEmpty) const SizedBox(height: 2),
                                      if (cliente.direccion.isNotEmpty)
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
                                      cliente.nombre.isNotEmpty ? cliente.nombre[0] : 'C',
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
    final nombreFantasiaController = TextEditingController();
    final rucController = TextEditingController();
    final correoController = TextEditingController();
    final direccionController = TextEditingController();
    final barrioController = TextEditingController();
    final localidadController = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final formKey = GlobalKey<FormState>();

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
                            
                            // Nombre Fantasía
                            TextFormField(
                              controller: nombreFantasiaController,
                              decoration: InputDecoration(
                                labelText: 'Nombre Fantasía',
                                prefixIcon: Icon(Icons.business_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // RUC
                            TextFormField(
                              controller: rucController,
                              decoration: InputDecoration(
                                labelText: 'RUC',
                                prefixIcon: Icon(Icons.badge_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el RUC';
                                }
                                return null;
                              },
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
                            
                            // Dirección
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
                            const SizedBox(height: 16),
                            
                            // Barrio
                            TextFormField(
                              controller: barrioController,
                              decoration: InputDecoration(
                                labelText: 'Barrio',
                                prefixIcon: Icon(Icons.location_city_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Localidad
                            TextFormField(
                              controller: localidadController,
                              decoration: InputDecoration(
                                labelText: 'Localidad',
                                prefixIcon: Icon(Icons.place_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
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
                                  pagoId: 0,
                                  vendedorId: 0,
                                );
                                
                                try {
                                  await clientServices.postCliente(
                                    context, 
                                    nuevoCliente, 
                                    token
                                  );

                                  // Recargar los datos después de crear el cliente
                                  await _recargarDatos();
                                  
                                  Navigator.of(context).pop();
                                  
                                } catch (e) {
                                  print('Error creando cliente: $e');
                                }
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