// dialogo_unidad.dart
import 'package:app_tec_sedel/models/marca.dart';
import 'package:app_tec_sedel/models/modelo.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/services/codigueras_services.dart';
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:flutter/material.dart';

class DialogoUnidad extends StatefulWidget {
  final Unidad? unidadExistente;
  final String token;
  final int? clienteId;
  final UnidadesServices unidadesServices;
  final CodiguerasServices codiguerasServices;
  final bool permitirBusquedaMatricula;

  const DialogoUnidad({
    super.key,
    this.unidadExistente,
    required this.token,
    this.clienteId,
    required this.unidadesServices,
    required this.codiguerasServices,
    this.permitirBusquedaMatricula = false,
  });

  @override
  DialogoUnidadState createState() => DialogoUnidadState();
}

class DialogoUnidadState extends State<DialogoUnidad> {
  final TextEditingController matriculaController = TextEditingController();
  final TextEditingController anioController = TextEditingController();
  final TextEditingController motorController = TextEditingController();
  final TextEditingController chasisController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController comentarioController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  bool consignado = false;
  bool averias = false;

  // Variables para los dropdowns
  List<Marca> _marcas = [];
  List<Modelo> modelos = [];
  Marca? marcaSeleccionada;
  Modelo? modeloSeleccionado;
  bool _cargandoMarcas = false;
  bool cargandoModelos = false;

