import 'package:flutter/material.dart';

final colorList = <Color>[
  // const Color.fromARGB(255, 33, 79, 119),
  // const Color.fromARGB(255, 0, 145, 60),
  const Color.fromARGB(176, 88, 35, 124),
];

class AppTheme{
  final int selectedColor;
  AppTheme({this.selectedColor = 0});

  ThemeData getTheme() => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: colorList[selectedColor],
      onPrimary: Colors.white, 
      secondary: Colors.deepPurple,
      // secondary: Colors.green,
      // secondary: Colors.blue,
      onSecondary: Colors.white, 
      error: Colors.white, 
      onError: Colors.red, 
      surface: Colors.white, 
      onSurface: Colors.black,    
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
    )
  );
}