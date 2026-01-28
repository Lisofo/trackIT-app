import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/clientes_firmas.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/models/revision_tarea.dart';
import 'package:app_tec_sedel/pages/pages.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/menu_providers.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/widgets/icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class RevisionOrdenMain extends StatefulWidget {
  const RevisionOrdenMain({super.key});

  @override
  State<RevisionOrdenMain> createState() => _RevisionOrdenMainState();
}

class _RevisionOrdenMainState extends State<RevisionOrdenMain> with SingleTickerProviderStateMixin {
  final TextEditingController comentarioController = TextEditingController();
  late Orden orden = Orden.empty();
  late AnimationController _animationController;
  
  late List<Materiales> materiales = [];
  late List<RevisionMaterial> revisionMaterialesList = [];
  late List<RevisionTarea> revisionTareasList = [];
  late int revisionId = 0;
  late String token = '';
  late String menu = '';
  int selectedIndex = 0;
  late List<ClienteFirma> firmas = [];
  bool filtro = false;
  int buttonIndex = 0;
  String valorComentario = '';
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    cargarDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  cargarDatos() async {
    orden = context.read<OrdenProvider>().orden;
    revisionId = orden.otRevisionId!;
    token = context.read<AuthProvider>().token;
    firmas = await RevisionServices().getRevisionFirmas(context, orden, token);
    materiales = await MaterialesServices().getMateriales(context, token);
    revisionMaterialesList = await MaterialesServices().getRevisionMateriales(context, orden, token);
    revisionTareasList = await RevisionServices().getRevisionTareas(context, orden, token);
    
    setState(() {});
  }


  Widget _buildMenuList() {
    final colors = Theme.of(context).colorScheme;
    // Verifica si tipoOrden es nulo antes de usarlo
    if (orden.tipoOrden?.codTipoOrden == null) {
      return const Center(child: Text('No se puede cargar el menú'));
    }
    
    final String? tipoOrden = orden.tipoOrden!.codTipoOrden;

    return FutureBuilder(
      future: menuProvider.cargarDataDrawer(context, tipoOrden!, token),
      initialData: const [],
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        } else if(snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        } else {
          final List<DrawerOpcion> rutas = snapshot.data as List<DrawerOpcion>;

          return ListView.separated(
            itemCount: rutas.length,
            itemBuilder: (context, i) {
              final ruta = rutas[i];
              return ListTile(
                title: Text(ruta.texto),
                leading: getIcon(ruta.icon, context),
                trailing: Icon(
                  Icons.keyboard_arrow_right,
                  color: colors.secondary,
                ),
                onTap: () {
                  menu = ruta.texto;
                  if (MediaQuery.of(context).size.width < 600) {
                    router.pop();
                  }
                  setState(() {});
                } 
              );
            }, 
            separatorBuilder: (BuildContext context, int index) { return const Divider(); },
          ); 
        }
      }
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text('Revisión orden ${orden.ordenTrabajoId}  ${orden.cliente?.codCliente} - ${orden.cliente?.nombre}')
      ),
      
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 395,
              width: 300,
              child: Card(
                child: Column(
                  children: [
                    Expanded(child: _buildMenuList()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisión orden ${orden.ordenTrabajoId}'), 
        foregroundColor: colors.onPrimary,
        actions:[
          IconButton(
            onPressed: () {router.pop();},
            icon: const Icon(Icons.arrow_back)
          )
        ]
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: _buildMenuList()),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (menu.isEmpty) {
      return const Center(child: Text('Seleccione una opción del menú'));
    }

    // ignore: unused_local_variable
    final isReadOnly = orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADO';

    switch (menu) {
      case 'Tareas Realizadas':
        return const TareasPage(
          fromRevisionMenu: true,
          isReadOnly: true,
        );
      case 'Materiales utilizados':
        return const MaterialesPage(
          fromRevisionMenu: true,
          isReadOnly: true,
        );
      case 'Firmas':
        return const Firma(
          fromRevisionMenu: true,
          isReadOnly: true,
        );
      case 'Incidencias':
        return const CameraGalleryScreen(
          fromRevisionMenu: true,
          isReadOnly: true,
        );
      default:
        return Center(child: Text('Contenido para: $menu'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _isMobile = constraints.maxWidth < 800;
          return _isMobile ? _buildMobileLayout() : _buildDesktopLayout();
        },
      ),
    );
  }
}