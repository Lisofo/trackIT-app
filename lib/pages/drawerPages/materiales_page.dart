// ignore_for_file: use_build_context_synchronously, avoid_init_to_null, void_checks, avoid_print

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
  late List<String> savedData = [];
  List<Materiales> materiales = [];
  List<MetodoAplicacion> metodosAplicacion = [];
  late List<Lote> lotes = [];
  late List<RevisionMaterial> revisionMaterialesList = [];
  late Materiales selectedMaterial = Materiales.empty();
  late Lote? selectedLote = Lote.empty();
  late String cantidad = '';
  late String comentario = ''; // Cambiado de ubicacion a comentario
  late MetodoAplicacion? selectedMetodo;
  late String token = '';
  late Materiales? materialInicial = null;
  late Orden orden = Orden.empty();
  final ScrollController _scrollController = ScrollController();
  late int marcaId = 0;
  late List<ManualesMateriales> manuales = [];
  bool estaBuscando = false;
  bool borrando = false;
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  int? statusCodeRevision;
  final _materialesServices = MaterialesServices();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    try {
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      materiales = await _materialesServices.getMateriales(context, token);
      if (orden.otRevisionId != 0) {
        revisionMaterialesList = await _materialesServices.getRevisionMateriales(context, orden, token);
      }
      if (materiales.isNotEmpty) {
        cargoDatosCorrectamente = true;
      }
      cargando = false;
    } catch (e) {
      cargando = false;
    }

    setState(() {});
  }

  // Método unificado para mostrar el diálogo de materiales (agregar/editar)
  Future<bool> _showMaterialDialog(BuildContext context, {Materiales? materialParaAgregar, RevisionMaterial? materialParaEditar}) async {
    
    bool esEdicion = materialParaEditar != null;
    RevisionMaterial materialActual = materialParaEditar ?? 
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
        metodoAplicacion: MetodoAplicacion.empty()
      );

    // Inicializar controladores con valores existentes si es edición
    final TextEditingController cantidadController = TextEditingController(text: esEdicion ? materialActual.cantidad.toString() : '');
    final TextEditingController comentarioController = TextEditingController(text: esEdicion ? materialActual.comentario : '');
    
    selectedLote = esEdicion ? materialActual.lote : Lote.empty();
    selectedMetodo = esEdicion ? materialActual.metodoAplicacion : null;

    bool resultado = await showDialog(
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
                  child: const Text('Ver Manuales',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline
                    )
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
                  selectedItem: esEdicion ? materialActual.lote : null,
                  onChanged: (newValue) {
                    selectedLote = newValue;
                  },
                  itemAsString: (Lote lote) => lote.materialLoteId == 0 ? 'Sin lote' : lote.lote,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione un lote',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Método de Aplicación:'), // Ya no es obligatorio
                DropdownSearch<MetodoAplicacion>(
                  items: metodosAplicacion,
                  selectedItem: esEdicion ? materialActual.metodoAplicacion : null,
                  onChanged: (newValue) {
                    selectedMetodo = newValue;
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
                  cantidad = cantidadController.text;
                  comentario = comentarioController.text;

                  // Validaciones
                  bool validacionExitosa = true;
                  String mensajeError = '';

                  if (cantidad.isEmpty || !esNumerico(cantidad)) {
                    validacionExitosa = false;
                    mensajeError = 'La cantidad es obligatoria y debe ser un número válido';
                  } else if (lotes.isNotEmpty && (selectedLote == null || selectedLote!.materialLoteId == 0)) {
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
                              child: const Text('Cerrar')
                            )
                          ],
                        );
                      },
                    );
                    return;
                  }

                  // Crear/actualizar el objeto RevisionMaterial
                  final RevisionMaterial revisionMaterialActualizada =
                      RevisionMaterial(
                    otMaterialId: esEdicion ? materialActual.otMaterialId : 0,
                    ordenTrabajoId: orden.ordenTrabajoId!,
                    otRevisionId: orden.otRevisionId!,
                    cantidad: double.parse(cantidad),
                    comentario: comentario,
                    ubicacion: '', // Campo vacío como se solicitó
                    areaCobertura: '', // Campo vacío como se solicitó
                    plagas: [],
                    material: materialActual.material,
                    lote: selectedLote ?? Lote.empty(),
                    metodoAplicacion: selectedMetodo ?? MetodoAplicacion.empty(),
                  );

                  late List<int> plagasIds = [];

                  if (esEdicion) {
                    await _materialesServices.putRevisionMaterial(context, orden, plagasIds, revisionMaterialActualizada, token);
                  } else {
                    await _materialesServices.postRevisionMaterial(context, orden, plagasIds, revisionMaterialActualizada, token);
                  }

                  statusCodeRevision = await _materialesServices.getStatusCode();
                  await _materialesServices.resetStatusCode();

                  if (statusCodeRevision == 1) {
                    if (!esEdicion) {
                      revisionMaterialActualizada.otMaterialId = 
                          revisionMaterialActualizada.otMaterialId;
                      revisionMaterialesList.add(revisionMaterialActualizada);
                    } else {
                      // Actualizar el elemento en la lista
                      int index = revisionMaterialesList.indexWhere((rm) => rm.otMaterialId == materialActual.otMaterialId);
                      if (index != -1) {
                        revisionMaterialesList[index] = revisionMaterialActualizada;
                      }
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
    );

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (selectedMaterial.materialId != 0 && materiales.isNotEmpty) {
      materialInicial = materiales.firstWhere(
          (material) => material.materialId == selectedMaterial.materialId);
    }

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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      onPressed: () async {
                        await cargarDatos();
                      },
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
                              border: Border.all(width: 2, color: colors.primary),
                              borderRadius: BorderRadius.circular(5)),
                          child: DropdownSearch(
                            enabled: !estaBuscando,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                                textAlignVertical: TextAlignVertical.center,
                                dropdownSearchDecoration: InputDecoration(
                                  hintText: 'Seleccione un material',
                                )),
                            items: materiales,
                            popupProps: const PopupProps.menu(
                                showSearchBox: true, searchDelay: Duration.zero),
                            onChanged: (newValue) async {
                              if ((orden.estado == 'PENDIENTE' ||
                                  orden.estado == 'FINALIZADA')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No puede de ingresar o editar datos.')));
                                return Future.value(false);
                              }
                              setState(() {
                                selectedMaterial = newValue!;
                                estaBuscando = true;
                              });
                              try {
                                lotes = await MaterialesServices()
                                    .getLotes(context, selectedMaterial.materialId, token);
                                metodosAplicacion = await MaterialesServices()
                                    .getMetodosAplicacion(context, token);
                              } catch (e) {
                                lotes = [];
                                metodosAplicacion = [];
                                estaBuscando = false;
                                setState(() {});
                              }
                              if (metodosAplicacion.isNotEmpty) {
                                bool resultado = await _showMaterialDialog(context,
                                    materialParaAgregar: selectedMaterial);
                                setState(() {
                                  estaBuscando = resultado;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(5)),
                                height: 30,
                                child: const Center(
                                  child: Text(
                                    'Materiales Utilizados:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.separated(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  controller: _scrollController,
                                  itemCount: revisionMaterialesList.length,
                                  itemBuilder: (context, i) {
                                    final item = revisionMaterialesList[i];
                                    return Dismissible(
                                      key: Key(item.otMaterialId.toString()),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss:
                                          (DismissDirection direction) async {
                                        if ((orden.estado == 'PENDIENTE' ||
                                            orden.estado == 'FINALIZADA')) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'No puede de ingresar o editar datos.'),
                                          ));
                                          return Future.value(false);
                                        }
                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              surfaceTintColor: Colors.white,
                                              title: const Text("Confirmar"),
                                              content: const Text(
                                                  "¿Estas seguro de querer borrar el material?"),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context).pop(false),
                                                  child: const Text("CANCELAR"),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    await _materialesServices
                                                        .deleteRevisionMaterial(
                                                            context,
                                                            orden,
                                                            revisionMaterialesList[i],
                                                            token);
                                                    statusCodeRevision =
                                                        await _materialesServices
                                                            .getStatusCode();
                                                    await _materialesServices
                                                        .resetStatusCode();
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
                                      onDismissed: (direction) {
                                        if (statusCodeRevision == 1) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'El material ${item.material.descripcion} ha sido borrado')));
                                          setState(() {
                                            revisionMaterialesList.removeAt(i);
                                          });
                                        }
                                        statusCodeRevision = null;
                                      },
                                      background: Container(
                                        color: Colors.red,
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 20),
                                        alignment: AlignmentDirectional.centerEnd,
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      child: Card(
                                        surfaceTintColor: Colors.white,
                                        child: ListTile(
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                  onPressed: !estaBuscando
                                                      ? () async {
                                                          estaBuscando = true;
                                                          setState(() {});
                                                          if ((orden.estado ==
                                                                  'PENDIENTE' ||
                                                              orden.estado ==
                                                                  'FINALIZADA')) {
                                                            ScaffoldMessenger.of(
                                                                    context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'No puede ingresar o editar datos.'),
                                                              ),
                                                            );
                                                            estaBuscando = false;
                                                            return Future.value(false);
                                                          }
                                                          try {
                                                            lotes = await MaterialesServices()
                                                                .getLotes(context,
                                                                    item.material
                                                                        .materialId,
                                                                    token);
                                                            metodosAplicacion =
                                                                await MaterialesServices()
                                                                    .getMetodosAplicacion(
                                                                        context,
                                                                        token);
                                                            estaBuscando = false;
                                                            setState(() {});
                                                          } catch (e) {
                                                            lotes = [];
                                                            metodosAplicacion = [];
                                                            estaBuscando = false;
                                                            setState(() {});
                                                          }
                                                          if (lotes.isNotEmpty &&
                                                              metodosAplicacion
                                                                  .isNotEmpty) {
                                                            bool resultado =
                                                                await _showMaterialDialog(
                                                                    context,
                                                                    materialParaEditar:
                                                                        item);
                                                            setState(() {
                                                              estaBuscando = resultado;
                                                            });
                                                          }
                                                          setState(() {});
                                                        }
                                                      : null,
                                                  icon: const Icon(Icons.edit)),
                                              IconButton(
                                                  onPressed: () async {
                                                    if ((orden.estado ==
                                                                'PENDIENTE' ||
                                                            orden.estado ==
                                                                'FINALIZADA')) {
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                              const SnackBar(
                                                        content: Text(
                                                            'No puede de ingresar o editar datos.'),
                                                      ));
                                                      return Future.value(false);
                                                    }
                                                    deleteMaterial(context, i);
                                                  },
                                                  icon: const Icon(Icons.delete)),
                                            ],
                                          ),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Material: ${revisionMaterialesList[i].material.descripcion}'),
                                              Text('Unidad: ${revisionMaterialesList[i].material.unidad}'),
                                              Text('Cantidad: ${revisionMaterialesList[i].cantidad}'),
                                              Text('Lote: ${revisionMaterialesList[i].lote?.lote ?? "Sin lote"}'),
                                              Text('Método de aplicación: ${revisionMaterialesList[i].metodoAplicacion.descripcion}'),
                                              Text('Comentario: ${revisionMaterialesList[i].comentario}'),
                                            ],
                                          ),
                                          onLongPress: () async {
                                            await verManual(context,material: item.material);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  separatorBuilder:
                                      (BuildContext context, int index) {
                                    return const Divider(
                                      thickness: 2,
                                      color: Colors.green,
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
                    if (!borrando) {
                      borrando = true;
                      await _materialesServices.deleteRevisionMaterial(
                          context, orden, revisionMaterialesList[i], token);
                      statusCodeRevision =
                          await _materialesServices.getStatusCode();
                      await _materialesServices.resetStatusCode();
                      if (statusCodeRevision == 1) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('El material ${revisionMaterialesList[i].material.descripcion} ha sido borrado'),
                        ));
                        setState(() {
                          revisionMaterialesList.removeAt(i);
                        });
                        router.pop();
                      }
                      statusCodeRevision = null;
                      borrando = false;
                    }
                  },
                  child: const Text("BORRAR")),
            ],
          );
        });
  }

  Future<void> verManual(BuildContext context, {RevisionMaterial? item, Materiales? material}) async {
    try {
      manuales = material == null
        ? await _materialesServices.getManualesMateriales(context, item!.material.materialId, token)
        : await _materialesServices.getManualesMateriales(context, material.materialId, token);
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
                var manual = manuales[i];
                return ListTile(
                  title: Text(manual.filename),
                  onTap: () {
                    launchURL(manual.filepath, token);
                  },
                );
              }
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CERRAR"),
            ),
          ],
        );
      }
    );
  }

  bool esNumerico(String str) {
    return double.tryParse(str) != null;
  }

  launchURL(String url, String token) async {
    Dio dio = Dio();
    String link = url += '?authorization=$token';
    print(link);
    try {
      // Realizar la solicitud HTTP con el encabezado de autorización
      Response response = await dio.get(
        link,
        options: Options(
          headers: {
            'Authorization': 'headers $token',
          },
        ),
      );
      // Verificar si la solicitud fue exitosa (código de estado 200)
      if (response.statusCode == 200) {
        // Si la respuesta fue exitosa, abrir la URL en el navegador
        Uri uri = Uri.parse(url);
        await launchUrl(uri);
      } else {
        // Si la solicitud no fue exitosa, mostrar un mensaje de error
        print('Error al cargar la URL: ${response.statusCode}');
      }
    } catch (e) {
      // Manejar errores de solicitud
      print('Error al realizar la solicitud: $e');
    }
  }
}