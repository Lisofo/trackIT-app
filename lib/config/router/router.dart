import 'package:go_router/go_router.dart';
import 'package:app_track_it/pages/pages.dart';

final router = GoRouter(initialLocation: '/', routes: [
  GoRoute(path: '/', builder: (context, state) => const Login()),
  GoRoute(path: '/entradaSalida', builder: (context, state) => const EntradSalida()),
  GoRoute(path: '/listaOrdenes', builder: (context, state) => const ListaOrdenes()),
  GoRoute(path: '/ordenInterna', builder: (context, state) => const OrdenInterna()),
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
]);
