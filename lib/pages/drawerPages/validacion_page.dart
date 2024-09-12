import 'package:app_tec_sedel/models/control_orden.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/orden_control_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ValidacionPage extends StatefulWidget {
  const ValidacionPage({super.key});

  @override
  State<ValidacionPage> createState() => _ValidacionPageState();
}

class _ValidacionPageState extends State<ValidacionPage> {
  late Orden orden = Orden.empty();

  List<ControlOrden> controles = [];
  String token = '';
  late String validacion = '';
  int count = 0;
  int desaprueba = 0;
  List<ControlOrden> listaGenerica = [];
  bool cargoDatosCorrectamente = false;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<OrdenProvider>().token;
    try {
      orden = context.read<OrdenProvider>().orden;
      controles = await OrdenControlServices().getControlOrden(context, orden, token);
      listaGenerica = controles.where((element) => element.controlRegId == 0).toList();
      count = listaGenerica.length;
      if(count == 0){
        listaGenerica = controles.where((element) => element.respuesta == 'DESAPRUEBA').toList();
        desaprueba = listaGenerica.length;
      }

      validacion = count > 0 ? 'Complete el cuestionario' : desaprueba == 0 ? 'Se valida' : 'No se valida';
      if (controles.isNotEmpty){
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
        title: const Text('Validación', style: TextStyle(color: Colors.white),),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Card(
                surfaceTintColor: Colors.white,
                elevation: 10,
                child: Text(
                  validacion,
                  style: TextStyle(fontSize: 35, color: count > 0 ? Colors.red : Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listaGenerica.length,
                itemBuilder: (context, i){
                  var control = listaGenerica[i];
                  return Card(
                    surfaceTintColor: Colors.white,
                    child: ListTile(
                      title: Text(control.grupo),
                      subtitle: Text(control.pregunta),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      // bottomNavigationBar: BottomAppBar(
      //   notchMargin: 10,
      //   elevation: 0,
      //   shape: const CircularNotchedRectangle(),
      //   color: Colors.grey.shade200,
      //   child: CustomButton(
      //     onPressed: () {},
      //     text: 'Confirmar',
      //     tamano: 20,
      //   ),
      // ),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
