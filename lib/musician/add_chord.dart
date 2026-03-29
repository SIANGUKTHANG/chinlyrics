import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads_manager.dart';

class AddChordPage extends StatefulWidget {
  final String title;
  final String singer;
  final String chordKey;
  final String ytController;
  final String edit;
  final String chordsController;

  const AddChordPage({
    super.key,
    required this.chordKey,
    required this.title,
    required this.singer,
    required this.ytController,
    required this.edit,
    required this.chordsController,
  });

  @override
  State<AddChordPage> createState() => _AddChordPageState();
}

class _AddChordPageState extends State<AddChordPage>
    with SingleTickerProviderStateMixin {
  TextEditingController titleController = TextEditingController();
  TextEditingController ytController = TextEditingController();
  TextEditingController singerController = TextEditingController();
  TextEditingController chordsController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool showHide = false;
  bool isUploading = false;
  String chordText = '';
  String selectedKey = 'C';
  late TabController tabController;
  bool isKeyboardVisible = false;

  // A THAR: Interstitial Ad caah
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  final chordFamilies = {
    'C': ['C', 'F', 'G', 'Am', 'Em', 'Dm', '_'],
    'C#': ['C#', 'F#', 'G#', 'A#m', 'Fm', 'D#m', '_'],
    'D♭': ['D♭', 'G♭', 'A♭', 'B♭m', 'Fm', 'E♭m', '_'],
    'D': ['D', 'G', 'A', 'Bm', 'F#m', 'Em', '_'],
    'D#': ['D#', 'G#', 'A#', 'Cm', 'Gm', 'Fm', '_'],
    'E♭': ['E♭', 'A♭', 'B♭', 'Cm', 'Gm', 'Fm', '_'],
    'E': ['E', 'A', 'B', 'C#m', 'G#m', 'F#m', '_'],
    'F': ['F', 'B♭', 'C', 'Dm', 'Am', 'Gm', '_'],
    'F#': ['F#', 'B', 'C#', 'D#m', 'A#m', 'G#m', '_'],
    'G♭': ['G♭', 'B', 'D♭', 'Ebm', 'B♭m', 'Abm', '_'],
    'G': ['G', 'C', 'D', 'Em', 'Bm', 'Am', '_'],
    'G#': ['G#', 'C#', 'D#', 'Fm', 'Cm', 'A#m', '_'],
    'A♭': ['A♭', 'D♭', 'E♭', 'Fm', 'Cm', 'B♭m', '_'],
    'A': ['A', 'D', 'E', 'F#m', 'C#m', 'Bm', '_'],
    'A#': ['A#', 'D#', 'F', 'Gm', 'Dm', 'Cm', '_'],
    'B♭': ['B♭', 'E♭', 'F', 'Gm', 'Dm', 'Cm', '_'],
    'B': ['B', 'E', 'F#', 'G#m', 'D#m', 'C#m', '_'],
  };

  final numbers = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '#',
    'b',
    '1\u0323',
    '2\u0323',
    '3\u0323',
    '4\u0323',
    '5\u0323',
    '6\u0323',
    '7\u0323',
  ];

  final extensionChords = [' | ', 'sus4', 'Space', '|:', ':|', '  ↵  '];

  final signature = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'maj7',
    'm',
    'sus2',
    'solo',
    'only',
    '<Drum>',
    '<kb>',
    '<Guitar>',
    '<rhythm>',
    '<Bass>',
    '~',
    '-',
    '/',
    ':',
    'D.S.',
    'D.C.',
    'Coda',
    'Fine',
    '  ↵  '
  ];

  final symbolColor = {
    ':|': Colors.red,
    '|:': Colors.red,
    '||': Colors.redAccent,
    '|': Colors.grey,
    'D.C.': Colors.green,
    'D.S.': Colors.green,
    'Fine': Colors.purple,
    'Coda': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    if (widget.chordKey != '') {
      selectedKey = widget.chordKey;
    }
    titleController.text = widget.title;
    singerController.text = widget.singer;
    ytController.text = widget.ytController;
    chordsController.text = widget.chordsController;
    chordText = chordsController.text;

    tabController.addListener(() {
      if (mounted) setState(() {});
    });
   //_loadInterstitialAd();
  }

  // Interstitial Ad Load Tuahnak
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      // ads_manager.dart ah hihi a um a hau
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose(); // Ad a fail zongah Page cu a kir thiamthiam lai
            },
          );

          setState(() {
            _interstitialAd = ad;
            _isAdReady = true;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
          _isAdReady = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    titleController.dispose();
    singerController.dispose();
    ytController.dispose();
    chordsController.dispose();
    super.dispose();
  }

  Future<void> saveChordToFirebase() async {
    if (titleController.text.trim().isEmpty ||
        singerController.text.trim().isEmpty ||
        chordsController.text.trim().isEmpty) {

      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentReference id = await FirebaseFirestore.instance.collection('musicianChords').add({
        'title': titleController.text.trim(),
        'singer': singerController.text.trim(),
        'chords': chordsController.text.trim(),
        'key': selectedKey,
        'ytLink': ytController.text.trim(),
        'uploaderUid': currentUser?.uid ?? 'Unknown',
        'uploaderEmail': currentUser?.email ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'musician_chord',
        'status': 'pending',
      });

      DocumentReference metaRef = FirebaseFirestore.instance.collection('metamusic').doc('part_1');
      DocumentSnapshot metaDoc = await metaRef.get();

      Map<String, dynamic> songsMap = {};
      if (metaDoc.exists && metaDoc.data() != null) {
        Map<String, dynamic> metaData = metaDoc.data() as Map<String, dynamic>;
        if (metaData.containsKey('songs_map')) {
          songsMap = Map<String, dynamic>.from(metaData['songs_map']);
        }
      }

      // REMHNAK 1: songtrack hi string a si caah isNotEmpty in check a si
      songsMap[id.id] = {
        'title': titleController.text.trim(),
        'singer': singerController.text.trim(),
        'uploaderUid': currentUser?.uid ?? 'Unknown',

      };

      await metaRef.set({
        'songs_map': songsMap,
        'total_songs': songsMap.length,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_isAdReady && _interstitialAd != null) {
        _interstitialAd!.show();
      }


      if (mounted) Navigator.pop(context);
    } catch (e) {
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void toggleKeyboard() {
    setState(() {
      isKeyboardVisible = !isKeyboardVisible;
      if (isKeyboardVisible) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    });
  }

  int _calculateBarsPerRow(double width) {
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 800) return 4;
    return 5;
  }

  void addText(String input) {
    final text = chordsController.text;
    var selection = chordsController.selection;
    var cursorPos = selection.baseOffset;

    // 1. Cursor a um lo (focus a loh) ahcun, a donghnak bik ah kan chiah lai
    if (cursorPos < 0) {
      cursorPos = text.length;
    }

    String newText = text;
    int newCursorPos = cursorPos;

    if (input == 'x' || input == 'Clear') {
      if (cursorPos == 0) return;
      newText = text.replaceRange(cursorPos - 1, cursorPos, '');
      newCursorPos = cursorPos - 1;
    } else if (input == 'Space') {
      newText = text.replaceRange(cursorPos, cursorPos, ' ');
      newCursorPos = cursorPos + 1;
    } else {
      final spaceNeeded = RegExp(r'^[A-G][#b♭]?[a-zA-Z0-9]*$').hasMatch(input);
      final textToInsert = spaceNeeded ? ' $input' : input;

      newText = text.replaceRange(cursorPos, cursorPos, textToInsert);
      newCursorPos = cursorPos + textToInsert.length;
    }

    // 2. Text le Cursor position thar kan pek lai
    chordsController.text = newText;
    chordsController.selection = TextSelection.collapsed(offset: newCursorPos);

    // 3. A BIAPI BIK: TextField kha Focus kan pek tthan lai (Cursor a langh peng nakhnga)
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }

    setState(() {
      chordText = chordsController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyChords = chordFamilies[selectedKey] ?? [];
    final sections = parseStructuredChords(chordsController.text);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: showHide
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(widget.edit,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              actions: [
                isUploading
                    ? const Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.redAccent, strokeWidth: 2))),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: saveChordToFirebase,
                        icon: const Icon(Icons.cloud_upload, size: 18),
                        label: const Text('Save'),
                      ),
                const SizedBox(width: 10),
              ],
            ),
      bottomNavigationBar: Container(
        color: Colors.grey[900],
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                  onPressed: () => setState(() => showHide = !showHide),
                  icon:
                      Icon(showHide ? Icons.visibility_off : Icons.visibility),
                  label: Text(showHide ? 'Edit Mode' : 'Preview'),
                ),
                IconButton(
                  onPressed: toggleKeyboard,
                  icon: Icon(
                      isKeyboardVisible ? Icons.keyboard_hide : Icons.keyboard,
                      color: Colors.white),
                ),
                TextButton(
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () => addText('x'),
                  child: const Text('Clear',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
            if (!showHide)
              TabBar(
                controller: tabController,
                indicatorColor: Colors.redAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Chord'),
                  Tab(text: 'Number'),
                  Tab(text: 'Sign')
                ],
              ),
            if (!showHide)
              // Keyboard height tlawmpal ka kauh (size.height / 3.0) button a ngan deuh caah
              SizedBox(
                height: MediaQuery.of(context).size.height / 4.0,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            buildKeyboardRow(familyChords),
                            const SizedBox(height: 12),
                            const SizedBox(height: 20),
                            buildKeyboardRow(extensionChords),
                            const SizedBox(height: 20),
                            buildKeyboardRow([
                              'Intro',
                              'Verse',
                              'Cho',
                              'Bridge',
                              'Ending',
                            ]),
                          ],
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          buildKeyboardRow(
                              ['[', ']', '<', '>', '{', '}', '.', ',']),
                          const SizedBox(height: 12),
                          buildKeyboardRow(numbers),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 20),
                            child: buildKeyboardRow(signature))),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHide)
                SafeArea(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: sections.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                "Preview langh ding a um rih lo. Chord te pawlkha '| C | G |' ti bantuk in '|' hmang in va tial hmanh.",
                                style: TextStyle(color: Colors.white54),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sections.map((section) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 15),
                                  Text(
                                    section.name.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 6),
                                  ...section.blocks.map((block) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (block.label != null)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2.0),
                                            child: Text(
                                              '> ${block.label!} ',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blueAccent),
                                            ),
                                          ),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final barsPerRow =
                                                _calculateBarsPerRow(
                                                    constraints.maxWidth);
                                            final barWidth =
                                                (constraints.maxWidth -
                                                        (barsPerRow - 1) * 8) /
                                                    barsPerRow;

                                            return Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: block.bars
                                                  .map((bar) => Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 2.0),
                                                        child: _buildChordBar(
                                                            context,
                                                            bar,
                                                            barWidth),
                                                      ))
                                                  .toList(),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                )
              else
                Column(
                  children: [
                    _buildTextField(titleController, 'Song Title'),
                    const SizedBox(height: 10),
                    _buildTextField(singerController, 'Singer Name'),
                    const SizedBox(height: 10),
                    _buildTextField(ytController, 'YouTube Link (Optional)'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: Colors.grey[900],
                          value: selectedKey,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) =>
                              setState(() => selectedKey = value!),
                          items: chordFamilies.keys
                              .map((key) => DropdownMenuItem(
                                  value: key, child: Text('Key: $key')))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: chordsController,
                        focusNode: _focusNode,
                        readOnly: !isKeyboardVisible,

                        // HIKA HI CHAP DING: readOnly a si lio zongah Cursor a langh peng lai
                        showCursor: true,

                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, height: 1.6),
                        maxLines: 15,
                        minLines: 8,
                        onTap: () {
                          setState(() => isKeyboardVisible = false);
                          // User nih a hmeh tikah focus kan laak colh lai
                          _focusNode.requestFocus();
                        },
                        onChanged: (value) => setState(() => chordText = value),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter chords here...",
                            hintStyle: TextStyle(color: Colors.white24)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
    );
  }

  // --- A BIAPI BIK REMHNAK (KEYBOARD BUTTON NGAN DEUH IN) ---
  Widget buildKeyboardRow(List<String> keys) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: keys.map((key) {
        final isDelete = key == 'x' || key == 'Clear';
        final isSpace = key == 'Space';

        return GestureDetector(
          onTap: () {
            if (key == '↵' || key == '  ↵  ') {
              addText('\n');
            } else if (isSpace) {
              addText('Space'); // addText logic chungah a thlen lai
            } else if (isDelete) {
              addText('x');
            } else if ('-' == key || key == ' - ') {
              addText(' -');
            } else {
              addText(key);
            }
          },
          child: Container(
            // Space button a si ahcun width a ngan deuh in kan pek (A lai ah a sau ding)
            width: isSpace ? 100 : null,
            padding: EdgeInsets.symmetric(
                vertical: isSpace ? 8 : 6, // Button San deuh nakhnga (Height)
                horizontal: isSpace ? 0 : 12 // Button Kau deuh nakhnga (Width)
                ),
            decoration: BoxDecoration(
              color: isDelete
                  ? Colors.redAccent.withOpacity(0.2)
                  : (isSpace
                      ? Colors.blueAccent.withOpacity(0.2)
                      : Colors.white12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDelete
                      ? Colors.redAccent
                      : (isSpace ? Colors.blueAccent : Colors.white24)),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)
              ],
            ),
            child: Text(
              isDelete ? 'Clear' : (isSpace ? 'SPACE' : key.trim()),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Font ngan deuh (hmuh fawi deuh nakhnga)
                fontWeight: FontWeight.bold,
                color: isDelete
                    ? Colors.redAccent
                    : (isSpace ? Colors.blueAccent : Colors.white),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- LOGIC FUNCTIONS ---
  List<ChordSection> parseStructuredChords(String input) {
    final lines = input.trim().split('\n');
    final List<ChordSection> sections = [];
    String? currentSection;
    List<ChordBlock> currentBlocks = [];
    String? currentLabel;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (!trimmed.contains('|') && !trimmed.startsWith('<')) {
        if (currentSection != null || currentBlocks.isNotEmpty) {
          sections.add(
              ChordSection(name: currentSection ?? '', blocks: currentBlocks));
        }
        currentSection = trimmed;
        currentBlocks = [];
        currentLabel = null;
      } else if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
        currentLabel = trimmed.substring(1, trimmed.length - 1);
      } else if (trimmed.contains('|')) {
        currentBlocks
            .add(ChordBlock(label: currentLabel, bars: _extractBars(trimmed)));
        currentLabel = null;
      }
    }
    if (currentSection != null || currentBlocks.isNotEmpty) {
      sections
          .add(ChordSection(name: currentSection ?? '', blocks: currentBlocks));
    }
    return sections;
  }

  List<Map> _splitChordsWithNotes(String bar, [int transposeShift = 0]) {
    final regex = RegExp(
        r'(\|\:|\:\||\|\||\||D\.C\.|D\.S\.|Fine|Coda|Segno|To Coda|~|>)' +
            r'|' +
            r'(?:\{([^\}]+)\})?' +
            r'([A-G][#b♭]?(?:\/[A-G][#b♭]?)?[a-zA-Z0-9#b♭]*)?' +
            r'(_)?' +
            r'(\[[0-9#b♭.,̣̇\s]+\])?');
    final matches = regex.allMatches(bar);
    return matches.map((m) {
      final symbol = m.group(1);
      final group = m.group(2);
      final chord = m.group(3);
      final isRest = m.group(4) != null;
      final noteRaw = m.group(5);

      final List<String> notes = noteRaw != null
          ? noteRaw.replaceAll(RegExp(r'[\[\]\s]'), '').split(',')
          : [];

      if (symbol != null) return {'symbol': symbol};
      if (isRest && group == null && (chord == null || chord.isEmpty))
        return {'chord': '_', 'note': notes};

      if (group != null) {
        final chords = group
            .split(',')
            .map((c) => transposeShift != 0
                ? transposeChord(c.trim(), transposeShift)
                : c.trim())
            .toList();
        return {'chordGroup': chords, 'note': notes};
      }
      if (chord != null && chord.isNotEmpty) {
        final transposed = transposeShift != 0
            ? transposeChord(chord.trim(), transposeShift)
            : chord.trim();
        return {'chord': isRest ? '_' : transposed, 'note': notes};
      }
      return {};
    }).toList();
  }

  Widget _buildChordBar(BuildContext context, String bar, double width) {
    final beats = _splitChordsWithNotes(bar.trim());

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: beats.map((beat) {
          if (beat.containsKey('symbol')) {
            final symbol = beat['symbol']!;
            return Text(symbol,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: symbolColor[symbol] ?? Colors.orange));
          }
          final noteList = List<String>.from(beat['note'] ?? []);
          if (beat.containsKey('chord') && beat['chord'] == '_') {
            return Column(
              children: [
                const Text("_",
                    style: TextStyle(fontSize: 12, color: Colors.white54)),
                if (noteList.isNotEmpty)
                  Row(
                      children: List.generate(
                          noteList.length,
                          (i) => Row(children: [
                                Text(noteList[i],
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white70)),
                                if (i < noteList.length - 1)
                                  const Text(',',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white70))
                              ]))),
              ],
            );
          }
          if (beat.containsKey('chordGroup')) {
            return Column(
              children: [
                Text('${beat['chordGroup'].join(',')}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
                if (noteList.isNotEmpty)
                  Row(
                      children: List.generate(
                          noteList.length,
                          (i) => Row(children: [
                                Text(noteList[i],
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white70)),
                                if (i < noteList.length - 1)
                                  const Text(',',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white70))
                              ]))),
              ],
            );
          }
          if (beat.containsKey('chord')) {
            final chord = beat['chord']!;
            final root = _extractRoot(chord);
            final suffix = chord.substring(root.length);
            return Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: root,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent)),
                      TextSpan(
                          text: suffix,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.blueAccent)),
                    ],
                  ),
                ),
                if (noteList.isNotEmpty)
                  Row(
                      children: List.generate(
                          noteList.length,
                          (i) => Row(children: [
                                Text(noteList[i],
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white70)),
                                if (i < noteList.length - 1)
                                  const Text(',',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white70))
                              ]))),
              ],
            );
          }
          return const SizedBox();
        }).toList(),
      ),
    );
  }

  String _extractRoot(String chord) {
    final match = RegExp(r'^[A-G][#b]?').firstMatch(chord);
    return match?.group(0) ?? chord;
  }

  List<String> _extractBars(String input) {
    final tokens = <String>[];
    String temp = input
        .replaceAll('|:', ' <<REPSTART>> ')
        .replaceAll(':|', ' <<REPEND>> ')
        .replaceAll('||', ' <<DOUBLEBAR>> ');
    final raw = temp.split('|');

    for (var part in raw) {
      part = part.trim();
      if (part.isEmpty) continue;
      part = part
          .replaceAll('<<REPSTART>>', '|:')
          .replaceAll('<<REPEND>>', ':|')
          .replaceAll('<<DOUBLEBAR>>', '||');
      tokens.add(part);
    }
    return tokens;
  }

  String transposeChord(String chord, int semitoneShift) {
    final chordMap = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final flatMap = {
      'Db': 'C#',
      'D♭': 'C#',
      'Eb': 'D#',
      'E♭': 'D#',
      'Gb': 'F#',
      'G♭': 'F#',
      'Ab': 'G#',
      'A♭': 'G#',
      'Bb': 'A#',
      'B♭': 'A#'
    };

    final match = RegExp(r'^([A-G][b♭#]?)(.*)').firstMatch(chord);
    if (match == null) return chord;
    String root = match.group(1)!;
    String suffix = match.group(2)!;
    root = flatMap[root] ?? root;
    int index = chordMap.indexOf(root);
    if (index == -1) return chord;
    int newIndex = (index + semitoneShift) % 12;
    if (newIndex < 0) newIndex += 12;
    return chordMap[newIndex] + suffix;
  }
}

class ChordSection {
  final String name;
  final List<ChordBlock> blocks;

  ChordSection({required this.name, required this.blocks});
}

class ChordBlock {
  final String? label;
  final List<String> bars;

  ChordBlock({this.label, required this.bars});
}
