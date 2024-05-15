import 'package:flutter/material.dart';

final colorList = <Color>[
   const Color.fromARGB(255, 14, 98, 146),
];

class AppTheme{

  final int selectedColor;

  AppTheme({this.selectedColor = 0});



  ThemeData getTheme() => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: colorList[selectedColor],
      onPrimary: Colors.white, 
      secondary: Colors.blue, 
      onSecondary: Colors.white, 
      error: Colors.white, 
      onError: Colors.black, 
      background: Colors.white, 
      onBackground: Colors.black, 
      surface: Colors.white, 
      onSurface: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
    )
  );

}