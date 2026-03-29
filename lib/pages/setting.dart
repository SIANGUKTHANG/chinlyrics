import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../about.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  final TextStyle _itemStyle = const TextStyle(
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    fontSize: 15,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1E2C),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E2C), Colors.black],
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // --- SECTION 1: DATA & STORAGE ---
            _buildSectionHeader("DATA & STORAGE"),
            _buildSettingsGroup([
              _buildListTile(
                icon: Icons.sync,
                title: 'Update Data (Hla Thar Check)',
                iconColor: Colors.greenAccent,
                onTap: _handleUpdateData,
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.cleaning_services,
                title: 'Clear Downloaded Tracks',
                iconColor: Colors.orangeAccent,
                onTap: _clearDownloads,
              ),
            ]),

            // --- SECTION 2: SUPPORT & FEEDBACK ---
            _buildSectionHeader("SUPPORT & FEEDBACK"),
            _buildSettingsGroup([
              _buildListTile(
                icon: Icons.message,
                title: 'Request Song / Report',
                iconColor: Colors.blueAccent,
                onTap: () => _launchURL('https://m.me/100290286104836'),
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.star_rate,
                title: 'Rate LaihLa Lyrics',
                iconColor: Colors.amberAccent,
                onTap: () {
                  // Na app link taktak in thleng te
                  _launchURL('https://apps.apple.com/kr/app/laihla-lyrics/id6479561333#productRatings');
                },
              ),
            ]),

            // --- SECTION 3: LEGAL & ABOUT ---
            _buildSectionHeader("LEGAL & ABOUT"),
            _buildSettingsGroup([
              _buildListTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                iconColor: Colors.purpleAccent,
                onTap: () => _launchURL('https://sites.google.com/view/it-rungrul/home'),
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.info,
                title: 'About App',
                iconColor: Colors.pinkAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 30),

            // --- BOTTOM LOGO & VERSION ---
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                  ),
                  child: Image.asset('assets/logo.png', height: 60, width: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.white54, size: 40)),
                ),
                const SizedBox(height: 12),
                const Text(
                  "LaihLa Lyrics",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Version 1.0.0",
                  style: TextStyle(fontSize: 13, color: Colors.white54, letterSpacing: 1.5),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required Color iconColor, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: _itemStyle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white10, height: 1, indent: 60, endIndent: 16);
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
    }
  }

  // Hla thar update tuah (Data refresh) lio ah a lang dingmi
  Future<void> _handleUpdateData() async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.redAccent),
            SizedBox(height: 16),
            Text('Checking for new songs...', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    readAndRetrieve();

  }

  Future<void> readAndRetrieve({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('Firebase in data a thar a um le um lo check a si...');
    }

    try {

      // 2. Firebase ah hla zeizat dah a um ti a zat lawng check nak
      AggregateQuerySnapshot countSnapshot =
      await FirebaseFirestore.instance.collection('songs').count().get();
      int serverCount = countSnapshot.count ?? 0;

        // Firebase in data thar laknak
        QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('songs').get();

        List<dynamic> newData = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Document ID

          // Timestamp kha String ah thlen hrimhrim a hau (JSON ah save khawh nakhnga)
          if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }
          return data;
        }).toList();
        // ABC in remhnak
        newData.sort((a, b) => a["title"]
            .toString()
            .toLowerCase()
            .compareTo(b["title"].toString().toLowerCase()));
        // Phone chung (Local JSON file) ah a thar in save tthan nak
        const fileName = 'hla';
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(json.encode(newData));

      if (mounted) {
        Navigator.pop(context); // Dialog phih
      }
    } catch (e) {

      if (mounted) {
        Navigator.pop(context); // Dialog phih
      }
      debugPrint("Data check/lak lio ah palhnak a um: $e");
    }
  }


  // Audio track (mp3) download na tuah ciami vialte hlohnak
  Future<void> _clearDownloads() async {
    try {
      final dir = await getTemporaryDirectory();
      List<FileSystemEntity> files = dir.listSync();
      int deletedCount = 0;

      for (var file in files) {
        if (file.path.endsWith('.mp3')) {
          file.deleteSync();
          deletedCount++;
        }
      }


    } catch (e) {
    }
  }
}