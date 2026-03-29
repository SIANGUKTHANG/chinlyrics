import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../musician/add_chord.dart';
import '../notifications/notificationHelper.dart';
import 'announcement.dart';

class AdminApprovalPage extends StatelessWidget {
  const AdminApprovalPage({super.key});


  Future<void> _approveSong(BuildContext context, DocumentSnapshot doc) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String type = data['type'] ?? '';

      data.remove('status');
      data.remove('type');
      data.remove('reportMessage');

      DocumentReference addedDoc = await FirebaseFirestore.instance.collection('hla').add(data);
      await FirebaseFirestore.instance.collection('songToEdit').doc(doc.id).delete();

      DocumentReference metaRef = FirebaseFirestore.instance.collection('metadata').doc('part_1');
      DocumentSnapshot metaDoc = await metaRef.get();

      Map<String, dynamic> songsMap = {};
      if (metaDoc.exists && metaDoc.data() != null) {
        Map<String, dynamic> metaData = metaDoc.data() as Map<String, dynamic>;
        if (metaData.containsKey('songs_map')) {
          songsMap = Map<String, dynamic>.from(metaData['songs_map']);
        }
      }

      // REMHNAK 1: songtrack hi string a si caah isNotEmpty in check a si
      songsMap[addedDoc.id] = {
        'title': data['title'] ?? 'Unknown',
        'singer': data['singer'] ?? 'Unknown Artist',
        'chord': data['chord'] ?? false,
        'track': (data['track'] ??'')
      };

      await metaRef.set({
        'songs_map': songsMap,
        'total_songs': songsMap.length,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));



