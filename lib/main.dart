// dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chinlyrics/pages/home.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'constant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
  await Hive.initFlutter();
  await Hive.openBox('downloads');
  downloads = Hive.box('downloads');
  await OrientationHelper().setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      title: 'laihla lyrics',
      debugShowCheckedModeBanner: false,
      home: const LoadingPage(),
    );
  }
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  double fileSize = 0;
  double downloadProgress = 0.0; // 0.0 .. 1.0

  @override
  void initState() {
    super.initState();
    readFavoriteFile();
    _startDownload();
  }

  Future<void> _startDownload() async {
    const fileName = 'hla';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        if (!mounted) return;
        Get.off(() => const Home());
        return;
      }

      final dio = Dio();

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (!mounted) return;

          if (total != -1) {
            downloadProgress = received / total;
            setState(() {});
          }
        },
      );

// NOW SAFE TO NAVIGATE
      if (mounted) {
        final file = File(savePath);
        if (await file.length() > 0) {
          Get.off(() => const Home());
        }

      }




    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white30,
            title: const Text('No connection', style: TextStyle(color: Colors.white)),
            content: const Text(
              'A voi khat nak ahcun internet chikhat na on piak a hau.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              ElevatedButton(
                clipBehavior: Clip.hardEdge,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white30),
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) _startDownload();
                  });
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> readFavoriteFile() async {
    try {
      const fileName = 'favorite';
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final path = File(filePath);
      if (await path.exists()) {
        final content = await path.readAsString();
        final List<dynamic> l = json.decode(content) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          for (var element in l) {
            favorites.add(element);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black12,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // determinate when we have progress, otherwise indeterminate
          SizedBox(
            width: 48,
            height: 48,
            child: downloadProgress*100 > 0
                ? CircularProgressIndicator(value: downloadProgress)
                : const CircularProgressIndicator(),
          ),
        ]),
      ),
    );
  }
}
