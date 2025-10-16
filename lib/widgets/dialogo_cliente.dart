// dialogo_cliente.dart
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';

class DialogoCliente extends StatefulWidget {
  final ClientServices clientServices;
  final String token;
  final Function(Cliente)? onClienteCreado;
  final bool esEdicion;
  final Cliente? clienteEditar;

  const DialogoCliente({
    super.key,
    required this.clientServices,
    required this.token,
    this.onClienteCreado,
    this.esEdicion = false,
    this.clienteEditar,
  });

  @override
  State<DialogoCliente> createState() => _DialogoClienteState();
}

class _DialogoClienteState extends State<DialogoCliente> {
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _nombreFantasiaController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Departamento? _departamentoSeleccionado;
  List<Departamento> _departamentos = [];
  bool _isLoadingDepartamentos = false;
  bool _isGuardando = false;

  // Variables para búsqueda por teléfono
  List<Cliente> _clientesEncontrados = [];
  Cliente? _clienteSeleccionado;
  bool _buscandoCliente = false;
  bool _mostrarAutocomplete = false;

  @override
  void initState() {
    super.initState();
    _cargarDepartamentos();
    _cargarDatosClienteExistente();
  }

  void _cargarDatosClienteExistente() {
    if (widget.esEdicion && widget.clienteEditar != null) {
      final cliente = widget.clienteEditar!;
      _telefonoController.text = cliente.telefono1;
      _codigoController.text = cliente.codCliente;
      _nombreController.text = cliente.nombre;
      _nombreFantasiaController.text = cliente.nombreFantasia;
      _rucController.text = cliente.ruc;
      _correoController.text = cliente.email;
      _direccionController.text = cliente.direccion;
      _barrioController.text = cliente.barrio;
      _localidadController.text = cliente.localidad;
    }
  }

