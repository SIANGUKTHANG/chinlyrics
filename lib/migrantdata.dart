// ================= FIREBASE DATABASE MIGRATION =================
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> migrateHlaToSongs(BuildContext context) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data thial lio a si, hngak ta..."), backgroundColor: Colors.orange),
    );

    final firestore = FirebaseFirestore.instance;
    final hlaSnapshot = await firestore.collection('hla').get();

    if (hlaSnapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("'hla' collection a lawng."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    WriteBatch batch = firestore.batch();
    int count = 0;

    for (var doc in hlaSnapshot.docs) {
      final data = doc.data();

      // 1. A hlun ning in chiah dingmi pawl
      String title = data['title'] ?? '';
      String singer = data['singer'] ?? '';
      String category = data['category'] ?? 'Gospel';
      var createdAt = data['createdAt'];
      var updatedAt = data['updatedAt'];

      // 2. Field min thleng dingmi pawl
      String soundtrack = data['songtrack'] ?? '';
      bool isChord = data['chord'] == true || data['chord'] == 'true'; // A him nakhnga check tuahnak

      // ================= 3. LYRICS FONHNAK LOGIC (REGEX CAAH) =================
      String compiledLyrics = _buildLyricsFromOldData(data);

      // 4. 'songs' collection thar ah a hlun Doc ID tein Document thar sernak
      DocumentReference newSongRef = firestore.collection('songs').doc(doc.id);

      // 5. Data thar fonh in khumhnak
      Map<String, dynamic> newSongData = {
        'title': title,
        'singer': singer,
        'category': category,
        'lyrics': compiledLyrics, // A tlar in fonh ciami Lyrics
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),

        'soundtrack': soundtrack,
        'isChord': isChord,

        'approved': true,
        'comments': 0,
        'likes': 0,
        'likedBy': [],
        'type': 'hla',
        'uploaderId': 'QaG0mhqEmrPI6vSUTV51hH9qhMF3', // Admin ID
      };

      batch.set(newSongRef, newSongData);
      count++;

      if (count == 490) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tlamtling tein 'songs' ah thial a si cang!"), backgroundColor: Colors.green),
      );
    }

  } catch (e) {
    print("Migration palhnak: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Palhnak: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

// ================= VERSE LE CHORUS FONHNAK HELPER =================
String _buildLyricsFromOldData(Map<String, dynamic> data) {
  StringBuffer sb = StringBuffer();

  // Hla tlang pakhat thunnak function te
  void addPart(String tag, String? text) {
    if (text != null && text.trim().isNotEmpty) {
      sb.writeln('{$tag}');
      sb.writeln(text.trim());
      sb.writeln(); // Tlang karlak ah space dahnak
    }
  }

  // A tlangpi in hla sining tein kan tlar hna lai
  addPart('verse', data['verse1']);
  addPart('chorus', data['chorus']);
  addPart('verse', data['verse2']);
  addPart('verse', data['verse3']);
  addPart('verse', data['verse4']);
  addPart('verse', data['verse5']);
  addPart('verse', data['verse6']);
  addPart('verse', data['verse7']);
  addPart('chorus', data['endingChorus']);

  // Hlan ah 'zate' (Hla pumpi) in na rak chiah sualmi a um ahcun
  if (sb.isEmpty && data['zate'] != null && data['zate'].toString().isNotEmpty) {
    addPart('verse', data['zate']);
  }

  // A donghnak i space a chuakmi hloh chihnak
  return sb.toString().trim();
}


Future<void> exportSongsToJson(BuildContext context) async {
  try {
    // 1. Loading langhternak
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("JSON file ser lio a si, hngak ta..."), backgroundColor: Colors.blueAccent),
    );

    final firestore = FirebaseFirestore.instance;

    // 'songs' collection chung i hla dihlak laaknak
    final snapshot = await firestore.collection('songs').get();

    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hla a um lo!"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    List<Map<String, dynamic>> allSongsList = [];

    // 2. Document pakhat cio JSON format ah thlennak
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data();

      // A biapi bik: Hmailei Like, Comment, Delete caah Doc ID thun chihnak
      data['id'] = doc.id;

      // Firebase Timestamp pawl kha JSON nih a theih nakhnga Nambat (int) ah thlen hmasa
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
      }

      allSongsList.add(data);
    }

    // 3. List kha JSON String ah thlennak (Mawi tein a tlar nakhnga indentation he)
    String jsonString = const JsonEncoder.withIndent('  ').convert(allSongsList);

    // 4. Phone memory chungah File sernak
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/laihla_songs.json');
    await file.writeAsString(jsonString);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("JSON tlamtling tein ser a si!"), backgroundColor: Colors.green),
      );
    }

    // 5. File cu fawi tein laak khawh nakhnga Share tuahnak (Email, Telegram, Drive ah save khawh a si)
    await Share.shareXFiles([XFile(file.path)], text: 'Laihla Lyrics - Songs Database JSON');

  } catch (e) {
    print("JSON export palhnak: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Palhnak: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

