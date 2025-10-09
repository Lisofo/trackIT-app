// dialogo_material.dart
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';

class DialogoMaterial extends StatefulWidget {
  final MaterialesServices materialesServices;
  final String token;
  final Function(Materiales)? onMaterialCreado;
  final bool esEdicion;
  final Materiales? materialEditar;

  const DialogoMaterial({
    super.key,
    required this.materialesServices,
    required this.token,
    this.onMaterialCreado,
    this.esEdicion = false,
    this.materialEditar,
  });

  @override
  State<DialogoMaterial> createState() => _DialogoMaterialState();
}

class _DialogoMaterialState extends State<DialogoMaterial> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fabProvController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;
  String _enAppTecnico = 'S';
  String _enUso = 'S';

  @override
  void initState() {
    super.initState();
    _cargarDatosMaterialExistente();
  }

  void _cargarDatosMaterialExistente() {
    if (widget.esEdicion && widget.materialEditar != null) {
      final material = widget.materialEditar!;
      _codigoController.text = material.codMaterial;
      _descripcionController.text = material.descripcion;
      _fabProvController.text = material.fabProv;
      _enAppTecnico = material.enAppTecnico;
      _enUso = material.enUso;
    }
  }

  Future<void> _guardarMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGuardando = true);

    try {
      final nuevoMaterial = Materiales(
        materialId: widget.esEdicion ? widget.materialEditar!.materialId : 0,
        codMaterial: _codigoController.text,
        descripcion: _descripcionController.text,
        dosis: '',
        unidad: '',
        fabProv: _fabProvController.text,
        enAppTecnico: _enAppTecnico,
        enUso: _enUso,
      );

      Materiales? materialGuardado;
      
      if (widget.esEdicion) {
        materialGuardado = await widget.materialesServices.putMaterial(
          context, 
          nuevoMaterial, 
          widget.token
        );
      } else {
        materialGuardado = await widget.materialesServices.postMaterial(
          context, 
          nuevoMaterial, 
          widget.token
        );
      }

      if (!mounted) return;

      if (materialGuardado != null) {
        if (widget.onMaterialCreado != null) {
          widget.onMaterialCreado!(materialGuardado);
        }
        
        Navigator.of(context).pop(materialGuardado);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} el material - Servicio retornó null'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isGuardando = false);
      }

    } catch (e) {
      print('Error ${widget.esEdicion ? 'editando' : 'creando'} material: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${widget.esEdicion ? 'editar' : 'crear'} el material: $e'),
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
                    widget.esEdicion ? Icons.edit : Icons.inventory_2,
                    size: 28,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.esEdicion ? 'Editar Material' : 'Nuevo Material',
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
                    // Código material
                    TextFormField(
                      controller: _codigoController,
                      decoration: InputDecoration(
                        labelText: 'Código Material',
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
                          return 'Por favor ingrese un código de material';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 1,
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
                          return 'Por favor ingrese la descripción del material';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // En App Técnico
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _enAppTecnico,
                        decoration: InputDecoration(
                          labelText: 'Disponible en App',
                          prefixIcon: Icon(Icons.phone_android, color: colors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'S',
                            child: Text('Sí'),
                          ),
                          DropdownMenuItem(
                            value: 'N',
                            child: Text('No'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _enAppTecnico = newValue ?? 'S';
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // En Uso
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _enUso,
                        decoration: InputDecoration(
                          labelText: 'En Uso',
                          prefixIcon: Icon(Icons.build, color: colors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'S',
                            child: Text('Sí'),
                          ),
                          DropdownMenuItem(
                            value: 'N',
                            child: Text('No'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _enUso = newValue ?? 'S';
                          });
                        },
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
                    onPressed: _isGuardando ? null : _guardarMaterial,
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
                        : Text(widget.esEdicion ? 'Guardar Cambios' : 'Guardar Material'),
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