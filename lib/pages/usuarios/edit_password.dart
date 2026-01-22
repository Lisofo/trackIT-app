import 'package:app_tec_sedel/models/usuario.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/usuarios_provider.dart';
import 'package:app_tec_sedel/services/usuario_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditPassword extends StatefulWidget {
  const EditPassword({super.key});

  @override
  State<EditPassword> createState() => _EditPasswordState();
}

class _EditPasswordState extends State<EditPassword> {
  final _userServices = UserServices();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _pinController = TextEditingController();
  final _rePinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _rePasswordController.dispose();
    _pinController.dispose();
    _rePinController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final Usuario userSeleccionado = context.read<UsuariosProvider>().usuario;
      final token = context.read<AuthProvider>().token;
      
      await _userServices.patchPwd(
        context,
        userSeleccionado.usuarioId.toString(),
        _passwordController.text,
        _pinController.text,
        token,
      );
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: _buildForm(context, false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Establecer Contraseña'),
        centerTitle: true,
        elevation: 1,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: _buildForm(context, true),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) ...[
            const SizedBox(height: 8),
            Text(
              'Configurar Credenciales',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Configuración de Acceso',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],

          // Campo de Contraseña
          _buildFormField(
            context: context,
            label: 'Contraseña',
            hintText: 'Ingrese nueva contraseña',
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              if (value.length < 6 || value.length > 12) {
                return 'Debe tener entre 6 y 12 caracteres';
              }
              return null;
            },
            isMobile: isMobile,
            isPassword: true,
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Campo de Confirmar Contraseña
          _buildFormField(
            context: context,
            label: 'Confirmar Contraseña',
            hintText: 'Reingrese la contraseña',
            controller: _rePasswordController,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
            isMobile: isMobile,
            isPassword: true,
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Campo de PIN
          _buildFormField(
            context: context,
            label: 'PIN',
            hintText: 'Ingrese nuevo PIN (opcional)',
            controller: _pinController,
            validator: (value) {
              if (value!.isNotEmpty && value.length != 4 && value.length != 6) {
                return 'El PIN debe tener 4 o 6 dígitos';
              }
              return null;
            },
            isMobile: isMobile,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Campo de Confirmar PIN
          _buildFormField(
            context: context,
            label: 'Confirmar PIN',
            hintText: 'Reingrese el PIN',
            controller: _rePinController,
            validator: (value) {
              if (_pinController.text.isNotEmpty && value != _pinController.text) {
                return 'Los PIN no coinciden';
              }
              return null;
            },
            isMobile: isMobile,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          const SizedBox(height: 32),

          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outline.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Requisitos:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Contraseña: 6-12 caracteres'),
                      SizedBox(height: 4),
                      Text('• PIN: 4 o 6 dígitos (opcional)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Botón de Guardar
          if (isMobile)
            _buildMobileSaveButton(context, colors)
          else
            _buildDesktopSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required BuildContext context,
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    required bool isMobile,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 14 : 15,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile ? double.infinity : 400,
          child: CustomTextFormField(
            controller: controller,
            label: hintText,
            maxLines: 1,
            obscure: isPassword,
            keyboard: keyboardType,
            maxLength: maxLength,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSaveButton(BuildContext context, ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _saveChanges(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, color: colors.onPrimary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSaveButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomButton(
          onPressed: () => _saveChanges(context),
          text: 'Guardar Cambios',
          tamano: 16,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }
}