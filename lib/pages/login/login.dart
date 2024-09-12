// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously, avoid_print

import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_tec_sedel/services/login_service.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var isObscured;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();
  final userFocusNode = FocusNode();
  String user = '';
  String pass = '';
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _loginServices = LoginServices();

  @override
  void initState() {
    super.initState();
    isObscured = true;
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
        child: Scaffold(
      backgroundColor:  colors.primary,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/banner.jpg'),
            const SizedBox(height: 40),
            const CircleAvatar(
                radius: 70.5,
                backgroundImage: AssetImage('images/logo.jpg')),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextFormField(
                        controller: usernameController,
                        hint: 'Ingrese su usuario',
                        fillColor: Colors.white,
                        preffixIcon: const Icon(Icons.person),
                        prefixIconColor: colors.primary,
                        maxLines: 1,
                        validator: (value) {
                          if (value!.isEmpty || value.trim().isEmpty) {
                            return 'Ingrese un usuario valido';
                          }
                          return null;
                        },
                        onSaved: (newValue) => user = newValue!),
                    const SizedBox(
                      height: 20,
                    ),
                    CustomTextFormField(
                        controller: passwordController,
                        obscure: isObscured,
                        focusNode: passwordFocusNode,
                        keyboard: TextInputType.number,
                        maxLines: 1,
                        fillColor: Colors.white,
                        hint: 'Ingrese su contraseña',
                        preffixIcon: const Icon(Icons.lock),
                        prefixIconColor: colors.primary,
                        suffixIcon: IconButton(
                          icon: isObscured
                              ? const Icon(
                                  Icons.visibility_off,
                                  color: Colors.black,
                                )
                              : const Icon(
                                  Icons.visibility,
                                  color: Colors.black,
                                ),
                          onPressed: () {
                            setState(() {
                              isObscured = !isObscured;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value!.isEmpty || value.trim().isEmpty) {
                            return 'Ingrese su contraseña';
                          }
                          if (value.length < 6) {
                            return 'Contraseña invalida';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) async {
                          await login(context);
                        },
                        onSaved: (newValue) => pass = newValue!),
                    const SizedBox(
                      height: 30,
                    ),
                    CustomButton(
                      onPressed: () async {
                        await login(context);
                      },
                      text: 'Iniciar Sesión',
                      tamano: 25,
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
                        })
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: const Padding(
          padding:
              EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 5),
          child: Text(
            'info@integralsoft.com.uy | 099113500',
            style: TextStyle(fontWeight: FontWeight.bold),
          )
        ),
      ),
    ));
  }

  Future<void> login(BuildContext context) async {
    await _loginServices.login(
      usernameController.text,
      passwordController.text,
      context,
    );

    if (_formKey.currentState?.validate() == true) {
      var statusCode = await _loginServices.getStatusCode();
      await _loginServices.resetStatusCode();
      if (statusCode == 1) {
        context.pushReplacement('/entradaSalida');
      } else if (statusCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revise su conexión'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (statusCode >= 400 && statusCode < 500){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas. Intente nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        print('Credenciales inválidas. Intente nuevamente.');
      }
    }
  }
}
