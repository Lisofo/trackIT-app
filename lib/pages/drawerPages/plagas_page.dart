// ignore_for_file: use_build_context_synchronously, void_checks

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/gradoInfestacion.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/plaga.dart';
import 'package:app_tec_sedel/models/revision_plaga.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/plagas_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlagasPage extends StatefulWidget {
  const PlagasPage({super.key});

  @override
  State<PlagasPage> createState() => _PlagasPageState();
}

class _PlagasPageState extends State<PlagasPage> {
  List<Plaga> plagas = [];
  final _revisionServices = RevisionServices();
  final _plagaServices = PlagaServices();
  List<GradoInfestacion> gradoInfeccion = [
    GradoInfestacion(
        gradoInfestacionId: 1,
        codGradoInfestacion: '1',
        descripcion: 'Sin Avistamiento'),
    GradoInfestacion(
        gradoInfestacionId: 2,
        codGradoInfestacion: '2',
        descripcion: 'Población Controlada - Aceptable'),
    GradoInfestacion(
        gradoInfestacionId: 3,
        codGradoInfestacion: '3',
        descripcion: 'Población Media - Requiere Atención'),
    GradoInfestacion(
        gradoInfestacionId: 4,
        codGradoInfestacion: '4',
        descripcion: 'Población Alta - Grave'),
  ];
  List<Plaga> plagasSeleccionadas = [];
  late Plaga selectedPlaga = Plaga.empty();
  List<GradoInfestacion> gradosSeleccionados = [];
  GradoInfestacion selectedGrado = GradoInfestacion.empty();
  final ScrollController _scrollController = ScrollController();
  late String token = '';
  late Orden orden = Orden.empty();
  late List<RevisionPlaga> revisionPlagasList = [];
  bool isReadOnly = true;
  late int marcaId = 0;
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  bool agregandoPlaga = false;
  int? statusCodeRevision;
  bool borrando = false;

  @override
  void initState(){
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
      plagas = await _plagaServices.getPlagas(context, token);
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      if(orden.otRevisionId != 0) {
        revisionPlagasList = await _revisionServices.getRevisionPlagas(context, orden, token);
      }
      if (plagas.isNotEmpty){
        cargoDatosCorrectamente = true;
      }
      cargando = false;
    }catch (e) {
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
          '${orden.ordenTrabajoId} - Plagas',
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
      ) :
      Padding(
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
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione una plaga'
                    )
                  ),
                  items: plagas,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true, searchDelay: Duration.zero
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedPlaga = value;
                    });
                  },
                )),
            const SizedBox(height: 30,),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: colors.primary),
                borderRadius: BorderRadius.circular(5)
              ),
              child: DropdownSearch(
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: 'Seleccione un grado de infestación'
                  )
                ),
                items: gradoInfeccion,
                popupProps: const PopupProps.menu(
                  showSearchBox: true, searchDelay: Duration.zero),
                onChanged: (value) {
                  setState(() {
                    selectedGrado = value;
                  });
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  onPressed: !agregandoPlaga ? () async {
                    agregandoPlaga = true;
                    setState(() {});
                    if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No puede de ingresar o editar datos.'),
                      ));
                      agregandoPlaga = false;
                      return Future.value(false);
                    }
                    if(selectedGrado.gradoInfestacionId != 0){
                      bool agregarPlaga = true;
                      if (revisionPlagasList.isNotEmpty) {
                        agregarPlaga = !revisionPlagasList.any((plaga) => plaga.plagaId == selectedPlaga.plagaId);
                      }
                      if (agregarPlaga) {
                        await posteoRevisionPlaga(context);
                        agregandoPlaga = false;
                        setState(() {});
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Seleccione un grado de infestación'),
                      ));
                      agregandoPlaga = false;
                      return Future.value(false);
                    }
                    agregandoPlaga = false;
                    setState(() {});
                  }: null,
                  disabled: agregandoPlaga,
                  text: 'Agregar +',
                  tamano: 20,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: revisionPlagasList.length,
                  itemBuilder: (context, index) {
                    final item = revisionPlagasList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: Key(item.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (DismissDirection direction) async {
                          if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
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
                                  "¿Estas seguro de querer borrar la plaga?"),
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
                                      await _revisionServices.deleteRevisionPlaga(context,orden,revisionPlagasList[index],token);
                                      statusCodeRevision = await _revisionServices.getStatusCode();
                                      await _revisionServices.resetStatusCode();
                                      if(statusCodeRevision == 1){
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
                          if(statusCodeRevision == 1){
                            setState(() {
                            revisionPlagasList.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('La plaga $item ha sido borrada'),
                            ));
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
                        child: Container(
                          decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide())),
                          child: ListTile(
                            title: Text(revisionPlagasList[index].plaga),
                            subtitle: Text(revisionPlagasList[index].gradoInfestacion),
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
                                      content: const Text("¿Estas seguro de querer borrar la plaga?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>Navigator.of(context).pop(false),
                                          child: const Text("CANCELAR"),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(foregroundColor:Colors.red,
                                          ),
                                          onPressed: !borrando ? () async {
                                            borrando = true;
                                            setState(() {});
                                            await borrarPlaga(context, index);
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
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> borrarPlaga(BuildContext context, int index) async {
    await _revisionServices.deleteRevisionPlaga(context, orden, revisionPlagasList[index], token);
    statusCodeRevision = await _revisionServices.getStatusCode();
    await _revisionServices.resetStatusCode();
    if(statusCodeRevision == 1){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('La plaga ${revisionPlagasList[index].plaga} ha sido borrada'),
      ));
      setState(() {
        revisionPlagasList.removeAt(index);
      });
      router.pop();
    }
    statusCodeRevision = null;
    borrando = false;
  }

  Future<void> posteoRevisionPlaga(BuildContext context) async {
    var nuevaPlaga = RevisionPlaga(
      otPlagaId: 0,
      ordenTrabajoId: orden.ordenTrabajoId!,
      otRevisionId: orden.otRevisionId!,
      comentario: '',
      plagaId: selectedPlaga.plagaId,
      codPlaga: selectedPlaga.codPlaga,
      plaga: selectedPlaga.descripcion,
      gradoInfestacionId: selectedGrado.gradoInfestacionId,
      codGradoInfestacion: selectedGrado.codGradoInfestacion,
      gradoInfestacion: selectedGrado.descripcion
    );
    await _revisionServices.postRevisionPlaga(
      context,
      orden,
      selectedPlaga.plagaId,
      selectedGrado.gradoInfestacionId,
      nuevaPlaga,
      token
    );
    statusCodeRevision = await _revisionServices.getStatusCode();
    await _revisionServices.resetStatusCode();
    if(statusCodeRevision == 1) {
      revisionPlagasList.add(nuevaPlaga);
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
    }
    statusCodeRevision = null;
  }
}
