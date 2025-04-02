import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/widgets/drawer.dart';
import 'package:flutter/material.dart';

class AdmingPage extends StatefulWidget {
  const AdmingPage({super.key});

  @override
  State<AdmingPage> createState() => _AdmingPageState();
}

class _AdmingPageState extends State<AdmingPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(
            color: colors.onPrimary
          ),
          actions: [
            IconButton(
              onPressed: () {router.pop();},
              icon: const Icon(Icons.arrow_back)
            )
          ],
        ),
        drawer: const Drawer(
          child: BotonesDrawer(),
        ),
      )
    );
  }
}