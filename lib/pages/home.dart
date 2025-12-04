import 'dart:convert';
import 'dart:io';
import 'package:chinlyrics/pages/setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../constant.dart';
import 'bible/home.dart';
import 'chords.dart';
import 'chawnghlang.dart';
import 'favorite.dart';
import 'khrihfa_hlabu.dart';
import 'offline_home.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var decoration = const BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.all(Radius.circular(12)));
  var textStyle = GoogleFonts.aldrich(
    color: Colors.white54,
    fontWeight: FontWeight.bold,
  );

  int newAdd = 0;
  var offlineList = [];
  var onlineList = [];

  @override
  void initState() {
    readJsonFile();

    OrientationHelper().clearPreferredOrientations();
    super.initState();
  }

  readJsonFile() async {
    const fileName = 'hla'; // Specify the desired file name
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';

    List<dynamic> l = json.decode(await File(filePath).readAsString()) as List;
    setState(() {
      offlineList = l;
    });
  }

  @override
  void dispose() {
    OrientationHelper()
        .setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: ElevatedButton(
        onPressed: () {
          Get.to(() => OfflineHome());
        },
        style: FilledButton.styleFrom(
          backgroundColor: Colors.grey.withOpacity(0.1),
          foregroundColor: Colors.white70, // 50% opacity
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10.0), // Creates a square button
          ),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 1.5,
          child: const Center(
            child: Text('Go to all songs', style: TextStyle(letterSpacing: 2)),
          ),
        ),
      )),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          offlineList.isEmpty? const SizedBox(): Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Songs : ${offlineList.length}',
              style: const TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          SizedBox(
            //   width: MediaQuery.of(context).size.width / 1.4,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildCategoryButton('Bible', const HomeBible()),
                _buildCategoryButton(' Khrihfa Hlabu ', const KhrihfaHlaBu()),
                _buildCategoryButton(' Chawnghlang ', const ChawngHlang()),
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: ListTile(
              onTap: () {
                Get.to(const Chords());
              },
              leading: const Icon(
                Icons.back_hand_outlined,
                color: Colors.white70,
              ),
              title: const Text('chord book',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Guitar chord cawnnak',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: ListTile(
              onTap: () {
                Get.to(const Favorite());
              },
              leading: const Icon(
                Icons.favorite,
                color: Colors.white70,
              ),
              title: const Text('Favorite',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'favorite na tuahmi zohnak',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: ListTile(
              onTap: () {
                Get.to(() => const Setting());
              },
              leading: const Icon(
                Icons.settings,
                color: Colors.white70,
              ),
              title: const Text('Settings',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'settings le a dang dang ..',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, Widget page) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          backgroundColor: Colors.white10,
          // Darker button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => page));
        },
        child: Text(title,
            style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade200,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)));
  }
}
