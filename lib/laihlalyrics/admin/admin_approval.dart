import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminApproval extends StatelessWidget {
  const AdminApproval({super.key});

  // Hla pakhat kha toCheck in songs ah a thial lai
  Future<void> _approveSong(BuildContext context, String docId, Map<String, dynamic> data) async {
    try {
      // 1. Approved a si ti theihnak thlen
      data['approved'] = true;
      data['updatedAt'] = FieldValue.serverTimestamp();

      // 2. 'songs' collection taktak ah khumh
      await FirebaseFirestore.instance.collection('songs').add(data);

      // 3. 'toCheck' in phiah (Delete)
      await FirebaseFirestore.instance.collection('toCheck').doc(docId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hla na Approve cang!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Palhnak: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // Hla a ttha lo mi phiahnak (Reject)
  Future<void> _rejectSong(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('toCheck').doc(docId).delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hla na Reject (phiat) cang.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Admin - Hla Zohnak", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('toCheck').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Hla thar zoh ding a um rih lo.", style: TextStyle(color: Colors.white54)));

          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white54,
                  title: Text(data['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(data['singer'] ?? 'Unknown', style: const TextStyle(color: Colors.white54)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(data['lyrics'] ?? '', style: const TextStyle(color: Colors.white70)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text("Reject", style: TextStyle(color: Colors.white)),
                          onPressed: () => _rejectSong(context, doc.id),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text("Approve", style: TextStyle(color: Colors.white)),
                          onPressed: () => _approveSong(context, doc.id, data),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}