// ignore_for_file: use_build_context_synchronously, avoid_init_to_null, void_checks, avoid_print

import 'package:app_track_it/models/manuales_materiales.dart';
import 'package:app_track_it/models/material.dart';
import 'package:app_track_it/models/orden.dart';
import 'package:app_track_it/models/plaga.dart';
import 'package:app_track_it/models/revision_materiales.dart';
import 'package:app_track_it/providers/orden_provider.dart';
import 'package:app_track_it/services/materiales_services.dart';
import 'package:app_track_it/services/plagas_services.dart';
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
  late List<Plaga> plagas = [];
  late List<Plaga> plagasSeleccionadas = [];
  late List<RevisionMaterial> revisionMaterialesList = [];
  late Materiales selectedMaterial = Materiales.empty();
  late Lote? selectedLote = Lote.empty();
  late String cantidad = '';
  late String ubicacion = '';
  late String areaCobertura = '';
  late MetodoAplicacion? selectedMetodo;
  late String token = '';
  late Materiales? materialInicial = null;
  late Orden orden = Orden.empty();
  final ScrollController _scrollController = ScrollController();
  late int marcaId = 0;
  late List<ManualesMateriales> manuales = [];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<OrdenProvider>().token;
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    materiales = await MaterialesServices().getMateriales(token);
    revisionMaterialesList = await MaterialesServices().getRevisionMateriales(orden, token);
    setState(() {});
  }

  void _showMaterialDetails(BuildContext context, Materiales material) async {
    plagas = await PlagaServices().getPlagas(token);
    lotes = await MaterialesServices().getLotes(selectedMaterial.materialId, token);
    metodosAplicacion = await MaterialesServices().getMetodosAplicacion(token);
    selectedMetodo = MetodoAplicacion.empty();
    selectedLote = Lote.empty();

    showDialog(
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
                  'Nombre: ${material.descripcion}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Unidad: ${material.unidad}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (){
                    verManual(context, null, material);
                  }, 
                  child: const Text('Ver Manuales', style: TextStyle(fontSize: 16, decoration: TextDecoration.underline),)
                ),
                const SizedBox(height: 16),
                const Text('Cantidad:'),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    cantidad = value;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Lote:'),
                DropdownSearch(
                  items: lotes,
                  onChanged: (newValue) {
                    setState(() {
                      selectedLote = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Método de Aplicación:'),
                DropdownSearch(
                  items: metodosAplicacion,
                  onChanged: (newValue) {
                    setState(() {
                      selectedMetodo = newValue;
                    });
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text('Plagas:'),
                DropdownSearch<Plaga>.multiSelection(
                  items: plagas,
                  popupProps: const PopupPropsMultiSelection.menu(
                      // showSelectedItems: true,
                      // disabledItemFn: (String s) => s.startsWith('I'),
                      ),
                  onChanged: (value) {
                    plagasSeleccionadas = (value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Ubicación:'),
                TextField(
                  onChanged: (value) {
                    ubicacion = value;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Área de Cobertura:'),
                TextField(
                  onChanged: (value) {
                    areaCobertura = value;
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  late List<int> plagasIds = [];

                  final RevisionMaterial nuevaRevisionMaterial =
                      RevisionMaterial(
                          otMaterialId: 0,
                          ordenTrabajoId: orden.ordenTrabajoId,
                          otRevisionId: orden.otRevisionId,
                          cantidad: esNumerico(cantidad)
                              ? double.parse(cantidad)
                              : double.parse("0.0"),
                          comentario: '',
                          ubicacion: ubicacion,
                          areaCobertura: areaCobertura,
                          plagas: plagasSeleccionadas,
                          material: material,
                          lote: selectedLote!,
                          metodoAplicacion: selectedMetodo!);
                  for (var i = 0; i < plagasSeleccionadas.length; i++) {
                    plagasIds.add(plagasSeleccionadas[i].plagaId);
                  }
                  await MaterialesServices().postRevisionMaterial(
                      context, orden, plagasIds, nuevaRevisionMaterial, token);
                  revisionMaterialesList.add(nuevaRevisionMaterial);

                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (selectedMaterial.materialId != 0 && materiales.isNotEmpty) {
      materialInicial = materiales.firstWhere((material) => material.materialId == selectedMaterial.materialId);
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            '${orden.ordenTrabajoId} - Materiales',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: colors.primary,
        ),
        backgroundColor: Colors.grey.shade200,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 2,
                        color: colors.primary),
                    borderRadius: BorderRadius.circular(5)),
                child: DropdownButton<Materiales>(
                  hint: const Text("Selecciona un material"),
                  value: materialInicial,
                  onChanged: (newValue) async {
                    if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No puede de ingresar o editar datos.'),
                      ));
                      return Future.value(false);
                    }
                    setState(() {
                      selectedMaterial = newValue!;
                      _showMaterialDetails(context, selectedMaterial);
                    });
                  },
                  items: materiales.map((material) {
                    return DropdownMenuItem(
                      value: material,
                      child: Text(material.descripcion),
                    );
                  }).toList(),
                  iconSize: 24,
                  elevation: 16,
                  isExpanded: true,
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
                            key: Key(item.toString()),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (DismissDirection direction) async {
                              if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('No puede de ingresar o editar datos.'),
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
                                            Navigator.of(context)
                                                .pop(false),
                                        child: const Text("CANCELAR"),
                                      ),
                                      TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () async {
                                            Navigator.of(context).pop(true);
                                            await MaterialesServices().deleteRevisionMaterial(context,orden,revisionMaterialesList[i],token);
                                          },
                                          child: const Text("BORRAR")),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              setState(() {
                                revisionMaterialesList.removeAt(i);
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('$item borrado'),
                              ));
                            },
                            background: Container(
                              color: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              alignment: AlignmentDirectional.centerEnd,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: Card(
                              surfaceTintColor: Colors.white,
                              child: ListTile(
                                trailing: IconButton(
                                  onPressed: () async {
                                    if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('No puede de ingresar o editar datos.'),
                                      ));
                                      return Future.value(false);
                                    }
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
                                                await MaterialesServices().deleteRevisionMaterial(context,orden,revisionMaterialesList[i],token);
                                                setState(() {
                                                  revisionMaterialesList.removeAt(i);
                                                });
                                              },
                                              child: const Text("BORRAR")
                                            ),
                                          ],
                                        );
                                      }
                                    );
                                  },
                                  icon: const Icon(Icons.delete)
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Material: ${revisionMaterialesList[i].material.descripcion}'),
                                    Text('Unidad: ${revisionMaterialesList[i].material.unidad}'),
                                    Text('Cantidad: ${revisionMaterialesList[i].cantidad}'),
                                    Text('Lote: ${revisionMaterialesList[i].lote}'),
                                    Text('Metodo de aplicacion: ${revisionMaterialesList[i].metodoAplicacion}'),
                                    Text('Ubicación: ${revisionMaterialesList[i].ubicacion}'),
                                    Text('Área de Cobertura: ${revisionMaterialesList[i].areaCobertura}'),
                                    Text('Plagas: ${revisionMaterialesList[i].plagas}'),
                                  ],
                                ),
                                onLongPress: () async {
                                  await verManual(context, item, null);
                                },
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(
                            thickness: 2,
                            color: colors.secondary,
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

  Future<void> verManual(BuildContext context, RevisionMaterial? item, Materiales? material) async {
    manuales = material == null ? await MaterialesServices().getManualesMateriales(context, item!.material.materialId, token) : await MaterialesServices().getManualesMateriales(context, material.materialId, token);
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