  // Variable para búsqueda por matrícula
  Unidad? unidadEncontrada;
  bool buscandoUnidad = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cargarMarcas();
  }

  void _inicializarDatos() {
    if (widget.unidadExistente != null) {
      final unidad = widget.unidadExistente!;
      matriculaController.text = unidad.matricula;
      anioController.text = unidad.anio.toString();
      motorController.text = unidad.motor;
      chasisController.text = unidad.chasis;
      colorController.text = unidad.color;
      comentarioController.text = unidad.comentario;
      descripcionController.text = unidad.descripcion;
      consignado = unidad.consignado;
      averias = unidad.averias;
    }
  }

  Future<void> _cargarMarcas() async {
    if (_marcas.isNotEmpty) return;
    
    setState(() {
      _cargandoMarcas = true;
    });

    try {
      final listaMarcas = await widget.codiguerasServices.getMarcas(context, widget.token);
      setState(() {
        _marcas = listaMarcas;
        _cargandoMarcas = false;
      });

      // Si estamos editando, cargar la marca y modelo existentes
      if (widget.unidadExistente != null) {
        _cargarDatosExistentes();
      }
    } catch (e) {
      setState(() {
        _cargandoMarcas = false;
      });
    }
  }

  void _cargarDatosExistentes() {
    final unidad = widget.unidadExistente!;
    
    // Buscar la marca correspondiente
    final marcaExistente = _marcas.firstWhere(
      (marca) => marca.marcaId == unidad.marcaId,
      orElse: () => Marca(marcaId: 0, descripcion: '', paraVenta: false, orden: ''),
    );
    
    if (marcaExistente.marcaId != 0) {
      setState(() {
        marcaSeleccionada = marcaExistente;
      });
      _cargarModelos(marcaExistente.marcaId);
    }
  }

  Future<List<Modelo>> _cargarModelos(int marcaId) async {
    try {
      return await widget.codiguerasServices.getModelos(context, widget.token, marcaId: marcaId);
    } catch (e) {
      return [];
    }
  }

  Future<void> _cargarModelosParaMarca(Marca? marca, Function setStateBd) async {
    if (marca == null) return;
    
    setStateBd(() {
      cargandoModelos = true;
      modelos = [];
      modeloSeleccionado = null;
    });
    
    final listaModelos = await _cargarModelos(marca.marcaId);
    
    setStateBd(() {
      modelos = listaModelos;
      cargandoModelos = false;
      
      // Si estamos editando y la marca es la misma que la existente, seleccionar el modelo correspondiente
      if (widget.unidadExistente != null && marca.marcaId == widget.unidadExistente!.marcaId || unidadEncontrada != null && marca.marcaId == unidadEncontrada!.marcaId) {
        modeloSeleccionado = listaModelos.firstWhere(
          (modelo) => (modelo.modeloId == widget.unidadExistente?.modeloId || modelo.modeloId == unidadEncontrada?.modeloId),
          orElse: () => Modelo(
            modeloId: 0, 
            marcaId: 0, 
            descripcion: '', 
            paraVenta: false, 
            orden: '', 
            codMarca: '', 
            marca: ''
          ),
        );
      }
    });
  }

  // Función para buscar unidad por matrícula
  Future<void> _buscarUnidadPorMatricula() async {
    if (matriculaController.text.isEmpty) return;

    setState(() {
      buscandoUnidad = true;
    });

    try {
      final unidadesEncontradas = await widget.unidadesServices.getUnidades(
        context, 
        widget.token, 
        matricula: matriculaController.text
      );

      if (unidadesEncontradas.isNotEmpty) {
        unidadEncontrada = unidadesEncontradas.first;
        
        // Llenar automáticamente los campos con los datos encontrados
        matriculaController.text = unidadEncontrada!.matricula;
        anioController.text = unidadEncontrada!.anio.toString();
        motorController.text = unidadEncontrada!.motor;
        chasisController.text = unidadEncontrada!.chasis;
        colorController.text = unidadEncontrada!.color;
        descripcionController.text = unidadEncontrada!.descripcion;
        consignado = unidadEncontrada!.consignado;
        averias = unidadEncontrada!.averias;
        
        // Buscar y seleccionar marca y modelo
        if (unidadEncontrada!.marcaId != 0) {
          final marca = _marcas.firstWhere(
            (m) => m.marcaId == unidadEncontrada!.marcaId,
            orElse: () => Marca(marcaId: 0, descripcion: '', paraVenta: false, orden: ''),
          );
          if (marca.marcaId != 0) {
            marcaSeleccionada = marca;
            await _cargarModelosParaMarca(marca, setState);
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidad encontrada y cargada automáticamente')),
        );
      } else {
        unidadEncontrada = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró una unidad con esa matrícula')),
        );
      }
    } catch (e) {
      unidadEncontrada = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar la unidad: $e')),
      );
    } finally {
      setState(() {
        buscandoUnidad = false;
      });
    }
  }

  Future<void> _guardarUnidad(Function setStateBd) async {
    final esEdicion = widget.unidadExistente != null || unidadEncontrada != null;
    final unidadExistente = widget.unidadExistente ?? unidadEncontrada;
    
    final unidad = Unidad(
      unidadId: esEdicion ? unidadExistente!.unidadId : 0,
      itemId: esEdicion ? unidadExistente?.itemId : null,
      codItem: esEdicion ? (unidadExistente?.codItem.toString() ?? '') : '',
      descripcion: descripcionController.text,
      modeloId: modeloSeleccionado?.modeloId ?? (esEdicion ? unidadExistente!.modeloId : 0),
      codModelo: modeloSeleccionado?.codMarca ?? (esEdicion ? unidadExistente!.codModelo : ''),
      modelo: modeloSeleccionado?.descripcion ?? (esEdicion ? unidadExistente!.modelo : ''),
      marcaId: marcaSeleccionada?.marcaId ?? (esEdicion ? unidadExistente!.marcaId : 0),
      codMarca: marcaSeleccionada?.descripcion ?? (esEdicion ? unidadExistente!.codMarca : ''),
      marca: marcaSeleccionada?.descripcion ?? (esEdicion ? unidadExistente!.marca : ''),
      chasis: chasisController.text,
      motor: motorController.text,
      anio: int.parse(anioController.text),
      colorId: 1,
      color: colorController.text,
      consignado: consignado,
      averias: averias,
      matricula: matriculaController.text,
      km: esEdicion ? unidadExistente!.km : 0,
      comentario: comentarioController.text,
      recibidoPorId: 113,
      recibidoPor: esEdicion ? unidadExistente!.recibidoPor : '',
      transportadoPor: esEdicion ? unidadExistente!.transportadoPor : '',
      clienteId: widget.clienteId ?? (esEdicion ? unidadExistente!.clienteId : null),
      padron: esEdicion ? unidadExistente!.padron : '',
    );

    try {
      if (esEdicion || unidadEncontrada != null) {
        await widget.unidadesServices.editarUnidad(context, unidad, widget.token);
      } else {
        await widget.unidadesServices.crearUnidad(context, unidad, widget.token);
      }

      final status = await widget.unidadesServices.getStatusCode();
      if (status != 0) {
        Navigator.of(context).pop(unidad);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unidad ${esEdicion ? 'editada' : 'agregada'} correctamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      // Error manejado por el servicio
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final esEdicion = widget.unidadExistente != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setStateBd) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, size: 28, color: colors.primary),
                      const SizedBox(width: 12),
                      Text(
                        esEdicion ? 'Editar Unidad' : 'Nueva Unidad',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (widget.permitirBusquedaMatricula) ...[
                    _buildCampoBusquedaMatricula(setStateBd),
                    const SizedBox(height: 16),
                  ],
                  
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Matrícula
                        if (!widget.permitirBusquedaMatricula) ...[
                          TextFormField(
                            controller: matriculaController,
                            decoration: InputDecoration(
                              labelText: 'Matrícula',
                              prefixIcon: Icon(Icons.confirmation_number_outlined, color: colors.primary),
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
                                return 'Por favor ingrese la matrícula';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Descripción
                        TextFormField(
                          controller: descripcionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            prefixIcon: Icon(Icons.description, color: colors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),                        
                        // Dropdown de Marcas
                        DropdownButtonFormField<Marca>(
                          decoration: InputDecoration(
                            labelText: 'Marca',
                            prefixIcon: Icon(Icons.branding_watermark_outlined, color: colors.primary),
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
                          value: marcaSeleccionada,
                          items: [
                            const DropdownMenuItem<Marca>(
                              value: null,
                              child: Text('Seleccione una marca'),
                            ),
                            ..._marcas.map((Marca marca) {
                              return DropdownMenuItem<Marca>(
                                value: marca,
                                child: Text(marca.descripcion),
                              );
                            }),
                          ],
                          onChanged: _cargandoMarcas 
                              ? null 
                              : (Marca? nuevaMarca) async {
                                  await _cargarModelosParaMarca(nuevaMarca, setStateBd);
                                  setStateBd(() {
                                    marcaSeleccionada = nuevaMarca;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor seleccione una marca';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Dropdown de Modelos
                        DropdownButtonFormField<Modelo>(
                          decoration: InputDecoration(
                            labelText: 'Modelo',
                            prefixIcon: Icon(Icons.model_training_outlined, color: colors.primary),
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
                          value: modeloSeleccionado,
                          items: [
                            DropdownMenuItem<Modelo>(
                              value: null,
                              child: Text(cargandoModelos ? 'Cargando modelos...' : 'Seleccione un modelo'),
                            ),
                            ...modelos.map((Modelo modelo) {
                              return DropdownMenuItem<Modelo>(
                                value: modelo,
                                child: Text(modelo.descripcion),
                              );
                            }),
                          ],
                          onChanged: (marcaSeleccionada == null || cargandoModelos)
                              ? null
                              : (Modelo? nuevoModelo) {
                                  setStateBd(() {
                                    modeloSeleccionado = nuevoModelo;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor seleccione un modelo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Año
                        TextFormField(
                          controller: anioController,
                          decoration: InputDecoration(
                            labelText: 'Año',
                            prefixIcon: Icon(Icons.calendar_today_outlined, color: colors.primary),
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
                          controller: motorController,
                          decoration: InputDecoration(
                            labelText: 'Número de Motor',
                            prefixIcon: Icon(Icons.engineering_outlined, color: colors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.error, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                          // validator: (value) {
                          //   if (value == null || value.isEmpty) {
                          //     return 'Por favor ingrese el número de motor';
                          //   }
                          //   return null;
                          // },
                        ),
                        const SizedBox(height: 16),
                        
                        // Número de Chasis
                        TextFormField(
                          controller: chasisController,
                          decoration: InputDecoration(
                            labelText: 'Número de Chasis',
                            prefixIcon: Icon(Icons.build_outlined, color: colors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Color
                        // TextFormField(
                        //   controller: colorController,
                        //   decoration: InputDecoration(
                        //     labelText: 'Color',
                        //     prefixIcon: Icon(Icons.color_lens_outlined, color: colors.primary),
                        //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        //     focusedBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(12),
                        //       borderSide: BorderSide(color: colors.primary, width: 2),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 16),

                        // Checkboxes para Consignado y Averías
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Consignado'),
                                value: consignado,
                                onChanged: (value) {
                                  setStateBd(() {
                                    consignado = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Averías'),
                                value: averias,
                                onChanged: (value) {
                                  setStateBd(() {
                                    averias = value ?? false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Comentario
                        TextFormField(
                          controller: comentarioController,
                          decoration: InputDecoration(
                            labelText: 'Comentario (Opcional)',
                            prefixIcon: Icon(Icons.comment_outlined, color: colors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                          maxLines: 3,
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
                            await _guardarUnidad(setStateBd);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(esEdicion ? 'Actualizar Unidad' : 'Guardar Unidad'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCampoBusquedaMatricula(Function setStateBd) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Búsqueda por Matrícula',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: matriculaController,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  hintText: 'Ingrese matrícula para buscar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onError, width: 2),
                  ),
                  errorStyle: TextStyle(color: colors.onError),
                  suffixIcon: buscandoUnidad 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _buscarUnidadPorMatricula(),
                        ),
                ),
                onFieldSubmitted: (value) => _buscarUnidadPorMatricula(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la matrícula';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (unidadEncontrada != null) ...[
          const SizedBox(height: 8),
          Text(
            '✓ Unidad encontrada - Complete los datos restantes',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}