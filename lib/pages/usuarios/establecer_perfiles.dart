// ignore_for_file: use_build_context_synchronously

import 'package:app_tec_sedel/models/perfil.dart';
import 'package:app_tec_sedel/models/perfil_usuario.dart';
import 'package:app_tec_sedel/models/usuario.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/usuarios_provider.dart';
import 'package:app_tec_sedel/services/usuario_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EstablecerPerfiles extends StatefulWidget {
  const EstablecerPerfiles({super.key});

  @override
  State<EstablecerPerfiles> createState() => _EstablecerPerfilesState();
}

class _EstablecerPerfilesState extends State<EstablecerPerfiles> {
  late List<Perfil> perfiles = [];
  late String token = '';
  late List<int> perfilesId = [];
  late List<PerfilUsuario> perfilesUsuario = [];
  late Usuario user = Usuario.empty();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      setState(() => isLoading = true);
      
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UsuariosProvider>();
      token = authProvider.token;
      user = userProvider.usuario;
      
      final [perfilesData, perfilesUsuarioData] = await Future.wait([
        UserServices().getPerfiles(context, token),
        UserServices().getUsuarioPerfiles(context, user, token),
      ]);
      
      perfiles = perfilesData;
      perfilesUsuario = perfilesUsuarioData;
      perfilesId.clear();
      
      for (var perfil in perfiles) {
        final bool activo = perfilesUsuario.any((pu) => pu.perfilId == perfil.perfilId);
        perfil.activo = activo;
        if (activo) {
          perfilesId.add(perfil.perfilId);
        }
      }
    } catch (error) {
      // Manejo de error podría ir aquí
      rethrow;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> togglePerfil(Perfil perfil, bool value) async {
    setState(() => perfil.activo = value);
    
    try {
      if (value) {
        perfilesId.add(perfil.perfilId);
        await UserServices().postUsuarioPerfiles(context, user, perfil.perfilId, token);
      } else {
        perfilesId.remove(perfil.perfilId);
        await UserServices().deleteUsuarioPerfiles(context, user, perfil.perfilId, token);
      }
    } catch (error) {
      // Revertir cambios en caso de error
      setState(() => perfil.activo = !value);
      if (value) {
        perfilesId.remove(perfil.perfilId);
      } else {
        perfilesId.add(perfil.perfilId);
      }
      // Podrías mostrar un snackbar de error aquí
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfiles de: ${user.nombre}'),
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(title: Text('Establecer perfiles de usuario ${user.nombre}'), foregroundColor: Colors.white,),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (perfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay perfiles disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Selecciona los perfiles para ${user.nombre}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: perfiles.length,
            itemBuilder: (context, i) {
              return Container(
                decoration: BoxDecoration(
                  color: perfiles[i].activo 
                    ? Colors.blue.shade50.withOpacity(0.5)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  value: perfiles[i].activo,
                  onChanged: (value) => togglePerfil(perfiles[i], value),
                  title: Text(
                    perfiles[i].nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: perfiles[i].activo 
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade800,
                    ),
                  ),
                  subtitle: perfiles[i].descripcion.isNotEmpty == true
                      ? Text(
                          perfiles[i].descripcion,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  secondary: Icon(
                    perfiles[i].activo ? Icons.verified : Icons.person_outline,
                    color: perfiles[i].activo 
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
                  ),
                  activeColor: Theme.of(context).primaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(height: 4);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${perfilesId.length} de ${perfiles.length} perfiles seleccionados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Definimos los breakpoints para responsividad
          if (constraints.maxWidth < 600) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }
}