      if (type == 'upload') {
        await NotificationHelper.sendNotification(
          title: "Hla Thar A Um!",
          body: "${data['title']} (Satu: ${data['singer']}) hla thar kan khum than!.",
          type: "song",
          topic: "all_users",
          extraData: data,
        );

        if (data['uploaderUid'] != null && data['uploaderUid'].toString().isNotEmpty) {
          await NotificationHelper.sendNotification(
            title: "Approved! 🎉",
            body: "Na tial mi hla '${data['title']}' kha Admin nih a cohlan cang.",
            type: "personal",
            extraData: data,
            topic: "user_${data['uploaderUid']}",
          );
        }
      } else if (type == 'report'){
        if (data['uploaderUid'] != null && data['uploaderUid'].toString().isNotEmpty) {
          await NotificationHelper.sendNotification(
            title: "Approved! 🎉",
            body: "Report na tuah mi hla '${data['title']}' kha Admin nih a zohfel cang.",
            type: "personal",
            extraData: data,
            topic: "user_${data['uploaderUid']}",
          );
        }
      }


    } catch (e) {
    }
  }

  Future<void> _rejectSong(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('songToEdit').doc(docId).delete();
    } catch (e) {
    }
  }

  void _showConfirmDialog(BuildContext context, DocumentSnapshot doc, bool isApprove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(isApprove ? "Confirm Song?" : "Reject Song?", style: const TextStyle(color: Colors.white)),
        content: Text(
            isApprove
                ? "Hi hla hi Live ('songs' collection) ah na langhter taktak lai maw?"
                : "Hi hla hi Database chung in na hloh (delete) taktak lai maw?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              if (isApprove) {
                _approveSong(context, doc);
              } else {
                _rejectSong(context, doc.id);
              }
            },
            child: Text(isApprove ? "Yes, Confirm" : "Yes, Reject", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveChord(BuildContext context, DocumentSnapshot doc) async {
    try {
      await FirebaseFirestore.instance.collection('musicianChords').doc(doc.id).update({
        'status': 'live',
      });
    } catch (e) {
    }
  }

  Future<void> _rejectChord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('musicianChords').doc(docId).delete();
    } catch (e) {
    }
  }

  void _showChordConfirmDialog(BuildContext context, DocumentSnapshot doc, bool isApprove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(isApprove ? "Approve Chord?" : "Reject Chord?", style: const TextStyle(color: Colors.white)),
        content: Text(
            isApprove
                ? "Hi Chord hi status 'live' ah na thleng taktak lai maw?"
                : "Hi Chord hi Database chung in na hloh (delete) taktak lai maw?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              if (isApprove) {
                _approveChord(context, doc);
              } else {
                _rejectChord(context, doc.id);
              }
            },
            child: Text(isApprove ? "Yes, Approve" : "Yes, Reject", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black12,
          title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnouncementPusherPage()));
                },
                icon: const Icon(Icons.notification_add)
            )
          ],
          bottom: const TabBar(
            indicatorColor: Colors.redAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.cloud_upload), text: "Uploads"),
              Tab(icon: Icon(Icons.report_problem), text: "Reports"),
              Tab(icon: Icon(Icons.library_music), text: "Chords"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSongStream(isReport: false),
            _buildSongStream(isReport: true),
            _buildChordStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildSongStream({required bool isReport}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('songToEdit').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(isReport ? "Report tuahmi a um lo." : "Upload thar a um lo.", style: const TextStyle(color: Colors.white54, fontSize: 16)));
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool isRep = data['type'] == 'report';
          return isReport ? isRep : !isRep;
        }).toList();

        return _buildSongList(filteredDocs, isReportTab: isReport);
      },
    );
  }

  Widget _buildChordStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('musicianChords').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Hngah lio mi Chord a um lo.", style: TextStyle(color: Colors.white54, fontSize: 16)));
        }

        return _buildChordList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildSongList(List<QueryDocumentSnapshot> docs, {required bool isReportTab}) {
    if (docs.isEmpty) {
      return Center(
        child: Text(isReportTab ? "Report tuahmi a um lo." : "Upload thar a um lo.",
            style: const TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var doc = docs[index];
        var data = doc.data() as Map<String, dynamic>;

        return Card(
          color: isReportTab ? Colors.orange.withOpacity(0.05) : Colors.white10,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: isReportTab
              ? RoundedRectangleBorder(
              side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
              borderRadius: BorderRadius.circular(10))
              : null,
          child: ExpansionTile(
            iconColor: Colors.white,
            collapsedIconColor: Colors.white54,
            title: Text(data['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(data['singer'] ?? 'Unknown Singer', style: const TextStyle(color: Colors.white70)),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isReportTab)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orangeAccent, size: 18),
                                SizedBox(width: 8),
                                Text("USER REPORT ISSUE:", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(data['reportMessage'] ?? 'No details provided by user', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    Text("Category: ${data['category']}", style: const TextStyle(color: Colors.blueAccent)),
                    Text("Composer: ${data['composer']}", style: const TextStyle(color: Colors.white70)),
                    if (data['uploaderEmail'] != null)
                      Text("Uploaded by: ${data['uploaderEmail']}", style: const TextStyle(color: Colors.greenAccent, fontStyle: FontStyle.italic)),
                    const Divider(color: Colors.white24),
                    const Text("Verse 1:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(data['verse1'] ?? '', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    const Text("Chorus:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(data['chorus'] ?? '', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => _showConfirmDialog(context, doc, false),
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                          tooltip: 'Reject/Delete',
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          onPressed: () {
                            if (isReportTab) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EditPendingReport(doc: doc)));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EditPendingSong(doc: doc)));
                            }
                          },
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          label: const Text("Edit", style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _showConfirmDialog(context, doc, true),
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: Text(isReportTab ? "Resolve & Live" : "Approve", style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChordList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var doc = docs[index];
        var data = doc.data() as Map<String, dynamic>;

        return Card(
          color: Colors.blueGrey.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ExpansionTile(
            iconColor: Colors.white,
            collapsedIconColor: Colors.white54,
            title: Text(data['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("Sa Tu: ${data['singer'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white70)),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Chord Key: ${data['key']}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    if (data['uploaderEmail'] != null)
                      Text("Uploaded by: ${data['uploaderEmail']}", style: const TextStyle(color: Colors.greenAccent, fontStyle: FontStyle.italic)),
                    if (data['ytLink'] != null && data['ytLink'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text("YouTube: ${data['ytLink']}", style: const TextStyle(color: Colors.redAccent)),
                      ),
                    const Divider(color: Colors.white24),
                    const Text("Chords:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(data['chords'] ?? '', style: const TextStyle(color: Colors.white, height: 1.5)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => _showChordConfirmDialog(context, doc, false),
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                          tooltip: 'Reject/Delete',
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AddChordPage(
                              title: doc['title'],
                              chordKey: doc['key'],
                              singer: doc['singer'],
                              chordsController: doc['chords'],
                              ytController: doc['ytLink'],
                              edit: doc['title'],
                            )));
                          },
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          label: const Text("Edit", style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _showChordConfirmDialog(context, doc, true),
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text("Approve Chord", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EditPendingSong extends StatefulWidget {
  final DocumentSnapshot doc;
  const EditPendingSong({super.key, required this.doc});

  @override
  State<EditPendingSong> createState() => _EditPendingSongState();
}

class _EditPendingSongState extends State<EditPendingSong> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _singerController;
  late TextEditingController _composerController;
  late TextEditingController _verse1Controller;
  late TextEditingController _verse2Controller;
  late TextEditingController _verse3Controller;
  late TextEditingController _verse4Controller;
  late TextEditingController _verse5Controller;
  late TextEditingController _chorusController;
  late TextEditingController _endingChorusController;
  late TextEditingController _songTrackController;

  bool _isUpdating = false;
  bool _hasChord = false;
  String _selectedCategory = 'hladang';

  final List<String> categories = [
    'pathian-hla',
    'christmas-hla',
    'kumthar-hla',
    'thitumnak-hla',
    'ram-hla',
    'zun-hla',
    'hladang'
  ];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> data = widget.doc.data() as Map<String, dynamic>;

    _titleController = TextEditingController(text: data['title'] ?? '');
    _singerController = TextEditingController(text: data['singer'] ?? '');
    _composerController = TextEditingController(text: data['composer'] ?? '');
    _verse1Controller = TextEditingController(text: data['verse1'] ?? '');
    _verse2Controller = TextEditingController(text: data['verse2'] ?? '');
    _verse3Controller = TextEditingController(text: data['verse3'] ?? '');
    _verse4Controller = TextEditingController(text: data['verse4'] ?? '');
    _verse5Controller = TextEditingController(text: data['verse5'] ?? '');
    _chorusController = TextEditingController(text: data['chorus'] ?? '');
    _endingChorusController = TextEditingController(text: data['endingchorus'] ?? '');
    _songTrackController = TextEditingController(text: data['songtrack'] ?? '');

    _hasChord = data['chord'] ?? false;
    String cat = data['category'] ?? 'hladang';
    _selectedCategory = categories.contains(cat) ? cat : 'hladang';
  }

  Future<void> _updateSong() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('songToEdit')
          .doc(widget.doc.id)
          .update({
        'title': _titleController.text.trim(),
        'singer': _singerController.text.trim(),
        'composer': _composerController.text.trim(),
        'verse1': _verse1Controller.text.trim(),
        'verse2': _verse2Controller.text.trim(),
        'verse3': _verse3Controller.text.trim(),
        'verse4': _verse4Controller.text.trim(),
        'verse5': _verse5Controller.text.trim(),
        'chorus': _chorusController.text.trim(),
        'endingchorus': _endingChorusController.text.trim(),
        'songtrack': _songTrackController.text.trim(),
        'chord': _hasChord,
        'category': _selectedCategory,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _singerController.dispose();
    _composerController.dispose();
    _verse1Controller.dispose();
    _verse2Controller.dispose();
    _verse3Controller.dispose();
    _verse4Controller.dispose();
    _verse5Controller.dispose();
    _chorusController.dispose();
    _endingChorusController.dispose();
    _songTrackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black12,
        title: const Text('Edit Pending Song', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hla Konglam (Info)", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_titleController, 'Hla Min (Title)'),
              _buildTextField(_singerController, 'Satu (Singer)'),
              _buildTextField(_composerController, 'Phantu (Composer)'),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    value: _selectedCategory,
                    style: const TextStyle(color: Colors.white),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(value: category, child: Text(category.toUpperCase()));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() { _selectedCategory = newValue!; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text("Chord a tel maw?", style: TextStyle(color: Colors.white)),
                checkColor: Colors.white,
                activeColor: Colors.blueAccent,
                tileColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                value: _hasChord,
                onChanged: (bool? value) {
                  setState(() { _hasChord = value ?? false; });
                },
              ),
              const SizedBox(height: 20),

              const Text("Hla Bia (Lyrics)", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_verse1Controller, 'Verse 1', maxLines: 4),
              _buildTextField(_chorusController, 'Chorus', maxLines: 4),
              _buildTextField(_verse2Controller, 'Verse 2', maxLines: 4),
              _buildTextField(_verse3Controller, 'Verse 3', maxLines: 4),
              _buildTextField(_verse4Controller, 'Verse 4', maxLines: 4),
              _buildTextField(_verse5Controller, 'Verse 5', maxLines: 4),
              _buildTextField(_endingChorusController, 'Ending Chorus', maxLines: 3),

              const SizedBox(height: 10),
              const Text("Audio Track (Optional)", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_songTrackController, 'Karaoke soundtrack link'),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: _updateSong,
                  child: const Text("UPDATE SONG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class EditPendingReport extends StatefulWidget {
  final DocumentSnapshot doc;
  const EditPendingReport({super.key, required this.doc});

  @override
  State<EditPendingReport> createState() => _EditPendingReportState();
}

class _EditPendingReportState extends State<EditPendingReport> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _singerController;
  late TextEditingController _composerController;
  late TextEditingController _verse1Controller;
  late TextEditingController _verse2Controller;
  late TextEditingController _verse3Controller;
  late TextEditingController _verse4Controller;
  late TextEditingController _verse5Controller;
  late TextEditingController _chorusController;
  late TextEditingController _endingChorusController;
  late TextEditingController _songTrackController;

  bool _isUpdating = false;
  bool _hasChord = false;
  String _selectedCategory = 'hladang';

  final List<String> categories = [
    'pathian-hla',
    'christmas-hla',
    'kumthar-hla',
    'thitumnak-hla',
    'ram-hla',
    'zun-hla',
    'hladang'
  ];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> data = widget.doc.data() as Map<String, dynamic>;

    _titleController = TextEditingController(text: data['title'] ?? '');
    _singerController = TextEditingController(text: data['singer'] ?? '');
    _composerController = TextEditingController(text: data['composer'] ?? '');
    _verse1Controller = TextEditingController(text: data['verse1'] ?? '');
    _verse2Controller = TextEditingController(text: data['verse2'] ?? '');
    _verse3Controller = TextEditingController(text: data['verse3'] ?? '');
    _verse4Controller = TextEditingController(text: data['verse4'] ?? '');
    _verse5Controller = TextEditingController(text: data['verse5'] ?? '');
    _chorusController = TextEditingController(text: data['chorus'] ?? '');
    _endingChorusController = TextEditingController(text: data['endingchorus'] ?? '');
    _songTrackController = TextEditingController(text: data['songtrack'] ?? '');

    _hasChord = data['chord'] ?? false;
    String cat = data['category'] ?? 'hladang';
    _selectedCategory = categories.contains(cat) ? cat : 'hladang';
  }

  Future<void> _updateSong() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    try {
      // REMHNAK 2: 'reports' si loin 'songToEdit' ah save tthannak a si
      await FirebaseFirestore.instance
          .collection('songToEdit')
          .doc(widget.doc.id)
          .update({
        'title': _titleController.text.trim(),
        'singer': _singerController.text.trim(),
        'composer': _composerController.text.trim(),
        'verse1': _verse1Controller.text.trim(),
        'verse2': _verse2Controller.text.trim(),
        'verse3': _verse3Controller.text.trim(),
        'verse4': _verse4Controller.text.trim(),
        'verse5': _verse5Controller.text.trim(),
        'chorus': _chorusController.text.trim(),
        'endingchorus': _endingChorusController.text.trim(),
        'songtrack': _songTrackController.text.trim(),
        'chord': _hasChord,
        'category': _selectedCategory,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _singerController.dispose();
    _composerController.dispose();
    _verse1Controller.dispose();
    _verse2Controller.dispose();
    _verse3Controller.dispose();
    _verse4Controller.dispose();
    _verse5Controller.dispose();
    _chorusController.dispose();
    _endingChorusController.dispose();
    _songTrackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black12,
        title: const Text('Edit Pending Report', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hla Konglam (Info)", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_titleController, 'Hla Min (Title)'),
              _buildTextField(_singerController, 'Satu (Singer)'),
              _buildTextField(_composerController, 'Phantu (Composer)'),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    value: _selectedCategory,
                    style: const TextStyle(color: Colors.white),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(value: category, child: Text(category.toUpperCase()));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() { _selectedCategory = newValue!; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text("Chord a tel maw?", style: TextStyle(color: Colors.white)),
                checkColor: Colors.white,
                activeColor: Colors.blueAccent,
                tileColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                value: _hasChord,
                onChanged: (bool? value) {
                  setState(() { _hasChord = value ?? false; });
                },
              ),
              const SizedBox(height: 20),

              const Text("Hla Bia (Lyrics)", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_verse1Controller, 'Verse 1', maxLines: 4),
              _buildTextField(_chorusController, 'Chorus', maxLines: 4),
              _buildTextField(_verse2Controller, 'Verse 2', maxLines: 4),
              _buildTextField(_verse3Controller, 'Verse 3', maxLines: 4),
              _buildTextField(_verse4Controller, 'Verse 4', maxLines: 4),
              _buildTextField(_verse5Controller, 'Verse 5', maxLines: 4),
              _buildTextField(_endingChorusController, 'Ending Chorus', maxLines: 3),

              const SizedBox(height: 10),
              const Text("Audio Track (Optional)", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_songTrackController, 'Karaoke soundtrack link'),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: _updateSong,
                  child: const Text("UPDATE REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}