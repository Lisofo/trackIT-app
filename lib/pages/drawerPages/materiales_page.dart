// ignore_for_file: use_build_context_synchronously, avoid_init_to_null, void_checks, avoid_print

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/manuales_materiales.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/plaga.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/plagas_services.dart';
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
      if(orden.otRevisionId != 0) {
        revisionMaterialesList = await _materialesServices.getRevisionMateriales(context, orden, token);
      }
      if (materiales.isNotEmpty){
        cargoDatosCorrectamente = true;
      }
      cargando = false;
    } catch (e) {
      cargando = false;
    }
    
    setState(() {});
  }

  Future<bool> _showMaterialDetails(BuildContext context, Materiales material) async {
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
                const Text('* Cantidad:'),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    cantidad = value;
                  },
                ),
                const SizedBox(height: 16),
                Text(lotes.isEmpty ? 'Lote:' : '* Lote:'),
                DropdownSearch(
                  items: lotes,
                  onChanged: (newValue) {
                    setState(() {
                      selectedLote = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('* Método de Aplicación:'),
                DropdownSearch(
                  items: metodosAplicacion,
                  onChanged: (newValue) {
                    setState(() {
                      selectedMetodo = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16,),
                const Text('* Plagas:'),
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
                const Text('* Ubicación:'),
                TextField(
                  onChanged: (value) {
                    ubicacion = value;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Área de Cobertura (m²-m³):'),
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
                  bool noTieneLotes = false;
                  bool tieneLoteId = false;
                  if(lotes.isEmpty){
                    noTieneLotes = true;
                  } else{
                    if(selectedLote!.materialLoteId != 0){
                      tieneLoteId = true;
                    }
                  }
                  if(cantidad != '' && ubicacion != '' && plagasSeleccionadas.isNotEmpty && (noTieneLotes || tieneLoteId) && (metodosAplicacion.isNotEmpty && selectedMetodo!.metodoAplicacionId != 0)){
                    late List<int> plagasIds = [];
                    final RevisionMaterial nuevaRevisionMaterial =
                      RevisionMaterial(
                        otMaterialId: 0,
                        ordenTrabajoId: orden.ordenTrabajoId!,
                        otRevisionId: orden.otRevisionId!,
                        cantidad: esNumerico(cantidad) ? double.parse(cantidad) : double.parse("0.0"),//
                        comentario: '',
                        ubicacion: ubicacion,//
                        areaCobertura: areaCobertura,
                        plagas: plagasSeleccionadas,//
                        material: material,
                        lote: selectedLote,//
                        metodoAplicacion: selectedMetodo!//
                      );
                    for (var i = 0; i < plagasSeleccionadas.length; i++) {
                      plagasIds.add(plagasSeleccionadas[i].plagaId);
                    }
                    await _materialesServices.postRevisionMaterial(context, orden, plagasIds, nuevaRevisionMaterial, token);
                    statusCodeRevision = await _materialesServices.getStatusCode();
                    await _materialesServices.resetStatusCode();
                    if(statusCodeRevision == 1) {
                      revisionMaterialesList.add(nuevaRevisionMaterial);
                      statusCodeRevision = null;
                      setState(() {});
                    }
                  } else {
                    showDialog(
                      context: context, 
                      builder: (BuildContext context){
                        return AlertDialog(
                          title: const Text('Error'),
                          content: const Text('Faltan campos por completar'),
                          actions: [
                            TextButton(onPressed: ()=> router.pop(), child: const Text('Cerrar'))
                          ],
                        );
                      }
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    return false;
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
          title: Text(
            '${orden.ordenTrabajoId} - Materiales',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: colors.primary,
        ),
        backgroundColor: Colors.grey.shade200,
        body: cargando ? const Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text('Cargando, por favor espere...')
              ],
            ),
          ) : !cargoDatosCorrectamente ? 
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await cargarDatos();
              }, 
              icon: const Icon(Icons.replay_outlined),
              label: const Text('Recargar'),
            ),
          ) : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: colors.primary
                  ),
                  borderRadius: BorderRadius.circular(5)
                ),
                child: DropdownSearch(
                  enabled: !estaBuscando,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    textAlignVertical: TextAlignVertical.center,
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione un material',
                    )
                  ),
                  items: materiales,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true, searchDelay: Duration.zero
                  ),
                  onChanged: (newValue) async {
                    if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No puede de ingresar o editar datos.'),
                      ));
                      return Future.value(false);
                    }
                    setState(() {
                      selectedMaterial = newValue!;
                      estaBuscando = true;
                    });
                    try {
                      plagas = await PlagaServices().getPlagas(context, token);
                      lotes = await MaterialesServices().getLotes(context, selectedMaterial.materialId, token);
                      metodosAplicacion = await MaterialesServices().getMetodosAplicacion(context, token);
                    } catch (e) {
                      plagas = [];
                      lotes = [];
                      metodosAplicacion = [];
                      estaBuscando = false;
                      setState(() {});
                    }
                    if(plagas.isNotEmpty && metodosAplicacion.isNotEmpty){
                      bool resultado = await _showMaterialDetails(context, selectedMaterial);
                      setState(() {
                        estaBuscando = resultado;
                      });
                    }
                  },
                )
              ),
              const SizedBox(height: 20,),
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
                                          await _materialesServices.deleteRevisionMaterial(context, orden, revisionMaterialesList[i], token);
                                          statusCodeRevision = await _materialesServices.getStatusCode();
                                          await _materialesServices.resetStatusCode();
                                          if(statusCodeRevision == 1) {
                                            Navigator.of(context).pop(true);
                                          }
                                        },
                                        child: const Text("BORRAR")
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              if(statusCodeRevision == 1){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('El material ${item.material.descripcion} ha sido borrado'),
                                ));
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
                                            if (marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('No puede ingresar o editar datos.'),
                                                ),
                                              );
                                              estaBuscando = false;
                                              return Future.value(false);
                                            }
                                            try {
                                              plagas = await PlagaServices().getPlagas(context, token);
                                              lotes = await MaterialesServices().getLotes(context, item.material.materialId, token);
                                              metodosAplicacion = await MaterialesServices().getMetodosAplicacion(context, token);
                                              estaBuscando = false;
                                              setState(() {});  
                                            } catch (e) {
                                              plagas = [];
                                              lotes = [];
                                              metodosAplicacion = [];
                                              estaBuscando = false;
                                              setState(() {});
                                            }
                                            if(plagas.isNotEmpty && lotes.isNotEmpty && metodosAplicacion.isNotEmpty){
                                              bool resultado = await editMaterial(context, item);
                                              setState(() {
                                                estaBuscando = resultado;
                                              });
                                              
                                            }
                                            setState(() {});
                                          }
                                        : null,
                                      icon: const Icon(Icons.edit)
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text('No puede de ingresar o editar datos.'),
                                          ));
                                          return Future.value(false);
                                        }
                                        deleteMaterial(context, i);
                                      },
                                      icon: const Icon(Icons.delete)
                                    ),
                                  ],
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
                if(!borrando){
                  borrando = true;
                  await _materialesServices.deleteRevisionMaterial(context,orden,revisionMaterialesList[i],token);
                  statusCodeRevision = await _materialesServices.getStatusCode();
                  await _materialesServices.resetStatusCode();
                  if(statusCodeRevision == 1) {
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
              child: const Text("BORRAR")
            ),
          ],
        );
      }
    );
  }

  Future<void> verManual(BuildContext context, RevisionMaterial? item, Materiales? material) async {
    try {
      manuales = material == null ? await _materialesServices.getManualesMateriales(context, item!.material.materialId, token) : await _materialesServices.getManualesMateriales(context, material.materialId, token);
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

  Future <bool> editMaterial(BuildContext context, RevisionMaterial material) async {
    final TextEditingController ubicacionController = TextEditingController();
    final TextEditingController areaController = TextEditingController();
    final TextEditingController cantidadController = TextEditingController();
    if(material.otMaterialId != 0){
      selectedLote = material.lote;
      selectedMetodo = material.metodoAplicacion;
      ubicacionController.text = material.ubicacion;
      areaController.text = material.areaCobertura;
      cantidadController.text = material.cantidad.toString();
      plagasSeleccionadas = material.plagas;
    } else {
      selectedLote = Lote.empty();
      selectedMetodo = MetodoAplicacion.empty();
    }   

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
                  'Nombre: ${material.material.descripcion}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Unidad: ${material.material.unidad}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (){
                    verManual(context, null, material.material);
                  }, 
                  child: const Text('Ver Manuales', style: TextStyle(fontSize: 16, decoration: TextDecoration.underline),)
                ),
                const SizedBox(height: 16),
                const Text('* Cantidad:'),
                TextFormField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(lotes.isEmpty ? 'Lote:' : '* Lote:'),
                DropdownSearch(
                  items: lotes,
                  selectedItem: selectedLote,
                  onChanged: (newValue) {
                    setState(() {
                      selectedLote = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('* Método de Aplicación:'),
                DropdownSearch(
                  items: metodosAplicacion,
                  selectedItem: selectedMetodo,
                  onChanged: (newValue) {
                    setState(() {
                      selectedMetodo = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16,),
                const Text('* Plagas:'),
                DropdownSearch<Plaga>.multiSelection(
                  items: plagas,
                  selectedItems: material.plagas,
                  itemAsString: (Plaga p) => p.descripcion,
                  compareFn: (Plaga p1, Plaga p2) => p1.plagaId == p2.plagaId,
                  popupProps: const PopupPropsMultiSelection.menu(
                    showSelectedItems: true,
                  ),
                  onChanged: (value) {
                    plagasSeleccionadas = (value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('* Ubicación:'),
                TextFormField(
                  controller: ubicacionController,
                ),
                const SizedBox(height: 16),
                const Text('Área de Cobertura (m²-m³):'),
                TextFormField(
                  controller: areaController,
                )
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
                  ubicacion = ubicacionController.text;
                  areaCobertura = areaController.text;
                  cantidad = cantidadController.text;
                  bool noTieneLotes = false;
                  bool tieneLoteId = false;
                  if(lotes.isEmpty){
                    noTieneLotes = true;
                  } else{
                    if(selectedLote!.materialLoteId != 0){
                      tieneLoteId = true;
                    }
                  }
                  if(cantidad != '' && ubicacion != '' && plagasSeleccionadas.isNotEmpty && (noTieneLotes || tieneLoteId) && (metodosAplicacion.isNotEmpty && selectedMetodo!.metodoAplicacionId != 0)){
                    late List<int> plagasIds = [];
                    final RevisionMaterial nuevaRevisionMaterial =
                      RevisionMaterial(
                        otMaterialId: material.otMaterialId,
                        ordenTrabajoId: orden.ordenTrabajoId!,
                        otRevisionId: orden.otRevisionId!,
                        cantidad: esNumerico(cantidad) ? double.parse(cantidad) : double.parse("0.0"),//
                        comentario: '',
                        ubicacion: ubicacion,//
                        areaCobertura: areaCobertura,
                        plagas: plagasSeleccionadas,//
                        material: material.material,
                        lote: selectedLote,//
                        metodoAplicacion: selectedMetodo!//
                      );
                    for (var i = 0; i < plagasSeleccionadas.length; i++) {
                      plagasIds.add(plagasSeleccionadas[i].plagaId);
                    }
                    await _materialesServices.putRevisionMaterial(context, orden, plagasIds, nuevaRevisionMaterial, token);
                    statusCodeRevision = await _materialesServices.getStatusCode();
                    await _materialesServices.resetStatusCode();
                    if(statusCodeRevision == 1){
                      selectedLote = Lote.empty();
                      selectedMetodo = MetodoAplicacion.empty();
                      ubicacionController.text = '';
                      areaController.text = '';
                      cantidadController.text = '';
                      revisionMaterialesList = await _materialesServices.getRevisionMateriales(context, orden, token);
                      plagas = [];
                      lotes = [];
                      metodosAplicacion = [];
                    }                   
                    setState(() {});
                  } else {
                    showDialog(
                      context: context, 
                      builder: (BuildContext context){
                        return AlertDialog(
                          title: const Text('Error'),
                          content: const Text('Faltan campos por completar'),
                          actions: [
                            TextButton(onPressed: ()=> router.pop(), child: const Text('Cerrar'))
                          ],
                        );
                      }
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    return false;
  }
}
