import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonHelper {
   loadKhrihfaHlaBu() async {
    String jsonString = await rootBundle.loadString('assets/khrihfahlabu.json');
    final jsonData = json.decode(jsonString);
    return jsonData;
  }

  loadChawngHlang() async {
    String jsonString = await rootBundle.loadString('assets/chawnghlang.json');
    final jsonData = json.decode(jsonString);
    return jsonData;
  }




}



