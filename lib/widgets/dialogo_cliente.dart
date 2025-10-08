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

      // Si estamos editando, seleccionar el departamento actual del cliente
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
    // Aquí puedes agregar validaciones específicas para el teléfono
    return telefono.isNotEmpty;
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGuardando = true);

    try {
      final nuevoCliente = Cliente(
        clienteId: widget.esEdicion ? widget.clienteEditar!.clienteId : 0,
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
      
      if (widget.esEdicion) {
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

      // Verificar si el widget sigue montado antes de realizar cualquier acción
      if (!mounted) return;

      if (clienteGuardado != null) {
        // Llamar al callback si existe
        if (widget.onClienteCreado != null) {
          widget.onClienteCreado!(clienteGuardado);
        }
        
        // Cerrar el diálogo y retornar el cliente guardado
        Navigator.of(context).pop(clienteGuardado);
      } else {
        // Si hubo error, mostrar mensaje pero no cerrar el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} el cliente - Servicio retornó null'),
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
                    // Teléfono
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono/Celular',
                        prefixIcon: Icon(Icons.phone_outlined, color: colors.primary),
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
                      keyboardType: TextInputType.phone,
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
                    const SizedBox(height: 16),

                    // Código cliente
                    TextFormField(
                      controller: _codigoController,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre de fantasía';
                        }
                        return null;
                      },
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
}