// dialogo_tarea.dart
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';

class DialogoTarea extends StatefulWidget {
  final TareasServices tareasServices;
  final String token;
  final Function(Tarea)? onTareaCreada;
  final bool esEdicion;
  final Tarea? tareaEditar;

  const DialogoTarea({
    super.key,
    required this.tareasServices,
    required this.token,
    this.onTareaCreada,
    this.esEdicion = false,
    this.tareaEditar,
  });

  @override
  State<DialogoTarea> createState() => _DialogoTareaState();
}

class _DialogoTareaState extends State<DialogoTarea> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosTareaExistente();
  }

  void _cargarDatosTareaExistente() {
    if (widget.esEdicion && widget.tareaEditar != null) {
      final tarea = widget.tareaEditar!;
      _codigoController.text = tarea.codTarea;
      _descripcionController.text = tarea.descripcion;
    }
  }

  Future<void> _guardarTarea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGuardando = true);

    try {
      final nuevaTarea = Tarea(
        tareaId: widget.esEdicion ? widget.tareaEditar!.tareaId : 0,
        codTarea: _codigoController.text,
        descripcion: _descripcionController.text,
      );

      Tarea? tareaGuardada;
      
      if (widget.esEdicion) {
        tareaGuardada = await widget.tareasServices.putTarea(
          context, 
          nuevaTarea, 
          widget.token
        );
      } else {
        tareaGuardada = await widget.tareasServices.postTarea(
          context, 
          nuevaTarea, 
          widget.token
        );
      }

      if (!mounted) return;

      if (tareaGuardada != null) {
        if (widget.onTareaCreada != null) {
          widget.onTareaCreada!(tareaGuardada);
        }
        
        Navigator.of(context).pop(tareaGuardada);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} la tarea - Servicio retornó null'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isGuardando = false);
      }

    } catch (e) {
      print('Error ${widget.esEdicion ? 'editando' : 'creando'} tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} la tarea: $e'),
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
                    widget.esEdicion ? Icons.edit : Icons.task,
                    size: 28,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.esEdicion ? 'Editar Tarea' : 'Nueva Tarea',
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
                    // Código tarea
                    TextFormField(
                      controller: _codigoController,
                      decoration: InputDecoration(
                        labelText: 'Código Tarea',
                        prefixIcon: Icon(Icons.code, color: colors.primary),
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
                          return 'Por favor ingrese un código de tarea';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description, color: colors.primary),
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
                          return 'Por favor ingrese la descripción de la tarea';
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
                    onPressed: _isGuardando ? null : _guardarTarea,
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
                        : Text(widget.esEdicion ? 'Guardar Cambios' : 'Guardar Tarea'),
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