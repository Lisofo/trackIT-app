// ignore_for_file: use_build_context_synchronously, void_checks
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_tarea.dart';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  List<Tarea> tareas = [];
  late String token = '';
  final _revisionServices = RevisionServices();
  final ScrollController _scrollController = ScrollController();
  List<Tarea> tareasSeleccionadas = [];
  Tarea selectedTarea = Tarea.empty();
  late Orden orden = Orden.empty();
  late List<RevisionTarea> revisionTareasList = [];
  late int marcaId = 0;
  bool isReadOnly = true;
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  bool agregandoTarea = false;
  int? statusCodeTareas;
  bool borrando = false;
  bool comenzando = false;
  bool sedel = false;
  bool track = false;
  bool parabrisas = true;
  bool pedirConfirmacion = true;
  bool isObscured = true;
  final TextEditingController pinController = TextEditingController();

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

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    try {
      tareas = await TareasServices().getTareas(context, token);
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      if(orden.otRevisionId != 0){
        revisionTareasList = await RevisionServices().getRevisionTareas(context, orden, token);
      }
      if (tareas.isNotEmpty){
        cargoDatosCorrectamente = true;
      }
      cargando = false;
    } catch (e) {
      cargando = false;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          '${orden.ordenTrabajoId} - Tareas Realizadas',
          style: const TextStyle(color: Colors.white),
        ),
      ),
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
        ) : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1, color: colors.primary
                  ),
                  borderRadius: BorderRadius.circular(5)
                ),
                child: DropdownSearch(
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(hintText: 'Seleccione una tarea')
                ),
                  items: tareas,
                  popupProps: const PopupProps.menu(showSearchBox: true, searchDelay: Duration.zero),
                  onChanged: (value) {
                    setState(() {
                      selectedTarea = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    onPressed: !agregandoTarea ? () async {
                      agregandoTarea = true;
                      setState(() {});
                      if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede de ingresar o editar datos.'),
                        ));
                        agregandoTarea = false;
                        return Future.value(false);
                      }
                      bool agregarTarea = true;
                      if (revisionTareasList.isNotEmpty) {
                        agregarTarea = !revisionTareasList.any((tarea) => tarea.tareaId == selectedTarea.tareaId);
                      }
                      if (agregarTarea) {
                        await posteoRevisionTarea(context);
                        agregandoTarea = false;
                        setState(() {});
                      }else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Seleccione una tarea'),
                        ));
                        agregandoTarea = false;
                        return Future.value(false);
                      }
                      agregandoTarea = false;
                      setState(() {});
                    } : null ,
                    disabled: agregandoTarea,
                    text: 'Agregar +',
                    tamano: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20,),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: revisionTareasList.length,
                  itemBuilder: (context, i) {
                    final item = revisionTareasList[i];
                    return Dismissible(
                      key: Key(item.toString()),
                      direction: sedel ? DismissDirection.endToStart : track ? DismissDirection.startToEnd : DismissDirection.horizontal,
                      confirmDismiss: (DismissDirection direction) {
                        if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('No puede de ingresar o editar datos.'),
                          ));
                          return Future.value(false);
                        }
                        return showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              surfaceTintColor: Colors.white,
                              title: const Text("Confirmar"),
                              content: const Text(
                                "¿Estas seguro de querer borrar la tarea?"
                              ),
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
                                    await _revisionServices.deleteRevisionTarea(context, orden, revisionTareasList[i], token);
                                    statusCodeTareas = await _revisionServices.getStatusCode();
                                    await _revisionServices.resetStatusCode();
                                    if(statusCodeTareas == 1){
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                                  child: const Text("BORRAR")
                                ),
                              ],
                            );
                          }
                        );
                      },
                      onDismissed: (direction) async {
                        if(statusCodeTareas == 1){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('La tarea $item ha sido borrada'),
                          ));
                          setState(() {
                            revisionTareasList.removeAt(i);
                          });
                        }
                        statusCodeTareas = null;
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
                      child: Container(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide())),
                        child: ListTile(
                          title: Text(revisionTareasList[i].descripcion),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if(parabrisas)...[
                                IconButton(
                                  onPressed: () async {
                                    if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('No puede de ingresar o editar datos.'),
                                      ));
                                      return Future.value(false);
                                    }
                                    comenzarTarea(context, i);
                                  },
                                  icon: const Icon(Icons.play_arrow)
                                ),
                              ],
                              IconButton(
                                onPressed: () async {
                                  if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('No puede de ingresar o editar datos.'),
                                    ));
                                    return Future.value(false);
                                  }
                                  popUpBorrarTarea(context, i);
                                },
                                icon: const Icon(Icons.delete)
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void comenzarTarea(BuildContext context, int i) {
    // final colors = Theme.of(context).colorScheme;
    pinController.text = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: const Text("Confirmar"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("¿Comienza a trabajar en la tarea ${revisionTareasList[i].descripcion}?"),
                if(pedirConfirmacion)...[
                  const SizedBox(height: 5,),
                  CustomTextFormField(
                    preffixIcon: const Icon(Icons.lock),
                    keyboard: const TextInputType.numberWithOptions(),
                    controller: pinController,
                    hint: 'Ingrese PIN',
                    maxLines: 1,
                    obscure: isObscured,
                    suffixIcon: IconButton(
                      icon: isObscured
                          ? const Icon(
                              Icons.visibility_off,
                              color: Colors.black,
                            )
                          : const Icon(
                              Icons.visibility,
                              color: Colors.black,
                            ),
                      onPressed: () {
                        setStateBd(() {
                          isObscured = !isObscured;
                        });
                      },
                    ),
                  )
                ]
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCELAR"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () {
                  MenuServices.showDialogs2(context, 'Tarea comenzada', true, true, true, true);
                }, 
                // !comenzando ? () async {
                  // comenzando = true;
                  // setState(() {});
                 // comenzarTarea()
                // } : null,
                child: const Text("COMENZAR")
              ),
            ],
          ),
        );
      }
    );
  }

  void popUpBorrarTarea(BuildContext context, int i) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text("Confirmar"),
          content: const Text("¿Estas seguro de querer borrar la tarea?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCELAR"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: !borrando ? () async {
                borrando = true;
                setState(() {});
                await borrarTarea(context, i);
              } : null,
              child: const Text("BORRAR")
            ),
          ],
        );
      }
    );
  }

  Future<void> borrarTarea(BuildContext context, int i) async {
    await _revisionServices.deleteRevisionTarea(context, orden, revisionTareasList[i], token);
    statusCodeTareas = await _revisionServices.getStatusCode();
    await _revisionServices.resetStatusCode();
    if(statusCodeTareas == 1){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('La tarea ${revisionTareasList[i].descripcion} ha sido borrada'),
      ));
      
      setState(() {
        revisionTareasList.removeAt(i);
      });
      router.pop();
    }
    statusCodeTareas = null;
    borrando = false;
  }

  Future<void> posteoRevisionTarea(BuildContext context) async {
    var nuevaTarea = RevisionTarea(
      otTareaId: 0,
      ordenTrabajoId: orden.ordenTrabajoId!,
      otRevisionId: orden.otRevisionId!,
      tareaId: selectedTarea.tareaId,
      codTarea: selectedTarea.codTarea,
      descripcion: selectedTarea.descripcion,
      comentario: '');
    await _revisionServices.postRevisionTarea(context, orden, selectedTarea.tareaId, nuevaTarea, token);
    statusCodeTareas = await _revisionServices.getStatusCode();
    await _revisionServices.resetStatusCode();
    if(statusCodeTareas == 1){
      revisionTareasList.add(nuevaTarea);
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      statusCodeTareas = null;
    }
    
    
  }
}
