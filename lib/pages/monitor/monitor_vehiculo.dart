// monitor_vehiculo.dart
import 'package:app_tec_sedel/models/marca.dart';
import 'package:app_tec_sedel/models/modelo.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/codigueras_services.dart';
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorVehiculos extends StatefulWidget {
  const MonitorVehiculos({super.key});

  @override
  MonitorVehiculosState createState() => MonitorVehiculosState();
}

class MonitorVehiculosState extends State<MonitorVehiculos> {
  
  List<Unidad> unidades = [];
  List<Unidad> unidadesFiltradas = [];
  TextEditingController searchController = TextEditingController();
  final UnidadesServices _unidadesServices = UnidadesServices();
  final CodiguerasServices _codiguerasServices = CodiguerasServices();
  late String token = '';
  bool _isLoading = true;

  // Variables para marcas y modelos (se cargan al iniciar)
  List<Marca> _marcas = [];
  bool _cargandoMarcas = false;

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
    _cargarMarcas(); // Cargar marcas al iniciar la pantalla
    searchController.addListener(_filtrarUnidades);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarUnidades() async {
    token = context.read<OrdenProvider>().token;
    try {
      final listaUnidades = await _unidadesServices.getUnidades(context, token);
      
      setState(() {
        unidades = listaUnidades;
        unidadesFiltradas = unidades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // El error ya fue manejado por Carteles().errorManagment en el servicio
    }
  }

  Future<void> _cargarMarcas() async {
    if (_marcas.isNotEmpty) return; // Ya están cargadas
    
    setState(() {
      _cargandoMarcas = true;
    });

    try {
      final listaMarcas = await _codiguerasServices.getMarcas(context, token);
      setState(() {
        _marcas = listaMarcas;
        _cargandoMarcas = false;
      });
    } catch (e) {
      setState(() {
        _cargandoMarcas = false;
      });
    }
  }

  Future<List<Modelo>> _cargarModelos(int marcaId) async {
    try {
      return await _codiguerasServices.getModelos(context, token, marcaId: marcaId);
    } catch (e) {
      return [];
    }
  }

  void _filtrarUnidades() {
    final query = searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        unidadesFiltradas = unidades;
      });
      return;
    }

