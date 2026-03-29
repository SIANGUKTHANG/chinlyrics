import 'dart:async';
import 'dart:convert';
import 'package:chinlyrics/laihlalyrics/home_feed.dart';
import 'package:chinlyrics/pages/khrihfa_hlabu.dart';
import 'package:chinlyrics/pages/offline_home.dart';
import 'package:chinlyrics/pages/setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../admin/admin.dart';
import '../admin/uploadpage.dart';
import '../constant.dart';
import '../laihlalyrics/home.dart';
import '../migrantdata.dart';
import '../musician/home.dart';
import '../user/profile.dart';
import 'bible/home.dart';
import 'chawnghlang.dart';
import 'chords.dart';
import 'favorite.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Box userBox = Hive.box('userBox');
  bool bibleDownload = false;
  int localSongs = 0;
  User? user;

  @override
  void initState() {
    super.initState();
    //UpdateChecker.checkForUpdate(context);
    user = FirebaseAuth.instance.currentUser;
    checkSongLength();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialogIfNeeded();
    });
    OrientationHelper().clearPreferredOrientations();


  }


  Future<void> checkSongLength() async {
    // 1. Phone chung i a um ciami JSON file in la hmasa (UI a rangnak dingah)
    await readLocalSong();

    try {
      // 2. Firebase ah hla zeizat dah a um ti a zat lawng check nak (Data a la lo, a number lawng a rel)
      AggregateQuerySnapshot countSnapshot =
          await FirebaseFirestore.instance.collection('hla').count().get();
      if(!mounted) return;
     setState(() {
       localSongs = countSnapshot.count ?? 0;
     });
    } catch (e) {
      if (kDebugMode) {
        print("error: $e");
      }
    }
  }

  Future<void> readLocalSong() async {
    const fileName = 'hla'; // Specify the desired file name
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';

    final file = File(filePath);
    if (await file.exists()) {
      //  await file.delete();
      List<dynamic> l =
          json.decode(await File(filePath).readAsString()) as List;

      l.sort((a, b) => a["title"].toLowerCase().compareTo(b["title"]
          .toLowerCase())); // Assuming you want to sort by the "title" field

      if (mounted) {
        setState(() {
          localSongs = l.length;
        });
      }
    } else {}
  }

  Widget buildListTile({
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required VoidCallback onTap,
    Widget? trailingText,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      color: Colors.white10, // Darker card background
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          leadingIcon,
          color: Colors.blue.shade200,
        ),
        title: Text(
          title,
          style: TextStyle(
              color: Colors.blueGrey.shade200,
              fontWeight: FontWeight.w500,
              letterSpacing: 1),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              color: Colors.blueGrey.shade200,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 1),
        ),
        trailing: trailingText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => OfflineHome()));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10, // Dark button background
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    margin: const EdgeInsets.all(10.0),
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: Text(
                        'Go to all songs ',
                        style: TextStyle(
                            color: Colors.blueGrey.shade200,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Favorite()));
                  },
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.blueGrey.shade200,
                  ))
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: localSongs == 0
                ? const SizedBox()
                : Text("Total Songs -  $localSongs",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade100,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1)),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildCategoryButton('Bible', const BiblePage()),
              _buildCategoryButton('Khrihfa Hlabu', const KhrihfaHlaBu()),
              _buildCategoryButton('Chawnghlang', const ChawngHlang()),
            ],
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Divider(
              color: Colors.white12,
              height: 0.5,
            ),
          ),
          const SizedBox(height: 20),
        Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: Colors.white10,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      // Hmanthlak velchum i border caah
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[900],
                        // Google in a lutmi nih hmanthlak an ngeih ahcun a lang lai, an ngeih lo (Email in lutmi) ahcun Icon a lang lai
                        backgroundImage: user!.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user!.photoURL == null
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                    ),
                    title: Text(
                      (user!.displayName) == null
                          ? 'chinlyrics user'
                          : user!.displayName.toString(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(user!.email.toString()),
                  ),
                ),
                  buildListTile(
              title: 'Admin Approval',
              subtitle: 'Hla approve tuahnak a si.',
              leadingIcon: Icons.admin_panel_settings,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const AdminApprovalPage()))
                    .then(((result) {
                  if (result == true) {

                  }
                }));
              }),

          buildListTile(
              title: 'Musician Note',
              subtitle: 'Music Note tial le tumnak.',
              leadingIcon: Icons.piano,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const ChordPage()))
                    .then(((result) {
                  if (result == true) {

                  }
                }));
              }),
          buildListTile(
            title: 'Chord Book',
            subtitle: 'Guitar chord cawnnak',
            leadingIcon: Icons.back_hand_outlined,
            onTap: () {

              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => const ChordsLibrary()));
            },
          ),
          buildListTile(
            title: 'Sample Home',
            subtitle: 'Guitar chord cawnnak',
            leadingIcon: Icons.back_hand_outlined,
            onTap: () {

              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => const MainNavigationPage()));
            }
          ),
          buildListTile(
              title: 'Upload Song',
              subtitle: 'Duhmi hla Server Ah khumhnak',
              leadingIcon: Icons.audio_file_outlined,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => const UploadSongPage()))
                    .then(((result) {
                  if (result == true) {
                  }
                }));
              }),
          Container(),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, Widget page) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

  // A THAR: A voikhatnak login a si le si lo check nak le Dialog
  void _showWelcomeDialogIfNeeded() {
    // Hive chungah 'isFirstTimeLogin' ti a um le um lo a check lai (A um lo ahcun 'true' a si lai)
    bool isFirstTime = userBox.get('isFirstTimeLogin', defaultValue: true);

    if (isFirstTime) {
      showDialog(
        context: context,
        barrierDismissible: false, // User nih OK button an hmeh hrimhrim a hau
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text("Theihternak",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            "'Laihla Lyrics' in kan in don!\n"
            "\n\nThis app is free to use, some ads may appear in the app. We ask for your understanding.\n\n"
            "Hi App hi man liam hau lo in Free tein hman khawh a si caah, app chungah Ads (fakthanh) tlawmpal a rak lang kho. Na theithiamnak lai kan in nawl.",
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  // 1. Dialog kan phih lai
                  Navigator.pop(context);

                  // 2. A hnu ah a langh ti lonakhnga Hive ah 'false' in kan save cang lai
                  userBox.put('isFirstTimeLogin', false);
                },
                child: const Text("OK, Ka Theithiam",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }
}
