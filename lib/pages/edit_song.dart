

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditLyrics extends StatefulWidget {
  final DocumentSnapshot doc;
  const EditLyrics({super.key, required this.doc});

  @override
  State<EditLyrics> createState() => _EditLyricsState();
}

class _EditLyricsState extends State<EditLyrics> {
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
          .collection('hla')
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
        title: const Text('Edit Lyrics', style: TextStyle(color: Colors.white)),
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
