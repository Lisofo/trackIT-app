import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/usuario.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/usuarios_provider.dart';
import 'package:app_tec_sedel/services/usuario_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddUsuarioPage extends StatefulWidget {
  const AddUsuarioPage({super.key});

  @override
  State<AddUsuarioPage> createState() => _AddUsuarioPageState();
}

class _AddUsuarioPageState extends State<AddUsuarioPage> {
  final _userServices = UserServices();
  final _loginController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _buttonIndex = 0;
  bool _isLoading = false;
  bool _isInitialized = false; // Para controlar si ya se inicializó

  @override
  void initState() {
    super.initState();
    // Inicializar controladores después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    final user = context.read<UsuariosProvider>().usuario;
    
    // Limpiar todos los controladores primero
    _loginController.clear();
    _nombreController.clear();
    _apellidoController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    
    // Solo llenar con datos si es un usuario existente
    if (user.usuarioId != 0) {
      _loginController.text = user.login;
      _nombreController.text = user.nombre;
      _apellidoController.text = user.apellido;
      _direccionController.text = user.direccion;
      _telefonoController.text = user.telefono;
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actualizar cuando cambie el usuario en el provider
    final user = context.watch<UsuariosProvider>().usuario;
    
    if (!_isInitialized) {
      return; // No hacer nada si aún no se inicializó
    }
    
    // Solo actualizar si el usuario ha cambiado y es un usuario existente
    if (user.usuarioId != 0) {
      // Verificar si los valores son diferentes para evitar actualizaciones innecesarias
      if (_loginController.text != user.login) {
        _loginController.text = user.login;
      }
      if (_nombreController.text != user.nombre) {
        _nombreController.text = user.nombre;
      }
      if (_apellidoController.text != user.apellido) {
        _apellidoController.text = user.apellido;
      }
      if (_direccionController.text != user.direccion) {
        _direccionController.text = user.direccion;
      }
      if (_telefonoController.text != user.telefono) {
        _telefonoController.text = user.telefono;
      }
    } else {
      // Para nuevo usuario, asegurarse de que los campos estén vacíos
      if (_loginController.text.isNotEmpty) _loginController.clear();
      if (_nombreController.text.isNotEmpty) _nombreController.clear();
      if (_apellidoController.text.isNotEmpty) _apellidoController.clear();
      if (_direccionController.text.isNotEmpty) _direccionController.clear();
      if (_telefonoController.text.isNotEmpty) _telefonoController.clear();
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarUsuario(BuildContext context, Usuario userSeleccionado, String token) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      userSeleccionado.login = _loginController.text.trim();
      userSeleccionado.nombre = _nombreController.text.trim();
      userSeleccionado.apellido = _apellidoController.text.trim();
      userSeleccionado.direccion = _direccionController.text.trim();
      userSeleccionado.telefono = _telefonoController.text.trim();

      try {
        if (userSeleccionado.usuarioId != 0) {
          await _userServices.putUsuario(context, userSeleccionado, token);
        } else {
          await _userServices.postUsuario(context, userSeleccionado, token);
          // Después de crear, mostrar mensaje de éxito y cerrar
          if (mounted) {
            await UserServices.showDialogs(
              context, 
              'Usuario creado correctamente', 
              false, // doblePop
              false
            );
          }
        }
      } catch (e) {
        // El error ya se maneja en UserServices
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _eliminarUsuarioDialog(BuildContext context, Usuario userSeleccionado, String token) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: const Text('¿Desea borrar el usuario?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _userServices.deleteUser(context, userSeleccionado, token);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Borrar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isMobile = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: isMobile ? 100 : 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomTextFormField(
              controller: controller,
              label: hint,
              maxLines: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Usuario user, String token, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuario'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.usuarioId != 0 ? 'Editar Usuario' : 'Nuevo Usuario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFormField(
                          label: 'Login:',
                          controller: _loginController,
                          hint: 'login',
                        ),
                        _buildFormField(
                          label: 'Nombre:',
                          controller: _nombreController,
                          hint: 'Nombre',
                        ),
                        _buildFormField(
                          label: 'Apellido:',
                          controller: _apellidoController,
                          hint: 'Apellido',
                        ),
                        _buildFormField(
                          label: 'Dirección:',
                          controller: _direccionController,
                          hint: 'Dirección',
                        ),
                        _buildFormField(
                          label: 'Teléfono:',
                          controller: _telefonoController,
                          hint: 'Teléfono',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDesktopButtons(user, token, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Usuario user, String token, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuario'),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                user.usuarioId != 0 ? 'Editar Usuario' : 'Nuevo Usuario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFormField(
                          label: 'Login:',
                          controller: _loginController,
                          hint: 'login',
                          isMobile: true,
                        ),
                        _buildFormField(
                          label: 'Nombre:',
                          controller: _nombreController,
                          hint: 'Nombre',
                          isMobile: true,
                        ),
                        _buildFormField(
                          label: 'Apellido:',
                          controller: _apellidoController,
                          hint: 'Apellido',
                          isMobile: true,
                        ),
                        _buildFormField(
                          label: 'Dirección:',
                          controller: _direccionController,
                          hint: 'Dirección',
                          isMobile: true,
                        ),
                        _buildFormField(
                          label: 'Teléfono:',
                          controller: _telefonoController,
                          hint: 'Teléfono',
                          isMobile: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildMobileBottomNav(user, token, context),
    );
  }

  Widget _buildDesktopButtons(Usuario user, String token, BuildContext context) {
    if (user.usuarioId != 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomButton(
            text: 'Perfiles',
            onPressed: () => router.push('/establecerPerfiles'),
            tamano: 16,
          ),
          const SizedBox(width: 12),
          CustomButton(
            text: 'Contraseña',
            onPressed: () => router.push('/editPassword'),
            tamano: 16,
          ),
          const SizedBox(width: 24),
          CustomButton(
            text: 'Guardar',
            onPressed: _isLoading ? null : () => _guardarUsuario(context, user, token),
            tamano: 16,
          ),
          const SizedBox(width: 12),
          CustomButton(
            text: 'Eliminar',
            onPressed: () => _eliminarUsuarioDialog(context, user, token),
            tamano: 16,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomButton(
            text: 'Guardar',
            onPressed: _isLoading ? null : () => _guardarUsuario(context, user, token),
            tamano: 16,
          ),
          const SizedBox(width: 12),
          CustomButton(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
            tamano: 16, 
          ),
        ],
      );
    }
  }

  Widget _buildMobileBottomNav(Usuario user, String token, BuildContext context) {
    if (user.usuarioId != 0) {
      return BottomNavigationBar(
        currentIndex: _buttonIndex,
        onTap: (index) async {
          setState(() => _buttonIndex = index);
          switch (index) {
            case 0:
              router.push('/establecerPerfiles');
              break;
            case 1:
              router.push('/editPassword');
              break;
            case 2:
              await _guardarUsuario(context, user, token);
              break;
            case 3:
              await _eliminarUsuarioDialog(context, user, token);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Perfiles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: 'Contraseña',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.save),
            label: 'Guardar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'Eliminar',
          ),
        ],
      );
    } else {
      return BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Guardar',
                  onPressed: _isLoading ? null : () => _guardarUsuario(context, user, token),
                  tamano: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  onPressed: () => Navigator.of(context).pop(),
                  tamano: 14,                  
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UsuariosProvider>().usuario;
    final token = context.watch<AuthProvider>().token;

    // Mostrar loading solo mientras se inicializa
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return _buildMobileLayout(user, token, context);
        } else {
          return _buildDesktopLayout(user, token, context);
        }
      },
    );
  }
}