import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin.dart';
import '../notifications/detail.dart';

class MyUploadedSongsPage extends StatelessWidget {
  const MyUploadedSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black12,
          title: const Text('My Uploaded Songs', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.redAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "Approved (Live)"),
              Tab(text: "Pending (Hngah lio)"),
            ],
          ),
        ),
        body: user == null
            ? const Center(child: Text("Login na tuah a hau.", style: TextStyle(color: Colors.white)))
            : TabBarView(
          children: [
            // Tab 1: Approved Songs (songs collection chung in amah thunmi lawng)
            _buildSongList('songs', user.uid),

            // Tab 2: Pending Songs (songToEdit collection chung in amah thunmi lawng)
            _buildSongList('songToEdit', user.uid),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Data laaknak le langhternak
  Widget _buildSongList(String collectionName, String uid) {
    return StreamBuilder<QuerySnapshot>(
      // Firebase Query: Amah UID he aa tlai (equalTo) mi lawng laaknak
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .where('uploaderUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {// 1. A BIAPI BIK: Error check hmasa (Hika ah hin Null error a chuah lonakhnga kan kham)
        if (snapshot.hasError) {
          return const Center(child: Text("Data laknak ah palhnak a um.", style: TextStyle(color: Colors.redAccent)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }

        // 2. Data a lawng (empty) a si ahcun (Null safe check kan hman)
        if (!snapshot.hasData || snapshot.data?.docs == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Hla na thunmi a um rih lo.",
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          );
        }

        var docs = snapshot.data!.docs;

        // 3. A THAR: Pending tab a si ahcun 'type: report' kha kan thup lai (Upload taktak lawng kan langhter lai)


        // Filter tuah hnu ah a lawng tthan a si ahcun
        if (docs.isEmpty) {
          return const Center(
            child: Text("Hngah liomi hla a um lo.", style: TextStyle(color: Colors.white54, fontSize: 16)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var item = docs[index].data() as Map<String, dynamic>;

            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () {

                  if(collectionName == 'songToEdit'){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditPendingSong(doc: docs[index])));
                  }else{

                    Navigator.push(context, MaterialPageRoute(builder: (context)=>
                        DetailsPage(
                      title: item['title'] ?? '',
                      chord: item['chord'] ?? false,
                      singer: item['singer'] ?? '',
                      composer: item['composer'] ?? '',
                      verse1: item['verse1'] ?? '',
                      verse2: item['verse2'] ?? '',
                      verse3: item['verse3'] ?? '',
                      verse4: item['verse4'] ?? '',
                      verse5: item['verse5'] ?? '',
                      songtrack: item['songtrack'] ?? '',
                      chorus: item['chorus'] ?? '',
                      endingChorus:
                      item['endingchorus'] ?? "",
                    ))
                    );

                    }

                },
                leading: CircleAvatar(
                  backgroundColor: collectionName == 'songs' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  child: Icon(
                    collectionName == 'songs' ? Icons.check_circle : Icons.hourglass_empty,
                    color: collectionName == 'songs' ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(item['title'] ?? 'No Title',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(item['singer'] ?? 'Unknown Singer',
                    style: const TextStyle(color: Colors.white70)),
                trailing: Text(
                  collectionName == 'songs' ? "Live" : "Pending",
                  style: TextStyle(
                      color: collectionName == 'songs' ? Colors.green : Colors.orange,
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
