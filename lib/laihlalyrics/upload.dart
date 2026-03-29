import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ================= A BIAPI BIK =================
// Na home feed page ah pehnak (Import tuah a hau)
import 'package:chinlyrics/laihlalyrics/home_feed.dart';

import 'isar/home.dart';
import 'model/song_model.dart';

class UploadPage extends StatefulWidget {
  final VoidCallback? onUploadSuccess;
  final Map<String, dynamic>?
      editSong; // Map ah SongModel na pek sual theu tawn, check te mu

  const UploadPage({super.key, this.onUploadSuccess, this.editSong});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _singerController = TextEditingController();
  final TextEditingController soundtrack = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String _selectedCategory = 'Gospel';
  final List<String> _categories = [
    'Gospel',
    'Ramhla',
    'Zunhla',
    'Christmas',
    'Kumthar',
    'Kawl hla',
  ];
  bool _isChord = false;

  bool _isLoading = false;
  bool _isEditing = false; // Edit lio a si maw theihnak ding
  String? _editDocId; // Edit a si ahcun Firebase ID

  // ================= A THAR: CHORD FAMILY & PREVIEW =================
  bool _showPreview = false; // Preview zohnak on/off
  String _selectedChordFamily = 'C'; // A hramthawk ah C Key

  final Map<String, List<String>> _chordFamilies = {
    'C': ['[C]', '[Dm]', '[Em]', '[F]', '[G]', '[Am]'],
    'D': ['[D]', '[Em]', '[F#m]', '[G]', '[A]', '[Bm]'],
    'E': ['[E]', '[F#m]', '[G#m]', '[A]', '[B]', '[C#m]'],
    'F': ['[F]', '[Gm]', '[Am]', '[Bb]', '[C]', '[Dm]'],
    'G': ['[G]', '[Am]', '[Bm]', '[C]', '[D]', '[Em]'],
    'A': ['[A]', '[Bm]', '[C#m]', '[D]', '[E]', '[F#m]'],
    'Bb': ['[Bb]', '[Cm]', '[Dm]', '[Eb]', '[F]', '[Gm]'],
  };

  void _addChord(String chord) {
    final text = _lyricsController.text;
    final selection = _lyricsController.selection;
    // Selection a tthat lo sual ahcun a donghnak ah a chap lai
    final offset =
        selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    final newText = text.replaceRange(offset, offset, chord);
    _lyricsController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + chord.length),
    );
  }

