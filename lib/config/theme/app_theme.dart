import 'package:flutter/material.dart';

const String flavor = String.fromEnvironment('FLAVOR');

final colorList = <Color>[
  const Color.fromARGB(255, 33, 79, 119), //Lopez Motors
  const Color.fromARGB(255, 0, 145, 60), //Parabrisas Ejido
  const Color.fromARGB(176, 88, 35, 124), //Automotora Argentina
];

final secondaryColorList = <Color>[
  Colors.blue,
  Colors.green,
  Colors.deepPurple,
];

class AppTheme{
  final int selectedColor;
  final Color primaryColor;
  final Color secondaryColor;

  static int _getSelectedColorIndex() {
    switch (flavor.toLowerCase()) {
      case 'lopezmotors':
        return 0;
      case 'parabrisasejido':
        return 1;
      case 'automotoraargentina':
        return 2;
      default:
        return 0;
    }
  }
  AppTheme({int? selectedColor, Color? primaryColor, Color? secondaryColor})
    : selectedColor = selectedColor ?? _getSelectedColorIndex(),
      primaryColor = primaryColor ?? colorList[_getSelectedColorIndex()],
      secondaryColor = secondaryColor ?? secondaryColorList[_getSelectedColorIndex()];

  ThemeData getTheme() => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white, 
      secondary: secondaryColor,
      onSecondary: Colors.white, 
      error: Colors.red, 
      onError: Colors.red, 
      surface: Colors.white, 
      onSurface: Colors.black,    
    ),

    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: primaryColor,
    )
  );

  AppTheme copyWith({
    int? selectedColor,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return AppTheme(
      selectedColor: selectedColor ?? this.selectedColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }
}