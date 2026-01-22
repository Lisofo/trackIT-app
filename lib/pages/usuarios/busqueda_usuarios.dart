// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/usuario.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/usuarios_provider.dart';
import 'package:app_tec_sedel/services/usuario_services.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _userServices = UserServices();
  final _apellidoController = TextEditingController();
  final _loginController = TextEditingController();
  final _nombreController = TextEditingController();
  
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _apellidoController.dispose();
    _loginController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _buscarUsuarios(BuildContext context, String token) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _userServices.getUsers(
        context,
        _loginController.text.trim(),
        _nombreController.text.trim(),
        _apellidoController.text.trim(),
        token,
      );

      setState(() {
        _usuarios = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar usuarios: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _limpiarFiltros() {
    _loginController.clear();
    _nombreController.clear();
    _apellidoController.clear();
    setState(() {
      _usuarios = [];
      _errorMessage = null;
    });
  }

  void _navegarAEditarUsuario(Usuario? usuario) {
    final provider = Provider.of<UsuariosProvider>(context, listen: false);
    
    if (usuario == null) {
      provider.clearSelectedUsuario();
    } else {
      provider.setUsuario(usuario);
    }
    
    router.push('/editUsuarios');
  }

  Widget _buildFiltros(BuildContext context, String token, bool isMobile) {
    final colors = Theme.of(context).colorScheme;
    
    if (isMobile) {
      return Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Filtrar Usuarios',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildCampoFiltro(
                context: context,
                label: 'Login',
                controller: _loginController,
                icon: Icons.person_outline,
                onSubmitted: () => _buscarUsuarios(context, token),
              ),
              const SizedBox(height: 16),
              _buildCampoFiltro(
                context: context,
                label: 'Nombre',
                controller: _nombreController,
                icon: Icons.badge_outlined,
                onSubmitted: () => _buscarUsuarios(context, token),
              ),
              const SizedBox(height: 16),
              _buildCampoFiltro(
                context: context,
                label: 'Apellido',
                controller: _apellidoController,
                icon: Icons.family_restroom_outlined,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _limpiarFiltros,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.surfaceVariant,
                        foregroundColor: colors.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _buscarUsuarios(context, token),
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _navegarAEditarUsuario(null),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Nuevo Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(right: BorderSide(color: colors.outline.withOpacity(0.2))),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros de Búsqueda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete uno o más campos para buscar usuarios',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            _buildCampoFiltro(
              context: context,
              label: 'Login',
              controller: _loginController,
              icon: Icons.person_outline,
              onSubmitted: () => _buscarUsuarios(context, token),
            ),
            const SizedBox(height: 20),
            _buildCampoFiltro(
              context: context,
              label: 'Nombre',
              controller: _nombreController,
              icon: Icons.badge_outlined,
              onSubmitted: () => _buscarUsuarios(context, token),
            ),
            const SizedBox(height: 20),
            _buildCampoFiltro(
              context: context,
              label: 'Apellido',
              controller: _apellidoController,
              icon: Icons.family_restroom_outlined,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _buscarUsuarios(context, token),
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navegarAEditarUsuario(null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCampoFiltro({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextFormField(
          controller: controller,
          maxLines: 1,
          label: label,
          preffixIcon: Icon(icon, size: 20),
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        ),
      ],
    );
  }

  Widget _buildListaUsuarios(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando usuarios...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final token = context.read<AuthProvider>().token;
                _buscarUsuarios(context, token);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              color: colors.onSurface.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intente con otros filtros de búsqueda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _usuarios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final usuario = _usuarios[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  usuario.usuarioId.toString(),
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              '${usuario.nombre} ${usuario.apellido}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.login,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                if (usuario.login.isNotEmpty)
                  Text(
                    usuario.login,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colors.onSurface.withOpacity(0.6),
            ),
            onTap: () => _navegarAEditarUsuario(usuario),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    final usuariosProvider = context.watch<UsuariosProvider>();

    if (usuariosProvider.needsRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        usuariosProvider.clearRefreshFlag();
        _buscarUsuarios(context, token); // Volver a buscar
      });
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

          return Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
              foregroundColor: Colors.white,
              title: const Text('Gestión de Usuarios'),
              actions: [
                if (isMobile)
                  IconButton(
                    onPressed: () {router.pop();},
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver',
                  )
              ],
            ),
            drawer: isMobile ? _buildFiltros(context, token, true) : null,
            drawerEnableOpenDragGesture: false,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) _buildFiltros(context, token, false),
                Expanded(
                  child: FutureBuilder(
                    future: Future.value(_usuarios),
                    builder: (context, snapshot) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildListaUsuarios(context),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: isMobile
                ? FloatingActionButton.extended(
                    onPressed: () => _navegarAEditarUsuario(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  )
                : null,
          );
        },
      ),
    );
  }
}