    setState(() {
      unidadesFiltradas = unidades.where((unidad) {
        return unidad.marca.toLowerCase().contains(query) ||
            (unidad.matricula.toLowerCase().contains(query)) ||
            unidad.modelo.toLowerCase().contains(query) ||
            unidad.anio.toString().contains(query) ||
            unidad.motor.toLowerCase().contains(query) ||
            unidad.chasis.toLowerCase().contains(query) ||
            unidad.descripcion.toLowerCase().contains(query) ||
            unidad.codItem.toLowerCase().contains(query) ||
            _getDisplayInfo(unidad).toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getDisplayInfo(Unidad unidad) {
    return '${unidad.marca} ${unidad.modelo} - ${unidad.matricula}';
  }

  // Método reutilizable para crear/editar unidad
  void _mostrarDialogoUnidad(BuildContext context, {Unidad? unidadExistente}) {
    final bool esEdicion = unidadExistente != null;
    
    final matriculaController = TextEditingController(text: unidadExistente?.matricula ?? '');
    final anioController = TextEditingController(text: unidadExistente?.anio.toString() ?? '');
    final motorController = TextEditingController(text: unidadExistente?.motor ?? '');
    final chasisController = TextEditingController(text: unidadExistente?.chasis ?? '');
    final colorController = TextEditingController(text: unidadExistente?.color ?? '');
    final comentarioController = TextEditingController(text: unidadExistente?.comentario ?? '');
    final descripcionController = TextEditingController(text: unidadExistente?.descripcion ?? '');
    
    bool consignado = unidadExistente?.consignado ?? false;
    bool averias = unidadExistente?.averias ?? false;

    // Variables para los dropdowns
    List<Modelo> modelos = [];
    Marca? marcaSeleccionada;
    Modelo? modeloSeleccionado;
    bool cargandoModelos = false;

    // Si es edición, cargar la marca y modelo existentes
    if (esEdicion) {
      // Buscar la marca correspondiente
      marcaSeleccionada = _marcas.firstWhere(
        (marca) => marca.marcaId == unidadExistente.marcaId,
        orElse: () => Marca(
          marcaId: 0, 
          descripcion: '', 
          paraVenta: false, 
          orden: ''
        ),
      );
      
      // Cargar modelos para la marca seleccionada
      if (marcaSeleccionada.marcaId != 0) {
        _cargarModelos(marcaSeleccionada.marcaId).then((listaModelos) {
          modelos = listaModelos;
          // Buscar el modelo correspondiente
          modeloSeleccionado = listaModelos.firstWhere(
            (modelo) => modelo.modeloId == unidadExistente.modeloId,
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
        });
      }
    }

    final formKey = GlobalKey<FormState>();
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) {
            // Función para cargar modelos cuando se selecciona una marca
            Future<void> cargarModelosParaMarca(Marca? marca) async {
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
                if (esEdicion && marca.marcaId == unidadExistente.marcaId) {
                  modeloSeleccionado = listaModelos.firstWhere(
                    (modelo) => modelo.modeloId == unidadExistente.modeloId,
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

            // Cargar modelos inicialmente si estamos editando y ya tenemos una marca seleccionada
            if (esEdicion && marcaSeleccionada != null && marcaSeleccionada!.marcaId != 0 && modelos.isEmpty) {
              cargarModelosParaMarca(marcaSeleccionada);
            }

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
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
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
                              // validator: (value) {
                              //   if (value == null || value.isEmpty) {
                              //     return 'Por favor ingrese la descripción';
                              //   }
                              //   return null;
                              // },
                            ),
                            const SizedBox(height: 16),

                            // Matrícula (opcional)
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
                            ),
                            const SizedBox(height: 16),
                            
                            // Dropdown de Marcas
                            DropdownButtonFormField<Marca>(
                              decoration: InputDecoration(
                                labelText: 'Marca',
                                prefixIcon: Icon(Icons.branding_watermark_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              value: marcaSeleccionada,
                              items: [
                                // Opción vacía inicial
                                const DropdownMenuItem<Marca>(
                                  value: null,
                                  child: Text('Seleccione una marca'),
                                ),
                                // Opciones de marcas (usando las ya cargadas)
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
                                      await cargarModelosParaMarca(nuevaMarca);
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
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                              value: modeloSeleccionado,
                              items: [
                                // Opción vacía inicial
                                DropdownMenuItem<Modelo>(
                                  value: null,
                                  child: Text(cargandoModelos ? 'Cargando modelos...' : 'Seleccione un modelo'),
                                ),
                                // Opciones de modelos
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
                            TextFormField(
                              controller: colorController,
                              decoration: InputDecoration(
                                labelText: 'Color',
                                prefixIcon: Icon(Icons.color_lens_outlined, color: colors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

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
                                // Crear nueva unidad con los campos actualizados
                                final unidad = Unidad(
                                  unidadId: esEdicion ? unidadExistente.unidadId : 0,
                                  itemId: esEdicion ? unidadExistente.itemId : null,
                                  codItem: esEdicion ? unidadExistente.codItem : '',
                                  descripcion: descripcionController.text,
                                  modeloId: modeloSeleccionado?.modeloId ?? 0,
                                  codModelo: modeloSeleccionado?.codMarca ?? '',
                                  modelo: modeloSeleccionado?.descripcion ?? '',
                                  marcaId: marcaSeleccionada?.marcaId ?? 0,
                                  codMarca: marcaSeleccionada?.descripcion ?? '',
                                  marca: marcaSeleccionada?.descripcion ?? '',
                                  chasis: chasisController.text,
                                  motor: motorController.text,
                                  anio: int.parse(anioController.text),
                                  colorId: 1,
                                  color: colorController.text,
                                  consignado: consignado,
                                  averias: averias,
                                  matricula: matriculaController.text,
                                  km: esEdicion ? unidadExistente.km : 0,
                                  comentario: comentarioController.text,
                                  recibidoPorId: 113,
                                  recibidoPor: esEdicion ? unidadExistente.recibidoPor : '',
                                  transportadoPor: esEdicion ? unidadExistente.transportadoPor : '',
                                  clienteId: esEdicion ? unidadExistente.clienteId : null,
                                  padron: esEdicion ? unidadExistente.padron : '',
                                );

                                if (esEdicion) {
                                  await _unidadesServices.editarUnidad(context, unidad, token);
                                } else {
                                  await _unidadesServices.crearUnidad(context, unidad, token);
                                }
                                
                                final status = await _unidadesServices.getStatusCode();
                                if (status == 0) {
                                  // Error al crear/editar unidad
                                  return;
                                } else {
                                  await _cargarUnidades();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Unidad ${esEdicion ? 'editada' : 'agregada'} correctamente'),
                                      backgroundColor: colors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );
                                }
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
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoNuevaUnidad(BuildContext context) {
    _mostrarDialogoUnidad(context);
  }

  void _editarUnidad(Unidad unidad) {
    _mostrarDialogoUnidad(context, unidadExistente: unidad);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                  child: unidadesFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_outlined, size: 64, color: colors.onSurface.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                unidades.isEmpty ? 'No hay vehículos registrados' : 'No se encontraron resultados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              if (unidades.isEmpty) 
                                TextButton(
                                  onPressed: _cargarUnidades,
                                  child: Text('Reintentar', style: TextStyle(color: colors.primary)),
                                ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: unidadesFiltradas.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: colors.outline.withOpacity(0.3)),
                          itemBuilder: (context, index) {
                            final unidad = unidadesFiltradas[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  _getDisplayInfo(unidad),
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
                                      'Año: ${unidad.anio}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Motor: ${unidad.motor}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Chasis: ${unidad.chasis}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    if (unidad.color.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Color: ${unidad.color}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                    if (unidad.descripcion.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Descripción: ${unidad.descripcion}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                    if (unidad.codItem.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Código: ${unidad.codItem}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colors.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                    if (unidad.consignado) ...[
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Consignado: Sí',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (unidad.averias) ...[
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Averías: Sí',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: colors.primary.withOpacity(0.2),
                                  child: Text(
                                    unidad.marca.isNotEmpty ? unidad.marca[0] : 'V',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _editarUnidad(unidad);
                                      },
                                      icon: const Icon(Icons.edit, color: Colors.blue,)
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.delete, color: Colors.red,)
                                    )
                                  ],
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
          _mostrarDialogoNuevaUnidad(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }
}