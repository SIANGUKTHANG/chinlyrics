import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool isMigrating = false;
  String statusMessage =
      "Hla 1,300 cu 'hla' collection ah tthial ding in in hngah lio a si...";

  Future<void> runMigrationAndGenerateIndex() async {
    setState(() {
      isMigrating = true;
      statusMessage = "1. 'songs' collection chung in hla lak lio a si...";
    });

    try {
      // 1. A hlun 'songs' collection chung in hla 1,300 vialte lak
      QuerySnapshot songsSnapshot =
          await FirebaseFirestore.instance.collection('hla').get();
      int totalSongs = songsSnapshot.docs.length;

      Map<String, dynamic> songsMap = {};
      int count = 0;

      // 2. Hla pakhat cio kha 'hla' collection thar ah copy tuah le Index ser
      for (var doc in songsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // A. 'hla' collection thar ah copy tuahnak (ID ngai te hmang in)
/*        await FirebaseFirestore.instance
            .collection('hla')
            .doc(doc.id)
            .set(data);*/

        // B. Search Index caah Map chungah khumh
        songsMap[doc.id] = {
          'title': data['title'] ?? 'No Title',
          'singer': data['singer'] ?? 'Unknown',
          'chord': data['chord'] ?? false,
          'track': data['songtrack'] ?? '',
        };

        count++;
        // Hla 100 a tlin paoh ah UI update tuah (App a buai lo nakhnga)
        if (count % 100 == 0 || count == totalSongs) {
          setState(() {
            statusMessage =
                "2. Hla $count / $totalSongs cu 'hla' ah tthial lio a si...";
          });
        }
      }

      setState(() {
        statusMessage = "3. Search Index cu 'part_1' ah khumh lio a si...";
      });

      // 3. 'metadata' collection chung i 'part_1' ah save tuahnak
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('part_1')
          .set({
        'songs_map': songsMap,
        'total_songs': songsMap.length,
        'last_updated': FieldValue.serverTimestamp(),
      });

      setState(() {
        statusMessage =
            "A TLAMTLING CANG! 🎉\n\nHla $totalSongs cu 'hla' collection ah a ttha tein tthial a si cang.\nSearch Index zong ser a si cang.\nHi page hi hloh khawh a si cang.";
        isMigrating = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = "Palhnak a um: $e";
        isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Tthialnak (Migration)"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.drive_file_move, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              if (isMigrating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: runMigrationAndGenerateIndex,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Hla Tthial Thawk"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
