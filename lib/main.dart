import 'dart:io';
import 'package:flutter/foundation.dart'; // Añade este import

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/router/router.dart';
import 'config/theme/app_theme.dart';
import 'providers/orden_provider.dart';

const String flavor = String.fromEnvironment('FLAVOR');
const bool isProd = bool.fromEnvironment('IS_PROD', defaultValue: false);
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      print('Error al cargar cámaras: $e');
    }
  } else {
    cameras = [];
    if (kIsWeb) {
      print("Cámara deshabilitada en web.");
    } else {
      print("Cámara deshabilitada en esta plataforma.");
    }
  }

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
  );
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  await Config.loadFromAssets(flavor, isProd);

  await _requestLocationPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrdenProvider(),),
        ChangeNotifierProvider(create: (_) => AuthProvider()..setFlavor(flavor),),
      ],
      child: const MyApp(),
    )
  );
}

Future<void> _requestLocationPermission() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    await Permission.location.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme(selectedColor: 0);
    return MaterialApp.router(
      routerConfig: router,
      theme: appTheme.getTheme(),
      debugShowCheckedModeBanner: false,
      title: 'Resysol',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Spanish
        Locale('en'), // English
      ],
    );
  }
}
