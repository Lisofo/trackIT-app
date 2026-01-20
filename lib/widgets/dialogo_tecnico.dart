// dialogo_tecnico.dart
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/services/tecnicos_services.dart';

class DialogoTecnico extends StatefulWidget {
  final TecnicosServices tecnicosServices;
  final String token;
  final Function(Tecnico)? onTecnicoCreado;
  final bool esEdicion;
  final Tecnico? tecnicoEditar;

  const DialogoTecnico({
    super.key,
    required this.tecnicosServices,
    required this.token,
    this.onTecnicoCreado,
    this.esEdicion = false,
    this.tecnicoEditar,
  });

  @override
  State<DialogoTecnico> createState() => _DialogoTecnicoState();
}

class _DialogoTecnicoState extends State<DialogoTecnico> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  final TextEditingController _fechaIngresoController = TextEditingController();
  final TextEditingController _fechaVtoCarneController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;
  DateTime? _fechaVtoCarne;

  @override
  void initState() {
    super.initState();
    _cargarDatosTecnicoExistente();
  }

  void _cargarDatosTecnicoExistente() {
    if (widget.esEdicion && widget.tecnicoEditar != null) {
      final tecnico = widget.tecnicoEditar!;
      _codigoController.text = tecnico.codTecnico;
      _nombreController.text = tecnico.nombre;
      _documentoController.text = tecnico.documento;
      
      if (tecnico.fechaNacimiento != null) {
        _fechaNacimiento = tecnico.fechaNacimiento;
        _fechaNacimientoController.text = _formatearFecha(tecnico.fechaNacimiento!);
      }
      
      if (tecnico.fechaIngreso != null) {
        _fechaIngreso = tecnico.fechaIngreso;
        _fechaIngresoController.text = _formatearFecha(tecnico.fechaIngreso!);
      }
      
      if (tecnico.fechaVtoCarneSalud != null) {
        _fechaVtoCarne = tecnico.fechaVtoCarneSalud;
        _fechaVtoCarneController.text = _formatearFecha(tecnico.fechaVtoCarneSalud!);
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Future<void> _seleccionarFecha(BuildContext context, Function(DateTime) onFechaSeleccionada) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onFechaSeleccionada(picked);
    }
  }

  Future<void> _guardarTecnico() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGuardando = true);

    try {
      final nuevoTecnico = Tecnico(
        tecnicoId: widget.esEdicion ? widget.tecnicoEditar!.tecnicoId : 0,
        codTecnico: _codigoController.text,
        nombre: _nombreController.text,
        fechaNacimiento: _fechaNacimiento,
        documento: _documentoController.text,
        fechaIngreso: _fechaIngreso,
        fechaVtoCarneSalud: _fechaVtoCarne,
        deshabilitado: false,
        cargo: Cargo(cargoId: 1, codCargo: 'GEN', descripcion: 'GENERAL'),
        firmaPath: '',
        avatarMd5: '',
        avatarPath:
        '',
        cargoId: 0,
        firmaMd5:
        '',
        verDiaSiguiente: false
      );

      Tecnico? tecnicoGuardado;
      
      if (widget.esEdicion) {
        tecnicoGuardado = await widget.tecnicosServices.putTecnico(
          context, 
          nuevoTecnico, 
          widget.token
        );
      } else {
        tecnicoGuardado = await widget.tecnicosServices.postTecnico(
          context, 
          nuevoTecnico, 
          widget.token
        );
      }

      if (!mounted) return;

      if (tecnicoGuardado != null) {
        if (widget.onTecnicoCreado != null) {
          widget.onTecnicoCreado!(tecnicoGuardado);
        }
        
        Navigator.of(context).pop(tecnicoGuardado);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} el técnico - Servicio retornó null'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isGuardando = false);
      }

    } catch (e) {
      print('Error ${widget.esEdicion ? 'editando' : 'creando'} técnico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} el técnico: $e'),
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
                    widget.esEdicion ? Icons.edit : Icons.engineering,
                    size: 28,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.esEdicion ? 'Editar Técnico' : 'Nuevo Técnico',
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
                    // Código técnico
                    TextFormField(
                      controller: _codigoController,
                      decoration: InputDecoration(
                        labelText: 'Código Técnico',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un código de técnico';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
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
                          return 'Por favor ingrese el nombre del técnico';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Documento
                    TextFormField(
                      controller: _documentoController,
                      decoration: InputDecoration(
                        labelText: 'Documento',
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
                          return 'Por favor ingrese el documento del técnico';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha Nacimiento
                    TextFormField(
                      controller: _fechaNacimientoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        prefixIcon: Icon(Icons.cake, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                      onTap: () {
                        _seleccionarFecha(context, (fecha) {
                          setState(() {
                            _fechaNacimiento = fecha;
                            _fechaNacimientoController.text = _formatearFecha(fecha);
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha Ingreso
                    TextFormField(
                      controller: _fechaIngresoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Ingreso',
                        prefixIcon: Icon(Icons.work, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                      onTap: () {
                        _seleccionarFecha(context, (fecha) {
                          setState(() {
                            _fechaIngreso = fecha;
                            _fechaIngresoController.text = _formatearFecha(fecha);
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha Vencimiento Carné Salud
                    TextFormField(
                      controller: _fechaVtoCarneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Vencimiento Carné de Salud',
                        prefixIcon: Icon(Icons.medical_services, color: colors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                      ),
                      onTap: () {
                        _seleccionarFecha(context, (fecha) {
                          setState(() {
                            _fechaVtoCarne = fecha;
                            _fechaVtoCarneController.text = _formatearFecha(fecha);
                          });
                        });
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
                    onPressed: _isGuardando ? null : _guardarTecnico,
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
                        : Text(widget.esEdicion ? 'Guardar Cambios' : 'Guardar Técnico'),
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