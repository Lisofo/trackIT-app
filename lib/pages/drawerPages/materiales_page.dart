// ignore_for_file: use_build_context_synchronously, avoid_init_to_null, void_checks, avoid_print, unused_local_variable

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/manuales_materiales.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialesPage extends StatefulWidget {
  const MaterialesPage({super.key});

  @override
  State<MaterialesPage> createState() => _MaterialesPageState();
}

class _MaterialesPageState extends State<MaterialesPage> {
  // =========================
  // VARIABLES DE ESTADO
  // =========================

  List<String> savedData = [];
  List<Materiales> materiales = [];
  List<MetodoAplicacion> metodosAplicacion = [];
  List<Lote> lotes = [];
  List<RevisionMaterial> revisionMaterialesList = [];
  List<ManualesMateriales> manuales = [];

  Materiales selectedMaterial = Materiales.empty();
  Orden orden = Orden.empty();

  String token = '';
  int marcaId = 0;

  final ScrollController _scrollController = ScrollController();
  final MaterialesServices _materialesServices = MaterialesServices();

  bool estaBuscando = false;
  bool borrando = false;
  bool cargoDatosCorrectamente = false;
  bool cargando = true;

  int? statusCodeRevision;

  // =========================
  // CICLO DE VIDA
  // =========================

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // =========================
  // CARGA INICIAL
  // =========================

  Future<void> cargarDatos() async {
    token = context.read<AuthProvider>().token;

    try {
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;

      materiales = await _materialesServices.getMateriales(context, token);

      if (orden.otRevisionId != 0) {
        revisionMaterialesList = await _materialesServices.getRevisionMateriales(context, orden, token);
      }

      cargoDatosCorrectamente = materiales.isNotEmpty;
    } catch (e) {
      cargoDatosCorrectamente = false;
    } finally {
      cargando = false;
      if (mounted) setState(() {});
    }
  }

  // =========================
  // DIALOGO AGREGAR / EDITAR
  // =========================