// ================= VERSE & CHORUS AUTO-INSERT =================
  void _insertTag(String tag) {
    final text = _lyricsController.text;
    final selection = _lyricsController.selection;
    // Selection a um lo ahcun a donghnak ah a chap lai
    final offset =
        selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    // Tag le a tang tlar thar (Newline) fawi tein a chap lai
    final insertion = '$tag\n';
    final newText = text.replaceRange(offset, offset, insertion);

    _lyricsController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + insertion.length),
    );
  }

  @override
  void initState() {
    super.initState();
    // ================= EDIT LIO A SI AHCUN DATA LAAK =================
    if (widget.editSong != null) {
      _isEditing = true;
      _editDocId =
          widget.editSong!['id']; // Firestore Document ID a hau hrimhrim lai

      _titleController.text = widget.editSong!['title'] ?? '';
      _singerController.text = widget.editSong!['singer'] ?? '';
      _lyricsController.text = widget.editSong!['lyrics'] ?? '';
      soundtrack.text = widget.editSong!['soundtrack'] ?? '';

      // Category cu list chungah a ummi a si lo ahcun Gospel ah chiah ding
      String cat = widget.editSong!['category'] ?? 'Gospel';
      _selectedCategory = _categories.contains(cat) ? cat : 'Gospel';

      _isChord = widget.editSong!['isChord'] ?? false;
    }
  }

  void _submitSong() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        Map<String, dynamic> songData = {
          'title': _titleController.text.trim(),
          'singer': _singerController.text.trim(),
          'soundtrack': soundtrack.text.trim(),
          'category': _selectedCategory,
          'isChord': _isChord,
          'lyrics': _lyricsController.text.trim(),
          'uploaderId': currentUser.uid,
          'approved': false, // Admin nih approve a hau ti theihnak
          'likes': 0,
          'comments': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_isEditing && _editDocId != null) {
          // Edit a si ahcun 'songs' ah a um cia caah update kan tuah thotho lai
          await FirebaseFirestore.instance
              .collection('songs')
              .doc(_editDocId)
              .update(songData);
        } else {
          // HLA THAR: 'songs' ah thun lo in 'toCheck' ah kan thun cang lai
          await FirebaseFirestore.instance.collection('toCheck').add(songData);

          // Note: Local UI (Isar) ah kan insert ti lai lo,
          // Zeicah tiah Admin approve a hngah rih caah a si.
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Admin sinah kuat a si cang, a hnu deuh ah a ra lang lai."),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _singerController.dispose();
    soundtrack.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // A hrampi rong
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_isEditing ? "Data Remhnak (Edit)" : "Data Thunnak",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _submitSong,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isEditing ? "Update" : "Upload",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                _buildLabel("Hla Title"),
                _buildTextField(
                    controller: _titleController,
                    hintText: "Eg: Bawipa Cu Ka Khamhtu",
                    icon: Icons.title,
                    validator: (value) =>
                        value!.trim().isEmpty ? "Min tial a hau" : null),
                const SizedBox(height: 20),

                // HLA LAWNG CAAH (Singer, Category, Chord, Soundtrack)

                _buildLabel("Satu (Singer)"),
                _buildTextField(
                    controller: _singerController,
                    hintText: "Tahchunhnak: Van Hlei Sung",
                    icon: Icons.person,
                    validator: (value) =>
                        value!.trim().isEmpty ? "Min tial a hau" : null),
                const SizedBox(height: 20),
                _buildLabel("Phun (Category)"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: Colors.grey[800],
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white54),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                            value: category, child: Text(category));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: _isChord
                              ? Colors.blueAccent
                              : Colors.transparent)),
                  child: SwitchListTile(
                    title: const Text("Guitar Chord aa tel maw?",
                        style: TextStyle(color: Colors.white)),
                    activeColor: Colors.blueAccent,
                    contentPadding: EdgeInsets.zero,
                    value: _isChord,
                    onChanged: (bool value) {
                      setState(() {
                        _isChord = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Soundtrack Link (Optional)"),
                currentUser?.email == 'itrungrul@gmail.com'
                    ? buildTrackerTextField(
                        controller: soundtrack,
                        hintText: " Audio link hika ah chia...",
                        maxLines: 1,
                      )
                    : Container(),
                const SizedBox(height: 20),

                // LYRICS / CONTENT
                _buildLabel("Hla Bia (Lyrics)"),
                // ================= CHORD QUICK BAR (MULTI-KEY) =================
                if (_isChord) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel("Quick Chords"),
                      // Key Thimnak Dropdown
                      DropdownButton<String>(
                        value: _selectedChordFamily,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        icon: const Icon(Icons.music_note,
                            color: Colors.blueAccent, size: 18),
                        underline: const SizedBox(),
                        items: _chordFamilies.keys.map((String key) {
                          return DropdownMenuItem<String>(
                              value: key, child: Text("Key: $key"));
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedChordFamily = newValue);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _chordFamilies[_selectedChordFamily]!.length,
                      itemBuilder: (context, index) {
                        String chord =
                            _chordFamilies[_selectedChordFamily]![index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
                            label: Text(chord,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            onPressed: () => _addChord(chord),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                ],

                // ================= LYRICS INPUT LE PREVIEW TOGGLE =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Preview hmehnak Button
                    TextButton.icon(
                      icon: Icon(_showPreview ? Icons.edit : Icons.visibility,
                          color: Colors.greenAccent, size: 18),
                      label: Text(_showPreview ? "Edit Tuah" : "Preview Zoh",
                          style: const TextStyle(color: Colors.greenAccent)),
                      onPressed: () =>
                          setState(() => _showPreview = !_showPreview),
                    ),
                    Row(
                      children: [
                        _buildLabel("Hla Bia (Lyrics)"),
                        IconButton(
                          icon: const Icon(Icons.help_outline,
                              color: Colors.blueAccent, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showFormatHelpDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),

                if (!_showPreview)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
                    child: Row(
                      children: [
                        ActionChip(
                          backgroundColor: Colors.greenAccent.withOpacity(0.15),
                          side: BorderSide.none,
                          label: const Text("+ {verse}",
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () => _insertTag("{verse}"),
                        ),
                        const SizedBox(width: 10),
                        ActionChip(
                          backgroundColor:
                              Colors.orangeAccent.withOpacity(0.15),
                          side: BorderSide.none,
                          label: const Text("+ {chorus}",
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () => _insertTag("{chorus}"),
                        ),
                      ],
                    ),
                  ),
                // Preview on a si ahcun Detail UI thengte a lang lai, a si lo ahcun TextField a lang lai
                _showPreview
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Ca a um lo ahcun theihternak a lang lai
                          children: _lyricsController.text.trim().isEmpty
                              ? [
                                  const Text("Ca tialmi a um rih lo...",
                                      style: TextStyle(color: Colors.white54))
                                ]
                              : _buildLyricsUI(_lyricsController.text),
                        ),
                      )
                    : _buildTextField(
                        controller: _lyricsController,
                        hintText:
                            "Tahchunhnak:\n{verse}\n[C]Bawipa cu ka khamhtu a si...",
                        maxLines: 15,
                        validator: (value) =>
                            value!.trim().isEmpty ? "Ca na tial rih lo" : null,
                      ),
                const SizedBox(height: 30),
                const SizedBox(height: 30),
                const SizedBox(height: 30),

                // SUBMIT BUTTON

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14)));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hintText,
      IconData? icon,
      int maxLines = 1,
      required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      ),
      validator: validator,
    );
  }

  Widget buildTrackerTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      ),
    );
  }

  // ================= PREVIEW UI BUILDER (Detail Page Bantuk) =================
  List<Widget> _buildLyricsUI(String rawLyrics) {
    List<Widget> widgets = [];

    // User nih {verse} asiloah {chorus} a tial rih lo ahcun amah tein a hramthawk ah a chap lai
    if (!rawLyrics.contains('{verse}') && !rawLyrics.contains('{chorus}')) {
      rawLyrics = '{verse}\n$rawLyrics';
    }

    List<String> blocks = rawLyrics.split(RegExp(r'(?=\{verse\}|\{chorus\})'));

    for (String block in blocks) {
      if (block.trim().isEmpty) continue;

      bool isChorus = block.startsWith('{chorus}');
      String lyricsBlock = "";

      // Tag {} a um taktak maw check nak
      if (block.contains('{') && block.contains('}')) {
        lyricsBlock = block.split('{').last.split('}').first.toString();
      }

      String cleanText =
          block.replaceAll('{verse}', '').replaceAll('{chorus}', '').trim();
      if (cleanText.isEmpty) continue;

      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: isChorus
              ? BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: Colors.blueAccent.withOpacity(0.8), width: 3)),
                )
              : null,
          child: _buildLyricSectionWithChords(
            text: cleanText,
            lyricsBlock: lyricsBlock.isNotEmpty ? lyricsBlock : 'verse',
            isChorus: isChorus,
            showChord: _isChord, // Switch na on/off ning in a lang/tlau lai
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildLyricSectionWithChords({
    required String text,
    required String lyricsBlock,
    required bool showChord,
    required bool isChorus,
  }) {
    double currentFontSize = isChorus ? 16 + 1 : 15;
    FontWeight fw = isChorus ? FontWeight.bold : FontWeight.w600;
    Color txtColor = isChorus ? Colors.white : Colors.white70;
    double leftPad = isChorus ? 15.0 : 0.0;

    // 1. CHORD PHIH (OFF) A SI AHCUN
    if (!showChord) {
      String cleanLyrics = text.replaceAll(RegExp(r'\[.*?\]'), '');
      return Padding(
        padding: EdgeInsets.only(left: leftPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$lyricsBlock ⤵️',
              style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: currentFontSize - 3,
                  height: 1.6,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              cleanLyrics,
              style: TextStyle(
                  color: txtColor,
                  fontSize: currentFontSize,
                  fontWeight: fw,
                  height: 1.5),
            ),
          ],
        ),
      );
    }

    // 2. CHORD ON A SI AHCUN
    List<String> chordsList = [];
    List<String> lyricsList = [];
    List<String> parts = text.split('[');

    for (var part in parts) {
      if (part.contains(']')) {
        List<String> splitPart = part.split(']');
        chordsList.add('[${splitPart[0]}]'); // Bracket he langhter tthan
        lyricsList.add(splitPart.length > 1 ? splitPart[1] : "");
      } else {
        chordsList.add("");
        lyricsList.add(part);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftPad),
          child: Text(
            '$lyricsBlock ⤵️',
            style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: currentFontSize - 3,
                height: 1.6,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: EdgeInsets.only(left: leftPad),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: List.generate(chordsList.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CHORD
                  if (chordsList[index].isNotEmpty)
                    Text(
                      chordsList[index].split('[').last.split(']').first,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          fontSize: currentFontSize - 2),
                    ),
                  // LYRIC
                  Text(
                    lyricsList[index],
                    style: TextStyle(
                        color: txtColor,
                        fontSize: currentFontSize,
                        fontWeight: fw,
                        height: 1.5),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ================= FORMAT THEIHTERNAK DIALOG =================
  void _showFormatHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.yellowAccent),
              SizedBox(width: 10),
              Text("Zeitindah tial ding?",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Hla bia kha a dawh bik in a langh nakhnga a tanglei bantuk hin tialpiak:",
                    style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 15),
                const Text("1. Hla Hramthawk (Verse) caah:",
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 5, bottom: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("{verse}\n[C]Bawipa cu ka khamhtu a si...",
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'monospace')),
                ),
                const Text("2. A Tlakmi (Chorus) caah:",
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold)),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 5, bottom: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text("{chorus}\n[F]Amah lawng in a za...",
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'monospace')),
                ),
                const Text(
                    "Note: {verse} asiloah {chorus} na tial lo zongah amah tein a hramthawk ah a chap ko lai.",
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ka Theithiam",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}
