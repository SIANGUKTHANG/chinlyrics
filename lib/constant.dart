

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

List<dynamic> jsonData = [];
List<dynamic> jsonDatas = [];
List<dynamic> favorites = [];
var downloads;

const url = 'https://laihlalyrics.itrungrul.com/api/songs';
//'https://drive.google.com/uc?export=download&id=14nduwHp9yLKADrtRW5JyQZRbWMtF11IE';


void addFavoriteData(dynamic favoriteData) async {
  final dir = await getApplicationDocumentsDirectory();

  const fileName = 'favorite';
  final filePath = '${dir.path}/$fileName';

  List<dynamic> existingData = [];

  try {
    File file = File(filePath);
    if (file.existsSync()) {
      String fileContents = await file.readAsString();
      existingData = jsonDecode(fileContents);
    }
  } catch (e) {}

  existingData.add(favoriteData);

  String updatedData = jsonEncode(existingData);
  File file = File(filePath);
  await file.writeAsString(updatedData);
}

void removeFavoriteData(dynamic favoriteData) async {
  final dir = await getApplicationDocumentsDirectory();

  const fileName = 'favorite';
  final filePath = '${dir.path}/$fileName';

  List<dynamic> existingData = [];

  try {
    File file = File(filePath);
    if (file.existsSync()) {
      String fileContents = await file.readAsString();
      existingData = jsonDecode(fileContents);
    }
  } catch (e) {}

  existingData.removeWhere((song) => song['title'] == favoriteData);

  String updatedData = jsonEncode(existingData);
  File file = File(filePath);
  await file.writeAsString(updatedData);
}





class OrientationHelper {
  Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) {
    return SystemChrome.setPreferredOrientations(orientations);
  }

  Future<void> clearPreferredOrientations() {
    return SystemChrome.setPreferredOrientations([]);
  }
}
