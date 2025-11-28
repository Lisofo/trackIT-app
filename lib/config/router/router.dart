import 'package:app_tec_sedel/pages/camera/camera_screen.dart';
import 'package:app_tec_sedel/pages/dashboard/dashboard.dart';
import 'package:app_tec_sedel/pages/monitor/mapa.dart';
import 'package:app_tec_sedel/pages/monitorOrdenes/planilla_consumos.dart';
import 'package:go_router/go_router.dart';
import 'package:app_tec_sedel/pages/pages.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Login()),
    GoRoute(path: '/entradaSalida', builder: (context, state) => const EntradSalida()),
    GoRoute(path: '/listaOrdenes', builder: (context, state) => const ListaOrdenesConBusqueda()),
    GoRoute(path: '/ordenInterna', builder: (context, state) => const OrdenInternaHorizontal()),
    GoRoute(path: '/ptosInspeccion', builder: (context, state) => const PtosInspeccionPage()),
    GoRoute(path: '/ptosInspeccionActividad', builder: (context, state) => const PtosInspeccionActividad()),
    GoRoute(path: '/ptosInspeccionRevision', builder: (context, state) => const PtosInspeccionRevisionPage()),
    GoRoute(path: '/cuestionario', builder: (context, state) => const CuestionarioPage()),
    GoRoute(path: '/firmas', builder: (context, state) => const Firma()),
    GoRoute(path: '/materialesDiagnostico', builder: (context, state) => const MaterialesDiagnosticoPage()),
    GoRoute(path: '/materiales', builder: (context, state) => const MaterialesPage()),
    GoRoute(path: '/observaciones', builder: (context, state) => const ObservacionesPage()),
    GoRoute(path: '/plagas', builder: (context, state) => const PlagasPage()),
    GoRoute(path: '/tareas', builder: (context, state) => const TareasPage()),
    GoRoute(path: '/validacion', builder: (context, state) => const ValidacionPage()),
    GoRoute(path: '/resumenOrden', builder: (context, state) => const ResumenOrden()),
    GoRoute(path: '/admin', builder: (context, state) => const AdmingPage(),),
    GoRoute(path: '/monitorOrdenes', builder: (context, state) => const MonitorOrdenes(),),
    GoRoute(path: '/monitorClientes', builder: (context, state) => const MonitorClientes(),),
    GoRoute(path: '/monitorVehiculos', builder: (context, state) => const MonitorVehiculos(),),
    GoRoute(path: '/monitorTareas', builder: (context, state) => const MonitorTareas(),),
    GoRoute(path: '/monitorMateriales', builder: (context, state) => const MonitorMateriales(),),
    GoRoute(path: '/monitorTecnicos', builder: (context, state) => const MonitorTecnicos(),),
    GoRoute(path: '/Dashboard', builder: (context, state) => const DashboardPage(),),
    GoRoute(path: '/mapa', builder: (context, state) => const MapaPage(),),
    GoRoute(path: '/camera', builder: (context, state) => const CameraGalleryScreen(),),
    GoRoute(path: '/planillaConsumos', builder: (context, state) => const ConsumosScreen(),),
  ],
  errorBuilder: (context, state) => const ErrorPage(),
);