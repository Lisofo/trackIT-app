// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'package:flutter/services.dart';

class Config {
  static late String APIURL;
  static late String MODO;

  static Future<void> loadFromAssets (String flavor, bool isProd) async {
    final patch = isProd
      ? 'assets/config/$flavor/config_prod.json'
      : 'assets/config/$flavor/config.json';
    
    final jsonStr = await rootBundle.loadString(patch);
    final jsonMap = json.decode(jsonStr);

    APIURL = jsonMap['APIURL'] ?? '';
    MODO = jsonMap['MODO'] ?? '';
  }
}
