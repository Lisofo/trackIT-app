// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/models/control_orden.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/orden_control_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CuestionarioPage extends StatefulWidget {
  const CuestionarioPage({super.key});

  @override
  State<CuestionarioPage> createState() => _CuestionarioPageState();
}

class _CuestionarioPageState extends State<CuestionarioPage> {
  String selectedPregunta = '';
  final TextEditingController comentarioController = TextEditingController();
  late Orden orden = Orden.empty();
  final _ordenControlServices = OrdenControlServices();
  List<ControlOrden> controles =[];
  String token = '';
  List<String> grupos = [];
  List<ControlOrden> preguntasFiltradas = [];
  List<String> models = [];
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  int? statusCodeControles;
  late int marcaId = 0;
  

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<OrdenProvider>().token;
    try {
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      controles = await OrdenControlServices().getControlOrden(context, orden, token);
      controles.sort((a, b) => a.pregunta.compareTo(b.pregunta));
      for(var i = 0; i < controles.length; i++){
        models.add(controles[i].grupo);
      }
      Set<String> conjunto = Set.from(models);
      grupos = conjunto.toList();
      grupos.sort((a, b) => a.compareTo(b));
      if (controles.isNotEmpty){
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cuestionario',style:TextStyle(color: Colors.white)),
          backgroundColor: colors.primary,
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
          ) : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container( 
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: colors.primary),
                  borderRadius: BorderRadius.circular(5)
                ),
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  hint: const Text('Seleccione un grupo de controles', textAlign: TextAlign.center,),
                  items: grupos.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: FittedBox(
                        child: Text(
                          e,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  isDense: true,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() {
                      selectedPregunta = value!;
                      preguntasFiltradas = controles.where((objeto) => objeto.grupo == selectedPregunta).toList();
                      for (var element in preguntasFiltradas) {element.pregunta;}
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.separated(
                itemCount: preguntasFiltradas.length,
                itemBuilder: (context, i) {
                  final ControlOrden pregunta = preguntasFiltradas[i];
                  List<bool> selections = List.generate(3, (_) => false);

                  if(pregunta.respuesta.isNotEmpty){
                    if(pregunta.respuesta == 'APRUEBA'){
                      selections[0] = true;
                    }else if(pregunta.respuesta == 'DESAPRUEBA'){
                      selections[1] = true;
                    }else if(pregunta.respuesta == 'NO APLICA'){
                      selections[2] = true;
                    }
                  }
                  return ListTile(
                    title: Row(
                      children: [
                        Flexible(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text(pregunta.pregunta)
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: () {
                            popUpComentario(context, pregunta);
                          }
                        ),
                      ],
                    ),
                    subtitle: Center(
                      child: ToggleButtons(
                        isSelected: selections,
                        borderColor: colors.primary,
                        selectedBorderColor: colors.primary,
                        borderWidth: 2,
                        borderRadius: BorderRadius.circular(5),
                        fillColor: colors.primary,
                        onPressed: (i){
                          setState(() {
                            
                            selections[0] = false;
                            selections[1] = false;
                            selections[2] = false;

                            selections[i] = true;
                            pregunta.respuesta = selections[0] ? 'APRUEBA' : selections[1] ? 'DESAPRUEBA' : 'NO APLICA';
                          });
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text('APRUEBA', style: TextStyle(fontSize: 14, color: selections[0] ? Colors.white : Colors.black),),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text('DESAPRUEBA', style: TextStyle(fontSize: 14, color: selections[1] ? Colors.white : Colors.black),),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text('NO APLICA', style: TextStyle(fontSize: 14, color: selections[2] ? Colors.white : Colors.black),),
                          ),
                        ],  
                      ),
                    )
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(
                    thickness: 3,
                    color: Colors.green,
                  );
                },
              ))
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 10,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          color: Colors.grey.shade200,
          child: CustomButton(
            onPressed: () async {
              if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('No puede de ingresar o editar datos.'),
                ));
                return Future.value(false);
              }
              await postControles(context);
            },
            text: 'Guardar',
            tamano: 20,
          ),
        ),
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }

  Future<void> postControles(BuildContext context) async {  
    List<ControlOrden> controlesSeleccionados = [];
    for(var control in controles) {
      if(control.respuesta.isNotEmpty){
        controlesSeleccionados.add(control);
      }
    }    
    await _ordenControlServices.postControles(context, orden, controlesSeleccionados, token);
    statusCodeControles = await _ordenControlServices.getStatusCode();
    await _ordenControlServices.resetStatusCode();
    if(statusCodeControles == 1){
      await OrdenControlServices.showDialogs(context, 'Controles actualizados correctamente', false, false);
    }    
    setState(() {});
    statusCodeControles = null;
  }

  void popUpComentario(BuildContext context, ControlOrden pregunta) {
    if(pregunta.controlRegId != 0 || pregunta.comentario != ''){
      comentarioController.text = pregunta.comentario;
    }else{comentarioController.text = '';}


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Observaciones'),
          content: CustomTextFormField(
            controller: comentarioController,
            label: 'Comentario',
            minLines: 1,
            maxLines: 20,
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
              onPressed: () {
                pregunta.comentario = comentarioController.text;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    );
  }

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}