import 'package:flutter/material.dart';

final colorList = <Color>[
   const Color.fromARGB(255, 0, 145, 60),
];

class AppTheme{

  final int selectedColor;

  AppTheme({this.selectedColor = 0});



  ThemeData getTheme() => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: colorList[selectedColor],
      onPrimary: Colors.white, 
      secondary: Colors.green, 
      onSecondary: Colors.white, 
      error: Colors.white, 
      onError: Colors.black, 
      surface: Colors.white, 
      onSurface: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
    )
  );

}