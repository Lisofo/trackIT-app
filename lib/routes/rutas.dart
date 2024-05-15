import 'package:flutter/material.dart';
import 'package:app_track_it/pages/drawerPages/cuestionario_page.dart';
import 'package:app_track_it/pages/drawerPages/firma_page.dart';
import 'package:app_track_it/pages/drawerPages/observaciones_page.dart';
import 'package:app_track_it/pages/drawerPages/validacion_page.dart';
import 'package:app_track_it/pages/entrada/entrada_salida.dart';
import 'package:app_track_it/pages/listaDeOrdenes/lista_ordenes.dart';
import 'package:app_track_it/pages/ordenInterna/orden_interna.dart';
import '../pages/drawerPages/materiales_page.dart';
import '../pages/drawerPages/plagas_page.dart';
import '../pages/drawerPages/ptosDeInspeccio/ptosInspeccion_page.dart';
import '../pages/drawerPages/tareas_page.dart';
import '../pages/login/login.dart';

Map<String, WidgetBuilder> getAppRoutes() {
  return <String, WidgetBuilder>{
    '/': (context) => const Login(),
    'entradaSalida': (context) => const EntradSalida(),
    'listaOrdenes': (context) => const ListaOrdenes(),
    'ordenInterna': (context) => const OrdenInterna(),
    'tareas': (context) => const TareasPage(),
    'plagas': (context) => const PlagasPage(),
    'ptosInspeccion': (context) => const PtosInspeccionPage(),
    'materiales': (context) => const MaterialesPage(),
    // 'materialesDiagnostico': (context) => MaterialesDiagnosticoPage(),
    "observaciones": (context) => const ObservacionesPage(),
    "firmas": (context) => const Firma(),
    "cuestionario": (context) => const CuestionarioPage(),
    "validacion": (context) => const ValidacionPage(),
    // 'ptosInspeccionActividad/mantenimiento': (context) =>
    //     PtosInspeccionActividad(),
  };
}
