// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'dart:convert';

import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/marcas.dart';
import 'package:app_tec_sedel/models/ubicacion.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/marcas_services.dart';
import 'package:app_tec_sedel/services/ubicacion_services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntradSalida extends StatefulWidget {
  const EntradSalida({super.key});

  @override
  State<EntradSalida> createState() => _EntradSalidaState();
}

class _EntradSalidaState extends State<EntradSalida> {
  late String _currentPosition = '';
  late Ubicacion ubicacion = Ubicacion.empty();
  late Marca marca = Marca.empty();
  late String nombreUsuario = '';
  bool ejecutandoEntrada = false;
  bool ejecutandoSalida = false;
  late int tecnicoId = 0;
  late String token = '';
  final _marcasServices = MarcasServices();
  final _ubicacionServices = UbicacionServices();
  int? statusCode;
  bool marcando = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    nombreUsuario = context.read<OrdenProvider>().nombreUsuario;
    tecnicoId = context.read<OrdenProvider>().tecnicoId;
    token = context.read<OrdenProvider>().token;
    await obtenerObjeto();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: const Text('¿Desea salir de la aplicación?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí'),
              ),
            ],
          ),
        );
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: colors.primary,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/banner.jpg'),
              const SizedBox(height: 20),
              CircleAvatar(
                backgroundColor: Colors.grey.shade800,
                radius: 55.5,
                child: const Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                nombreUsuario,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold),
              ),
              if (marca.marcaId != 0) ...[
                Text(
                  'Tiene una entrada iniciada a la hora ${marca.desde}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                )
              ] else ...[
                const Text(
                  'No marcó entrada aún',
                  style: TextStyle(color: Colors.white),
                )
              ],
              const SizedBox(
                height: 20,
              ),
              CustomButton(
                onPressed: marca.marcaId == 0 ? () {
                  marcando = true;
                  setState(() {});
                  marcarEntrada();
                } : null,
                text: 'Marcar entrada',
                disabled: marca.marcaId != 0 || marcando,
              ),
              const SizedBox(
                height: 20,
              ),
              CustomButton(
                onPressed: marca.marcaId != 0 ? () {
                  marcando = true;
                  setState(() {});
                  marcarSalida();
                } : null,
                text: 'Marcar Salida',
                disabled: marca.marcaId == 0 || marcando,
              ),
              const SizedBox(
                height: 30,
              ),
              CustomButton(
                onPressed: !marcando ? () {
                  router.push('/listaOrdenes');
                } : null ,
                text: 'Revisar Ordenes',
                disabled: marcando,
              ),
              const SizedBox(
                height: 100,
              ),
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (BuildContext context,
                    AsyncSnapshot<PackageInfo> snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Versión ${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})',
                      style: const TextStyle(color: Colors.white),
                    );
                  } else {
                    return const Text('Cargando la app...');
                  }
                }
              ),
              const Expanded(child: Text('')),
            ],
          ),
          bottomNavigationBar: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 5),
              child: Text(
                'info@integralsoft.com.uy | 099113500',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  obtenerUbicacion() async {
    await getLocation();
    int uId = context.read<OrdenProvider>().uId;
    ubicacion.fecha = DateTime.now();
    ubicacion.usuarioId = uId;
    ubicacion.ubicacion = _currentPosition;
    await _ubicacionServices.postUbicacion(context, ubicacion, token);
    statusCode = await _ubicacionServices.getStatusCode();
    await _ubicacionServices.resetStatusCode();
  }

  marcarEntrada() async {
    if (!ejecutandoEntrada) {
      ejecutandoEntrada = true;
      if (marca.marcaId == 0) {
        await obtenerUbicacion();
        if (statusCode == 1){
          int ubicacionId = ubicacion.ubicacionId;
          if(ubicacionId != 0){
            marca = Marca.empty();
            marca.tecnicoId = tecnicoId;
            marca.desde = DateTime.now();
            marca.ubicacionId = ubicacionId;
            await _marcasServices.postMarca(context, marca, token);
            statusCode = await _marcasServices.getStatusCode();
            await _marcasServices.getStatusCode();
            if (statusCode == 1){
              guardarObjeto(marca);
            }
          }
        }
        statusCode = null;
        setState(() {});
      } else {
        MarcasServices.showDialogs(context, 'Ya tiene una entrada inciada', false, false);
        statusCode = null;
      }
      print('hola entrada');
      ejecutandoEntrada = false;
    }
    marcando = false;
  }

  marcarSalida() async {
    List<Orden> ordenesEnProceso = context.read<OrdenProvider>().ordenesEnProceso;
    if (!ejecutandoSalida) {
      ejecutandoSalida = true;
      if (marca.marcaId != 0) {
        bool confirmacion = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              surfaceTintColor: Colors.white,
              title: const Text('Mensaje'),
              content: const Text('¿Estás seguro de querer marcar salida?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    marcando = false;
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('SALIR'),
                ),
              ],
            );
          },
        );
        ordenesEnProceso = ordenesEnProceso.where((orden) => orden.estado == 'EN PROCESO').toList();
        if (ordenesEnProceso.isEmpty && confirmacion == true) {
          await obtenerUbicacion();
          if (statusCode == 1){
            int ubicacionId = ubicacion.ubicacionId;
            marca.hasta = DateTime.now();
            marca.ubicacionIdHasta = ubicacionId;
            await _marcasServices.putMarca(context, marca, token);
            statusCode = await _marcasServices.getStatusCode();
            _marcasServices.resetStatusCode();
            if (statusCode == 1) {
              Provider.of<OrdenProvider>(context, listen: false).setMarca(0);
              _borrarIdLocal();
            }
            statusCode = null;
            setState(() {});
          }
        } else if(ordenesEnProceso.isNotEmpty){
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                surfaceTintColor: Colors.white,
                title: const Text('Advertencia'),
                content: const Text('Revise las ordenes que le quedaron en proceso'),
                actions: [
                  TextButton(
                    onPressed: () {
                      marcando = false;
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK')
                  )
                ],
              );
            }
          );
        } else {
          marcando = false;
          setState(() {});
        }
      } else {
        MarcasServices.showDialogs(context, 'Marque entrada para luego marcar salida', false, false);
      }
      print('chau salida');
      ejecutandoSalida = false;
    }
    marcando = false;
    setState(() {});
  }

  Future<void> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _currentPosition = '${position.latitude}, ${position.longitude}';
        print('${position.latitude}, ${position.longitude}');
      });
    } catch (e) {
      setState(() {
        _currentPosition = 'Error al obtener la ubicación: $e';
      });
    }
  }

  _borrarIdLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      marca = Marca.empty();
      prefs.setString('marcaConDatos', jsonEncode(marca));
    });
  }

  void guardarObjeto(Marca objeto) async {
    final prefs = await SharedPreferences.getInstance();
    print(objeto.toMap().toString());
    await prefs.setString('marcaConDatos', jsonEncode(objeto.toMap()));
  }

  Future obtenerObjeto() async {
    marca = await MarcasServices().getUltimaMarca(context, tecnicoId, token);
    // final prefs = await SharedPreferences.getInstance();
    // final jsonString = prefs.getString('marcaConDatos');
    // if (jsonString != null) {
    //   print(jsonString);
    //   final map = jsonDecode(jsonString);
    //   marca = Marca.fromJson(map);
    // }
    Provider.of<OrdenProvider>(context, listen: false).setMarca(marca.marcaId);
    setState(() {});
    return;
  }
}
