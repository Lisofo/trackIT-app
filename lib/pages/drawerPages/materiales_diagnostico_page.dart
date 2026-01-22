// ignore_for_file: use_build_context_synchronously, avoid_init_to_null, void_checks, avoid_print

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/manuales_materiales.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/plaga.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/materiales_diagnostico_services.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialesDiagnosticoPage extends StatefulWidget {
  const MaterialesDiagnosticoPage({super.key});

  @override
  State<MaterialesDiagnosticoPage> createState() => _MaterialesDiagnosticoPageState();
}

class _MaterialesDiagnosticoPageState extends State<MaterialesDiagnosticoPage> {
  late List<String> savedData = [];
  List<Materiales> materiales = [];
  late List<Plaga> plagas = [];
  final _materialesServices = MaterialesServices();
  final _materialesDiagnisticoServices = MaterialesDiagnosticoServices();
  late List<Plaga> plagasSeleccionadas = [];
  late List<RevisionMaterial> revisionMaterialesList = [];
  late Materiales selectedMaterial = Materiales.empty();
  late String cantidad = '';
  late String comentario = '';
  late String token = '';
  late Materiales? materialInicial = null;
  late Orden orden = Orden.empty();
  final ScrollController _scrollController = ScrollController();
  late int marcaId = 0;
  final TextEditingController comentarioController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  late List<ManualesMateriales> manuales = [];
  bool estaBuscando = false;
  bool borrando = false;
  bool agrengandoMaterial = false;
  int? statusCodeMaterial;
  bool cargoDatosCorrectamente = false;
  bool cargando = true;

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
      materiales = await MaterialesServices().getMateriales(context, token);
      if(orden.otRevisionId != 0) {
        revisionMaterialesList = await MaterialesServices().getRevisionMateriales(context, orden, token);
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
    comentarioController.text = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              CustomTextFormField(
                label: 'Cantidad',
                keyboard: TextInputType.number,
                onChanged: (value) {
                  cantidad = value;
                },
              ),
              const SizedBox(height: 16,),
              CustomTextFormField(
                controller: comentarioController,
                maxLines: 1,
                label: 'Comentario',
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
              onPressed: !agrengandoMaterial ? () async {
                agrengandoMaterial = true;
                setState(() {});
                final RevisionMaterial nuevaRevisionMaterial =
                  RevisionMaterial(
                    otMaterialId: 0,
                    ordenTrabajoId: orden.ordenTrabajoId!,
                    otRevisionId: orden.otRevisionId!,
                    cantidad: esNumerico(cantidad) ? double.parse(cantidad) : double.parse("0.0"),
                    comentario: comentarioController.text,
                    ubicacion: '',
                    areaCobertura: '',
                    plagas: [],
                    material: material,
                    lote: Lote.empty(),
                    metodoAplicacion: MetodoAplicacion.empty()
                  );
                await _materialesDiagnisticoServices.postRevisionMaterial(context, orden, nuevaRevisionMaterial, token);
                statusCodeMaterial = await _materialesDiagnisticoServices.getStatusCode();
                await _materialesDiagnisticoServices.resetStatusCode();
                if(statusCodeMaterial == 1){
                  revisionMaterialesList.add(nuevaRevisionMaterial);
                  statusCodeMaterial = null;
                  setState(() {});
                }
                agrengandoMaterial = false;
              } : null,
              child: const Text('Guardar'),
              
            ),
          ],
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
          iconTheme: const IconThemeData(color: Colors.white),
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
                        color: colors.primary),
                    borderRadius: BorderRadius.circular(5)),
                child: DropdownSearch(
                  enabled: !estaBuscando,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    textAlignVertical: TextAlignVertical.center,
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione un material'
                    )
                  ),
                  items: materiales,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true, searchDelay: Duration.zero
                  ),
                  onChanged: (newValue) async {
                    if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO')){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No puede de ingresar o editar datos.'),
                      ));
                      return Future.value(false);
                    }
                    setState(() {
                      selectedMaterial = newValue!;
                      estaBuscando = true;
                    });
                    bool resultado = await _showMaterialDetails(context, selectedMaterial);
                    setState(() {
                      estaBuscando = resultado;
                    });
                  },
                )
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
                          'Materiales a utilizar:',
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
                              if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO')){
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
                                        onPressed: () => Navigator.of(context) .pop(false),
                                        child: const Text("CANCELAR"),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () async { 
                                          await _materialesDiagnisticoServices.deleteRevisionMaterial(context, orden,revisionMaterialesList[i],token);
                                          statusCodeMaterial = await _materialesDiagnisticoServices.getStatusCode();
                                          await _materialesDiagnisticoServices.resetStatusCode();
                                          if(statusCodeMaterial == 1){
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
                              if(statusCodeMaterial == 1){
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('El material ${item.material.descripcion} ha sido borrado'),
                                ));
                                setState(() {
                                  revisionMaterialesList.removeAt(i);
                                });
                              }
                              statusCodeMaterial = null;
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: !estaBuscando
                                        ? () async {
                                            if (marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO')) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('No puede ingresar o editar datos.'),
                                                ),
                                              );
                                              return Future.value(false);
                                            }
                                            setState(() {
                                              estaBuscando = true;
                                            });
                                            bool resultado = await editMaterial(context, item);
                                            setState(() {
                                              estaBuscando = resultado;
                                            });
                                          }
                                        : null,
                                      icon: const Icon(Icons.edit)
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO')){
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
                                              content: const Text(
                                                  "¿Estas seguro de querer borrar el material?"),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text("CANCELAR"),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(foregroundColor:Colors.red,),
                                                  onPressed: !borrando ? () async {
                                                    borrando = true;
                                                    setState(() {});
                                                    await borrarMaterial(context, item, i);
                                                  } : null,
                                                  child: const Text("BORRAR")
                                                ),
                                              ],
                                            );
                                          }
                                        );
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
                                    Text('Comentario: ${revisionMaterialesList[i].comentario}'),
                                  ],
                                ),
                                onLongPress: () async {
                                  await verManual(context, item, null);
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

  Future<void> borrarMaterial(BuildContext context, RevisionMaterial item, int i) async {
    
    await _materialesDiagnisticoServices.deleteRevisionMaterial(context, orden, revisionMaterialesList[i], token);
    statusCodeMaterial = await _materialesDiagnisticoServices.getStatusCode();
    await _materialesDiagnisticoServices.resetStatusCode();

    if (statusCodeMaterial == 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('El material ${revisionMaterialesList[i].material.descripcion} ha sido borrado'),
      ));
      setState(() {
        revisionMaterialesList.removeAt(i);
      });
      router.pop();
    }
    statusCodeMaterial = null;
    borrando = false;
    
  }

  bool esNumerico(String str) {
    return double.tryParse(str) != null;
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

  Future<bool> editMaterial(BuildContext context, RevisionMaterial material) async {
    if(material.otMaterialId != 0){
      comentarioController.text = material.comentario;
      cantidadController.text = material.cantidad.toString();
    } else{
      comentarioController.text = '';
      cantidadController.text = '';
    }
    

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
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
                CustomTextFormField(
                  label: 'Cantidad',
                  controller: cantidadController,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 16,),
                CustomTextFormField(
                  controller: comentarioController,
                  minLines: 1,
                  maxLines: 5,
                  label: 'Comentario',
                )
              ],
            ),
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
                comentario = comentarioController.text;
                cantidad = cantidadController.text;
                final RevisionMaterial nuevaRevisionMaterial =
                  RevisionMaterial(
                    otMaterialId: material.otMaterialId,
                    ordenTrabajoId: orden.ordenTrabajoId!,
                    otRevisionId: orden.otRevisionId!,
                    cantidad: esNumerico(cantidad) ? double.parse(cantidad) : double.parse("0.0"),
                    comentario: comentario,
                    ubicacion: '',
                    areaCobertura: '',
                    plagas: [],
                    material: material.material,
                    lote: Lote.empty(),
                    metodoAplicacion: MetodoAplicacion.empty()
                  );
                await _materialesDiagnisticoServices.putRevisionMaterial(context, orden, nuevaRevisionMaterial, token);
                statusCodeMaterial = await _materialesDiagnisticoServices.getStatusCode();
                await _materialesDiagnisticoServices.resetStatusCode();

                if(statusCodeMaterial == 1){
                  comentarioController.text = '';
                  cantidadController.text = '';
                  revisionMaterialesList = await _materialesDiagnisticoServices.getRevisionMateriales(context, orden, token);
                }
                statusCodeMaterial = null;
                setState(() {});
              },
            ),
          ],
        );
      },
    );
    return false;
  }
}
