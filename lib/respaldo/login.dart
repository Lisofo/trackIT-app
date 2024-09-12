// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var isObscured;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    isObscured = true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
        child: Scaffold(
      backgroundColor: colors.primary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('images/logo.jpg'),
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 70.5,
            backgroundImage: NetworkImage(
                'https://e1.pxfuel.com/desktop-wallpaper/714/204/desktop-wallpaper-goku-gucci-goku-drip-thumbnail.jpg'),
          ),
          const Text(
            'LUCAS DÍAZ',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Encargado de X',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Form(
                key: _formKey,
                child: TextFormField(
                  obscureText: isObscured,
                  focusNode: passwordFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(20)),
                      fillColor: Colors.white,
                      filled: true,
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: const Color.fromARGB(255, 41, 146, 41),
                      suffixIcon: IconButton(
                        padding: const EdgeInsetsDirectional.only(end: 12.0),
                        icon: isObscured
                            ? const Icon(
                                Icons.visibility_off,
                                color: Colors.black,
                              )
                            : const Icon(Icons.visibility, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                      hintText: 'Contraseña'),
                )),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text(
                    '¿Haz olvidado tu contraseña?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w200,
                        fontSize: 12),
                  ),
                  onPressed: () {},
                )
              ],
            ),
          ),
          ElevatedButton(
              style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  elevation: WidgetStatePropertyAll(10),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(50),
                          right: Radius.circular(50))))),
              onPressed: () {
                Navigator.pushNamed(context, 'entradaSalida');
              },
              child: Text(
                'Iniciar Sesión',
                style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              )),
          const Expanded(child: Text('')),
          Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.only(
                  left: 16, right: 16, top: 10, bottom: 5),
              child: Text(
                'sedel@sedel.com.uy | 23623375 | +598 98 729 117',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    ));
  }
}