  Future<void> _cargarDepartamentos() async {
    try {
      setState(() => _isLoadingDepartamentos = true);
      final departamentos = await widget.clientServices.getClientesDepartamentos(context, widget.token);
      
      if (mounted) {
        setState(() {
          _departamentos = departamentos ?? [];
          _isLoadingDepartamentos = false;
        });
      }

      if (widget.esEdicion && widget.clienteEditar != null) {
        final departamentoActual = _departamentos.firstWhere(
          (dep) => dep.departamentoId == widget.clienteEditar!.departamento.departamentoId,
          orElse: () => Departamento.empty(),
        );
        if (departamentoActual.departamentoId != 0) {
          setState(() {
            _departamentoSeleccionado = departamentoActual;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDepartamentos = false);
      }
      print('Error cargando departamentos: $e');
    }
  }

  bool _validarTelefono(String telefono) {
    return telefono.isNotEmpty;
  }

  // Función para buscar cliente por teléfono
  Future<void> _buscarClientePorTelefono() async {
    if (_telefonoController.text.isEmpty) return;

    setState(() {
      _buscandoCliente = true;
      _clientesEncontrados = [];
      _clienteSeleccionado = null;
      _mostrarAutocomplete = false;
    });

    try {
      final clientesEncontrados = await widget.clientServices.getClientes(
        context,
        '', // nombre
        '',    // codCliente
        null,  // estado
        '0',   // tecnicoId (0 para todos)
        widget.token, 
        condicion: _telefonoController.text
      );

      if (clientesEncontrados.isNotEmpty) {
        setState(() {
          _clientesEncontrados = clientesEncontrados;
        });

        if (clientesEncontrados.length == 1) {
          // Si hay solo un cliente, llenar automáticamente
          _seleccionarCliente(clientesEncontrados.first);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente encontrado y cargado automáticamente')),
          );
        } else {
          // Si hay múltiples clientes, mostrar autocomplete
          setState(() {
            _mostrarAutocomplete = true;
          });
        }
      } else {
        // No se encontraron clientes
        _clienteSeleccionado = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró un cliente con ese teléfono')),
        );
      }
    } catch (e) {
      _clienteSeleccionado = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar el cliente: $e')),
      );
    } finally {
      setState(() {
        _buscandoCliente = false;
      });
    }
  }

  // Función para seleccionar un cliente del autocomplete
  void _seleccionarCliente(Cliente cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _telefonoController.text = cliente.telefono1;
      _codigoController.text = cliente.codCliente;
      _nombreController.text = cliente.nombre;
      _nombreFantasiaController.text = cliente.nombreFantasia;
      _rucController.text = cliente.ruc;
      _correoController.text = cliente.email;
      _direccionController.text = cliente.direccion;
      _barrioController.text = cliente.barrio;
      _localidadController.text = cliente.localidad;
      _mostrarAutocomplete = false;
      
      // Buscar y seleccionar departamento
      if (cliente.departamento.departamentoId != 0) {
        final departamento = _departamentos.firstWhere(
          (dep) => dep.departamentoId == cliente.departamento.departamentoId,
          orElse: () => Departamento.empty(),
        );
        if (departamento.departamentoId != 0) {
          _departamentoSeleccionado = departamento;
        }
      }
    });
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGuardando = true);

    try {
      final esEdicion = widget.esEdicion || _clienteSeleccionado != null;
      final clienteExistente = widget.clienteEditar ?? _clienteSeleccionado;

      final nuevoCliente = Cliente(
        clienteId: esEdicion ? clienteExistente!.clienteId : 0,
        codCliente: _codigoController.text,
        nombre: _nombreController.text,
        nombreFantasia: _nombreFantasiaController.text,
        direccion: _direccionController.text,
        barrio: _barrioController.text,
        localidad: _localidadController.text,
        telefono1: _telefonoController.text,
        telefono2: '',
        email: _correoController.text,
        ruc: _rucController.text,
        estado: 'A',
        coordenadas: null,
        tecnico: Tecnico.empty(),
        departamento: _departamentoSeleccionado ?? Departamento.empty(),
        tipoCliente: TipoCliente.empty(),
        notas: '',
        pagoId: 0,
        vendedorId: 0,
        departamentoId: _departamentoSeleccionado?.departamentoId ?? 0,
        tipoClienteId: 1,
        tecnicoId: context.read<OrdenProvider>().tecnicoId,
      );

      Cliente? clienteGuardado;
      
      if (esEdicion) {
        clienteGuardado = await widget.clientServices.putCliente(
          context, 
          nuevoCliente, 
          widget.token
        );
      } else {
        clienteGuardado = await widget.clientServices.postCliente(
          context, 
          nuevoCliente, 
          widget.token
        );
      }

      if (!mounted) return;

      if (clienteGuardado != null) {
        if (widget.onClienteCreado != null) {
          widget.onClienteCreado!(clienteGuardado);
        }
        
        Navigator.of(context).pop(clienteGuardado);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${esEdicion ? 'editar' : 'crear'} el cliente - Servicio retornó null'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isGuardando = false);
      }

    } catch (e) {
      print('Error ${widget.esEdicion ? 'editando' : 'creando'} cliente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} el cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isGuardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
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
                  Icon(
                    widget.esEdicion ? Icons.edit : Icons.person_add,
                    size: 28,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
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
                key: _formKey,
                child: Column(
                  children: [
                    // Campo de teléfono con búsqueda
                    _buildCampoTelefono(),
                    const SizedBox(height: 16),

                    // Autocomplete para múltiples clientes
                    if (_mostrarAutocomplete && _clientesEncontrados.length > 1) ...[
                      _buildAutocompleteClientes(),
                      const SizedBox(height: 16),
                    ],

                    // Código cliente
                    if (_clienteSeleccionado != null && _clienteSeleccionado?.codCliente != '') ...[
                      TextFormField(
                        controller: _codigoController,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Código cliente',
                          prefixIcon: Icon(Icons.badge, color: colors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.onError, width: 2),
                          ),
                          errorStyle: TextStyle(color: colors.onError),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un código de cliente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.onError, width: 2),
                        ),
                        errorStyle: TextStyle(color: colors.onError),
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
                      controller: _nombreFantasiaController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Fantasía',
                        prefixIcon: Icon(Icons.business_outlined, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.onError, width: 2),
                        ),
                        errorStyle: TextStyle(color: colors.onError),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // RUC
                    TextFormField(
                      controller: _rucController,
                      decoration: InputDecoration(
                        labelText: 'RUC',
                        prefixIcon: Icon(Icons.badge_outlined, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.onError, width: 2),
                        ),
                        errorStyle: TextStyle(color: colors.onError),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    TextFormField(
                      controller: _correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.onError, width: 2),
                        ),
                        errorStyle: TextStyle(color: colors.onError),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Departamento
                    _isLoadingDepartamentos
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<Departamento>(
                              value: _departamentoSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'Departamento',
                                prefixIcon: Icon(Icons.location_city_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.onError, width: 2),
                                ),
                                errorStyle: TextStyle(color: colors.onError),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              items: _departamentos.map((departamento) {
                                return DropdownMenuItem<Departamento>(
                                  value: departamento,
                                  child: Text(departamento.nombre),
                                );
                              }).toList(),
                              onChanged: (Departamento? newValue) {
                                setState(() {
                                  _departamentoSeleccionado = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor seleccione un departamento';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                    const SizedBox(height: 16),

                    // Dirección
                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on_outlined, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.onError, width: 2),
                        ),
                        errorStyle: TextStyle(color: colors.onError),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                      maxLines: 1,
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
                      controller: _barrioController,
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
                      controller: _localidadController,
                      decoration: InputDecoration(
                        labelText: 'Localidad',
                        prefixIcon: Icon(Icons.place_outlined, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.onError, width: 2),
                        ),
                        errorStyle: TextStyle(color: colors.onError),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una localidad';
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
                    onPressed: _isGuardando ? null : () => Navigator.of(context).pop(),
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
                    onPressed: _isGuardando ? null : _guardarCliente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isGuardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.esEdicion ? 'Guardar Cambios' : 'Guardar Cliente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoTelefono() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teléfono/Celular',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ingrese teléfono para buscar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onError, width: 2),
                  ),
                  errorStyle: TextStyle(color: colors.onError),
                  suffixIcon: _buscandoCliente 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _buscarClientePorTelefono(),
                        ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                onFieldSubmitted: (value) => _buscarClientePorTelefono(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un teléfono';
                  }
                  if (!_validarTelefono(value)) {
                    return 'Por favor ingrese un teléfono válido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (_clienteSeleccionado != null) ...[
          const SizedBox(height: 8),
          Text(
            '✓ Cliente encontrado - Complete los datos restantes',
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAutocompleteClientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Se encontraron múltiples clientes, seleccione uno:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _clientesEncontrados.map((cliente) {
              return ListTile(
                title: Text(cliente.nombre),
                subtitle: Text('${cliente.codCliente} - ${cliente.telefono1}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _seleccionarCliente(cliente),
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}