  Future<bool> _showMaterialDialog(
    BuildContext context, {
    Materiales? materialParaAgregar,
    RevisionMaterial? materialParaEditar,
  }) async {
    final bool esEdicion = materialParaEditar != null;

    final RevisionMaterial materialActual = materialParaEditar ??
      RevisionMaterial(
        otMaterialId: 0,
        ordenTrabajoId: orden.ordenTrabajoId!,
        otRevisionId: orden.otRevisionId!,
        cantidad: 0.0,
        comentario: '',
        ubicacion: '',
        areaCobertura: '',
        plagas: [],
        material: materialParaAgregar ?? Materiales.empty(),
        lote: Lote.empty(),
        metodoAplicacion: MetodoAplicacion.empty(),
      );

    // CONTROLADORES
    final TextEditingController cantidadController = TextEditingController(text: esEdicion ? materialActual.cantidad.toString() : '');
    final TextEditingController comentarioController = TextEditingController(text: esEdicion ? materialActual.comentario : '');

    // ESTADO LOCAL DEL DIALOGO (FIX CRÍTICO)
    Lote? selectedLoteLocal = esEdicion ? materialActual.lote : null;
    MetodoAplicacion? selectedMetodoLocal = esEdicion ? materialActual.metodoAplicacion : null;

    final bool resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: AlertDialog(
            surfaceTintColor: Colors.white,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nombre: ${materialActual.material.descripcion}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Unidad: ${materialActual.material.unidad}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    verManual(context, material: materialActual.material);
                  },
                  child: const Text(
                    'Ver Manuales',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('* Cantidad:'),
                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese la cantidad',
                  ),
                ),
                const SizedBox(height: 16),
                Text(lotes.isEmpty ? 'Lote:' : '* Lote:'),
                DropdownSearch<Lote>(
                  items: lotes,
                  selectedItem: selectedLoteLocal,
                  onChanged: (newValue) {
                    selectedLoteLocal = newValue;
                  },
                  itemAsString: (Lote lote) => lote.materialLoteId == 0 ? 'Sin lote' : lote.lote,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione un lote',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Método de Aplicación:'),
                DropdownSearch<MetodoAplicacion>(
                  items: metodosAplicacion,
                  selectedItem: selectedMetodoLocal,
                  onChanged: (newValue) {
                    selectedMetodoLocal = newValue;
                  },
                  itemAsString: (MetodoAplicacion metodo) => metodo.descripcion,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione un método (opcional)',
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Comentario:'),
                TextField(
                  controller: comentarioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese un comentario (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  final String cantidad = cantidadController.text;
                  final String comentario = comentarioController.text;
                  bool validacionExitosa = true;
                  String mensajeError = '';
                  if (cantidad.isEmpty || double.tryParse(cantidad) == null) {
                    validacionExitosa = false;
                    mensajeError = 'La cantidad es obligatoria y debe ser un número válido';
                  } else if (lotes.isNotEmpty && (selectedLoteLocal == null || selectedLoteLocal!.materialLoteId == 0)) {
                    validacionExitosa = false;
                    mensajeError = 'Debe seleccionar un lote';
                  }
                  if (!validacionExitosa) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error'),
                          content: Text(mensajeError),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            )
                          ],
                        );
                      },
                    );
                    return;
                  }
                  final RevisionMaterial revisionMaterialActualizada = RevisionMaterial(
                    otMaterialId: materialActual.otMaterialId,
                    ordenTrabajoId: orden.ordenTrabajoId!,
                    otRevisionId: orden.otRevisionId!,
                    cantidad: double.parse(cantidad),
                    comentario: comentario,
                    ubicacion: '',
                    areaCobertura: '',
                    plagas: [],
                    material: materialActual.material,
                    lote: selectedLoteLocal ?? Lote.empty(),
                    metodoAplicacion: selectedMetodoLocal ?? MetodoAplicacion.empty(),
                  );
                  final List<int> plagasIds = [];
                  if (esEdicion) {
                    await _materialesServices.putRevisionMaterial(
                      context,
                      orden,
                      plagasIds,
                      revisionMaterialActualizada,
                      token,
                    );
                  } else {
                    await _materialesServices.postRevisionMaterial(
                      context,
                      orden,
                      plagasIds,
                      revisionMaterialActualizada,
                      token,
                    );
                  }
                  statusCodeRevision = await _materialesServices.getStatusCode();
                  await _materialesServices.resetStatusCode();
                  if (statusCodeRevision == 1) {
                    if (mounted) {
                      setState(() {
                        if (esEdicion) {
                          final index = revisionMaterialesList.indexWhere((rm) => rm.otMaterialId == materialActual.otMaterialId,
                          );
                          if (index != -1) {
                            revisionMaterialesList[index] = revisionMaterialActualizada;
                          }
                        } else {
                          revisionMaterialesList.add(revisionMaterialActualizada);
                        }
                      });
                    }
                    Navigator.of(context).pop(true);
                  } else {
                    Navigator.of(context).pop(false);
                  }
                },
              ),
            ],
          ),
        );
      },
    ) ??
    false;

    // Después del diálogo, siempre establecer a false
    if (mounted) {
      setState(() {
        estaBuscando = false;
      });
    }

    return resultado;
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${orden.ordenTrabajoId} - Materiales',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: colors.primary,
        ),
        backgroundColor: Colors.grey.shade200,
        body: cargando
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Text('Cargando, por favor espere...')
                  ],
                ),
              )
            : !cargoDatosCorrectamente
                ? Center(
                    child: TextButton.icon(
                      onPressed: cargarDatos,
                      icon: const Icon(Icons.replay_outlined),
                      label: const Text('Recargar'),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: colors.primary,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: DropdownSearch<Materiales>(
                            enabled: !estaBuscando,
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              textAlignVertical:
                                  TextAlignVertical.center,
                              dropdownSearchDecoration:
                                  InputDecoration(
                                hintText: 'Seleccione un material',
                              ),
                            ),
                            items: materiales,
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: Duration.zero,
                            ),
                            onChanged: (newValue) async {
                              if (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No puede de ingresar o editar datos.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                selectedMaterial = newValue!;
                                estaBuscando = true;
                              });

                              try {
                                lotes = await _materialesServices.getLotes(
                                  context,
                                  selectedMaterial.materialId,
                                  token,
                                );
                                metodosAplicacion = await _materialesServices.getMetodosAplicacion(
                                  context,
                                  token,
                                );
                              } catch (e) {
                                lotes = [];
                                metodosAplicacion = [];
                              }

                              if (mounted) {
                                setState(() {
                                  estaBuscando = false;
                                });
                              }

                              if (metodosAplicacion.isNotEmpty) {
                                final resultado = await _showMaterialDialog(
                                  context,
                                  materialParaAgregar: selectedMaterial,
                                );
                                if (mounted) {
                                  setState(() {
                                    estaBuscando = false;
                                  });
                                }
                              } else {
                                if (mounted) {
                                  setState(() {
                                    estaBuscando = false;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Materiales Utilizados:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.separated(
                                  controller: _scrollController,
                                  itemCount: revisionMaterialesList.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    thickness: 2,
                                    color: Colors.green,
                                  ),
                                  itemBuilder: (context, i) {
                                    final item = revisionMaterialesList[i];
                                    return Dismissible(
                                      key: Key(item.otMaterialId.toString()),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (DismissDirection direction) async {
                                        if (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO') {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No puede de ingresar o editar datos.',
                                              ),
                                            ),
                                          );
                                          return false;
                                        }

                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              surfaceTintColor:Colors.white,
                                              title: const Text("Confirmar"),
                                              content: const Text(
                                                "¿Estas seguro de querer borrar el material?",
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text("CANCELAR"),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    await _materialesServices.deleteRevisionMaterial(
                                                      context,
                                                      orden,
                                                      revisionMaterialesList[i],
                                                      token,
                                                    );

                                                    statusCodeRevision = await _materialesServices.getStatusCode();
                                                    await _materialesServices.resetStatusCode();

                                                    if (statusCodeRevision == 1) {
                                                      Navigator.of(context).pop(true);
                                                    }
                                                  },
                                                  child: const Text("BORRAR"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      onDismissed: (_) {
                                        if (statusCodeRevision == 1) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'El material ${item.material.descripcion} ha sido borrado',
                                              ),
                                            ),
                                          );

                                          setState(() {
                                            revisionMaterialesList.removeAt(i);
                                          });
                                        }
                                        statusCodeRevision = null;
                                      },
                                      background: Container(
                                        color: Colors.red,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        alignment: AlignmentDirectional.centerEnd,
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      child: Card(
                                        surfaceTintColor:Colors.white,
                                        child: ListTile(
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: !estaBuscando ? () async {
                                                  if (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO') {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('No puede ingresar o editar datos.',),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  setState(() {
                                                    estaBuscando = true;
                                                  });

                                                  try {
                                                    lotes = await _materialesServices.getLotes(
                                                      context,
                                                      item.material.materialId,
                                                      token,
                                                    );
                                                    metodosAplicacion = await _materialesServices.getMetodosAplicacion(
                                                      context,
                                                      token,
                                                    );
                                                  } catch (e) {
                                                    lotes = [];
                                                    metodosAplicacion = [];
                                                  }

                                                  if (mounted) {
                                                    setState(() {
                                                      estaBuscando = false;
                                                    });
                                                  }

                                                  if (lotes.isNotEmpty && metodosAplicacion.isNotEmpty) {
                                                    final resultado = await _showMaterialDialog(context, materialParaEditar: item,);
                                                    if (mounted) {
                                                      setState(() {
                                                        estaBuscando = false;
                                                      });
                                                    }
                                                  } else {
                                                    if (mounted) {
                                                      setState(() {
                                                        estaBuscando = false;
                                                      });
                                                    }
                                                  }
                                                } : null,
                                                icon: const Icon(Icons.edit),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  if (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO') {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'No puede de ingresar o editar datos.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  deleteMaterial(context, i);
                                                },
                                                icon: const Icon(Icons.delete),
                                              ),
                                            ],
                                          ),
                                          title: Column(
                                            crossAxisAlignment:CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Material: ${item.material.descripcion}',
                                              ),
                                              Text(
                                                'Unidad: ${item.material.unidad}',
                                              ),
                                              Text(
                                                'Cantidad: ${item.cantidad}',
                                              ),
                                              Text(
                                                'Lote: ${item.lote?.lote ?? "Sin lote"}',
                                              ),
                                              Text(
                                                'Método de aplicación: ${item.metodoAplicacion.descripcion}',
                                              ),
                                              Text(
                                                'Comentario: ${item.comentario}',
                                              ),
                                            ],
                                          ),
                                          onLongPress: () async {
                                            await verManual(
                                              context,
                                              material: item.material,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // =========================
  // BORRADO MANUAL
  // =========================

  void deleteMaterial(BuildContext context, int i) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text("Confirmar"),
          content: const Text("¿Estas seguro de querer borrar el material?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCELAR"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                if (borrando) return;

                borrando = true;

                await _materialesServices.deleteRevisionMaterial(
                  context,
                  orden,
                  revisionMaterialesList[i],
                  token,
                );

                statusCodeRevision = await _materialesServices.getStatusCode();
                await _materialesServices.resetStatusCode();

                if (statusCodeRevision == 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'El material ${revisionMaterialesList[i].material.descripcion} ha sido borrado',
                      ),
                    ),
                  );

                  setState(() {
                    revisionMaterialesList.removeAt(i);
                  });

                  router.pop();
                }

                statusCodeRevision = null;
                borrando = false;
              },
              child: const Text("BORRAR"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // MANUALES
  // =========================

  Future<void> verManual(
    BuildContext context, {
    RevisionMaterial? item,
    Materiales? material,
  }) async {
    try {
      manuales = material == null
        ? await _materialesServices.getManualesMateriales(
            context,
            item!.material.materialId,
            token,
          )
        : await _materialesServices.getManualesMateriales(
            context,
            material.materialId,
            token,
          );
    } catch (e) {
      print(e);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manuales'),
          content: SizedBox(
            height: 400,
            width: MediaQuery.of(context).size.width * 0.6,
            child: ListView.builder(
              itemCount: manuales.length,
              itemBuilder: (context, i) {
                final manual = manuales[i];
                return ListTile(
                  title: Text(manual.filename),
                  onTap: () {
                    launchURL(manual.filepath, token);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CERRAR"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // HELPERS
  // =========================

  bool esNumerico(String str) {
    return double.tryParse(str) != null;
  }

  Future<void> launchURL(String url, String token) async {
    final Dio dio = Dio();
    final String link = '$url?authorization=$token';

    try {
      final Response response = await dio.get(
        link,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final Uri uri = Uri.parse(link);
        await launchUrl(uri);
      } else {
        print('Error al cargar la URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
    }
  }
}