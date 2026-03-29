import 'package:flutter/material.dart';
import 'package:flutter_guitar_chord/flutter_guitar_chord.dart';
import 'package:guitar_chord_library/guitar_chord_library.dart';

class ChordsLibrary extends StatefulWidget {
  const ChordsLibrary({super.key});

  @override
  State<ChordsLibrary> createState() => _ChordsLibraryState();
}

class _ChordsLibraryState extends State<ChordsLibrary> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Chord List (Tab pakhat cio ah a langh dingmi chord cazin)
  final Map<String, List<String>> tabChords = {
    'A': ['A', 'Am', 'A7', 'Am7', 'Amaj7', 'Asus4', 'A#', 'A#m', 'A#7', 'A#maj7', 'A#sus4', 'A#sus2'],
    'B': ['B', 'Bm', 'B7', 'Bm7', 'Bmaj7', 'Bsus4'],
    'C': ['C', 'Cm', 'C7', 'Cm7', 'Cmaj7', 'Csus4', 'C#', 'C#m', 'C#7', 'C#maj7', 'C#sus4', 'C#sus2'],
    'D': ['D', 'Dm', 'D7', 'Dm7', 'Dmaj7', 'Dsus4', 'D#', 'D#m', 'D#7', 'D#maj7', 'D#sus4', 'D#sus2'],
    'E': ['E', 'Em', 'E7', 'Em7', 'Emaj7', 'Esus4'],
    'F': ['F', 'Fm', 'F7', 'Fm7', 'Fmaj7', 'Fsus4', 'F#', 'F#m', 'F#7', 'F#maj7', 'F#sus4', 'F#sus2'],
    'G': ['G', 'Gm', 'G7', 'Gm7', 'Gmaj7', 'Gsus4', 'G#', 'G#m', 'G#7', 'G#maj7', 'G#sus4', 'G#sus2'],
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Chords Library',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        bottom: TabBar(
          isScrollable: false,
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: 'A'), Tab(text: 'B'), Tab(text: 'C'),
            Tab(text: 'D'), Tab(text: 'E'), Tab(text: 'F'), Tab(text: 'G'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabChords.keys.map((tabKey) {
          List<String> chordsForThisTab = tabChords[tabKey]!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            itemCount: chordsForThisTab.length,
            itemBuilder: (context, index) {
              return ChordDisplayCard(chordName: chordsForThisTab[index]);
            },
          );
        }).toList(),
      ),
    );
  }
}

// A BIAPI: Dot color thleng khawh nakhnga StatefulWidget ah thlen a si
class ChordDisplayCard extends StatefulWidget {
  final String chordName;
  const ChordDisplayCard({super.key, required this.chordName});

  @override
  State<ChordDisplayCard> createState() => _ChordDisplayCardState();
}

class _ChordDisplayCardState extends State<ChordDisplayCard> {
  int currentIndex = 0; // A THAR: Swipe na tuahmi page theihnak

  List<dynamic> _getChordPositions() {
    String searchKey = widget.chordName.toLowerCase();
    var instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);
    var allKeys = instrument.getKeys(false) ?? [];

    for (var k in allKeys) {
      var chordsInKey = instrument.getChordsByKey(k) ?? [];
      for (var c in chordsInKey) {
        if (_isChordMatch(c.chordKey, c.suffix, searchKey)) {
          return c.chordPositions ?? [];
        }
      }
    }
    return [];
  }

  bool _isChordMatch(String libraryKey, String librarySuffix, String searchedChord) {
    String search = searchedChord.toLowerCase();
    String key = libraryKey.toLowerCase();
    String suffix = librarySuffix.toLowerCase();

    if (key + suffix == search) return true;
    if (suffix == 'major' && (search == key || search == '${key}maj')) return true;
    if (suffix == 'minor' && (search == '${key}m' || search == '${key}min')) return true;
    if ((suffix == 'minor7' || suffix == 'm7') && search == '${key}m7') return true;
    if ((suffix == 'major7' || suffix == 'maj7') && search == '${key}maj7') return true;
    if (suffix == 'dim' && search == '${key}dim') return true;
    if (suffix == 'aug' && search == '${key}aug') return true;
    if (suffix == 'sus4' && search == '${key}sus4') return true;
    if (suffix == 'sus2' && search == '${key}sus2') return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> positions = _getChordPositions();

    if (positions.isEmpty) {
      return const SizedBox(); // Data a um lo ahcun langhter hlah
    }

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 16,),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Chord Min (Title)
            Text(
              widget.chordName, // A THAR: StatefulWidget a si caah 'widget.' chap a hau
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Chord Hmanthlak / Suaimi (PageView in Swipe tuah khawh in)
            SizedBox(
              height: 300,
              width: 250,
              child: PageView.builder(
                itemCount: positions.length,
                onPageChanged: (index) {
                  // A THAR: Na Swipe fatin dot te kha a tlik ve nakhnga State thlen
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  var pos = positions[index];
                  return FlutterGuitarChord(
                    tabBackgroundColor: Colors.blue,
                    fingerSize: 26,
                    differentStringStrokes: true,
                    barColor: Colors.white54,
                    stringStroke: 1,
                    stringColor: Colors.white,
                    barStroke: 3,
                    labelOpenStrings: true,
                    firstFrameColor: Colors.blue,
                    firstFrameStroke: 8,
                    baseFret: pos.baseFret,
                    chordName: '', // A cunglei ah title kan pek cang caah a lawng in chiah
                    frets: pos.frets is List ? pos.frets.join(' ') : pos.frets.toString(),
                    fingers: pos.fingers is List ? pos.fingers.join(' ') : pos.fingers.toString(),
                    totalString: 6,
                    barCount: 4,
                    mutedColor: Colors.red,
                    tabForegroundColor: Colors.white,
                    labelColor: Colors.white,
                  );
                },
              ),
            ),

            // Swipe tuah khawh a si ti theihternak (Dots)
            if (positions.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  positions.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    width: currentIndex == index ? 12.0 : 8.0,
                    height: currentIndex == index ? 12.0 : 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == index
                          ? Colors.redAccent // Na hmeh lio mi dot
                          : Colors.white24, // A dang dot pawl
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


var constantChord = {
  "a": [
    "assets/chords/A.png",
    'assets/chords/A (1).png',
    'assets/chords/A (2).png',
    'assets/chords/A (3).png',
    'assets/chords/A (4).png',
    'assets/chords/A (5).png',
    'assets/chords/A (6).png'
  ],
  "am": [
    "assets/chords/Am.png",
    'assets/chords/Am (1).png',
    'assets/chords/Am (2).png',
  ],
  "a7": [
    "assets/chords/A7.png",
    'assets/chords/A7 (1).png',
    'assets/chords/A7 (2).png',
    'assets/chords/A7 (3).png',
  ],
  "am7": [
    "assets/chords/Am7.png",
    'assets/chords/Am7 (1).png',
    'assets/chords/Am7 (2).png',
  ],
  "amaj7": [
    "assets/chords/Amaj7.png",
    'assets/chords/Amaj7 (1).png',
    'assets/chords/Amaj7 (2).png',
    'assets/chords/Amaj7 (3).png',
    'assets/chords/Amaj7 (4).png',
    'assets/chords/Amaj7 (5).png',
  ],
  "asus4": [
    "assets/chords/Asus4.png",
    'assets/chords/Asus4 (1).png',
    'assets/chords/Asus4 (2).png',
  ],

  "a#": [
    "assets/chords/A#.png"
  ],
  "a#m": [
    "assets/chords/A#m.png"
  ],
  "a#7": [
    "assets/chords/A#7.png"
  ],

  "a#maj7": [
    "assets/chords/A#maj7.png"
  ],
  "a#sus4": [
    "assets/chords/A#sus4.png"
  ],
  "a#sus2": [
    "assets/chords/A#sus2.png"
  ],

  //b

  "b": [
    'assets/chords/B.png',
    'assets/chords/B (1).png',
    'assets/chords/B (2).png',
    'assets/chords/B (3).png',
    'assets/chords/B (4).png',
    'assets/chords/B (5).png',
    'assets/chords/B (6).png',
  ],
  "bm": [
    "assets/chords/Bm.png",
    'assets/chords/Bm (1).png',
    'assets/chords/Bm (2).png',
  ],
  "b7": [
    "assets/chords/B7.png",
    'assets/chords/B7 (1).png',
    'assets/chords/B7 (2).png',
    'assets/chords/B7 (3).png',
  ],
  "bm7": [
    "assets/chords/Bm7.png",
    'assets/chords/Bm7 (1).png',
    'assets/chords/Bm7 (2).png',
  ],
  "bmaj7": [
    "assets/chords/Bmaj7.png",
    'assets/chords/Bmaj7 (1).png',
    'assets/chords/Bmaj7 (2).png',
    'assets/chords/Bmaj7 (3).png',
    'assets/chords/Bmaj7 (4).png',
    'assets/chords/Bmaj7 (5).png',
  ],
  "bsus4": [
    "assets/chords/Bsus4.png",
    'assets/chords/Bsus4 (1).png',
    'assets/chords/Bsus4 (2).png',
  ],

  //c

  "c#": [
    'assets/chords/C#.png'
  ],
  "c#m": [
    "assets/chords/C#m.png"
  ],
  "c#7": [
    "assets/chords/C#7.png"
  ],

  "c#maj7": [
    "assets/chords/C#maj7.png"
  ],
  "c#sus4": [
    "assets/chords/C#sus4.png"
  ],
  "c#sus2": [
    "assets/chords/C#sus4.png"
  ],

  "c": [
    'assets/chords/c.png',
    'assets/chords/c (1).png',
    'assets/chords/c (2).png',
    'assets/chords/c (3).png',
    'assets/chords/c (4).png',
    'assets/chords/c (5).png',
    'assets/chords/c (6).png',
  ],
  "cm": [
    "assets/chords/Cm.png",
    'assets/chords/Cm (1).png',
    'assets/chords/Cm (2).png',
  ],
  "c7": [
    "assets/chords/C7.png",
    'assets/chords/C7 (1).png',
    'assets/chords/C7 (2).png',
    'assets/chords/C7 (3).png',
  ],
  "cm7": [
    "assets/chords/Cm7.png",
    'assets/chords/Cm7 (1).png',
    'assets/chords/Cm7 (2).png',
  ],
  "cmaj7": [
    "assets/chords/Cmaj7.png",
    'assets/chords/Cmaj7 (1).png',
    'assets/chords/Cmaj7 (2).png',
    'assets/chords/Cmaj7 (3).png',
    'assets/chords/Cmaj7 (4).png',
    'assets/chords/Cmaj7 (5).png',
  ],
  "csus4": [
    "assets/chords/Csus4.png",
    'assets/chords/Csus4 (1).png',
    'assets/chords/Csus4 (2).png',
  ],

  //d

  "d": [
    'assets/chords/D.png',
    'assets/chords/D (1).png',
    'assets/chords/D (2).png',
    'assets/chords/D (3).png',
    'assets/chords/D (4).png',
    'assets/chords/D (5).png',
    'assets/chords/D (6).png',
  ],
  "dm": [
    "assets/chords/Dm.png",
    'assets/chords/Dm (1).png',
    'assets/chords/Dm (2).png',
  ],
  "d7": [
    "assets/chords/D7.png",
    'assets/chords/D7 (1).png',
    'assets/chords/D7 (2).png',
    'assets/chords/D7 (3).png',
  ],
  "dm7": [
    "assets/chords/Dm7.png",
    'assets/chords/Dm7 (1).png',
    'assets/chords/Dm7 (2).png',
  ],
  "dmaj7": [
    "assets/chords/Dmaj7.png",
    'assets/chords/Dmaj7 (1).png',
    'assets/chords/Dmaj7 (2).png',
    'assets/chords/Dmaj7 (3).png',
    'assets/chords/Dmaj7 (4).png',
    'assets/chords/Dmaj7 (5).png',
  ],
  "dsus4": [
    "assets/chords/Dsus4.png",
    'assets/chords/Dsus4 (1).png',
    'assets/chords/Dsus4 (2).png',
  ],

  "d#": [
    'assets/chords/D#.png'
  ],
  "d#m": [
    "assets/chords/D#m.png"
  ],
  "d#7": [
    "assets/chords/D#7.png" ],

  "d#maj7": [
    "assets/chords/D#maj7.png",
    'assets/chords/Dmaj7 (1).png',
    'assets/chords/Dmaj7 (2).png',
    'assets/chords/Dmaj7 (3).png',
    'assets/chords/Dmaj7 (4).png',
    'assets/chords/Dmaj7 (5).png',
  ],
  "d#sus4": [
    "assets/chords/D#sus4.png",
    'assets/chords/Dsus4 (1).png',
    'assets/chords/Dsus4 (2).png',
  ],
  "d#sus2": [
    "assets/chords/D#sus2.png",
    'assets/chords/Dsus4 (1).png',
    'assets/chords/Dsus4 (2).png',
  ],

  "e": [
    "assets/chords/E.png",
    'assets/chords/E (1).png',
    'assets/chords/E (2).png',
    'assets/chords/E (3).png',
    'assets/chords/E (4).png',
    'assets/chords/E (5).png',
    'assets/chords/E (6).png'
  ],
  "em": [
    "assets/chords/Em.png",
    'assets/chords/Em (1).png',
    'assets/chords/Em (2).png',
  ],
  "e7": [
    "assets/chords/E7.png",
    'assets/chords/E7 (1).png',
    'assets/chords/E7 (2).png',
    'assets/chords/E7 (3).png',
  ],
  "em7": [
    "assets/chords/Em7.png",
    'assets/chords/Em7 (1).png',
    'assets/chords/Em7 (2).png',
  ],
  "emaj7": [
    "assets/chords/Emaj7.png",
    'assets/chords/Emaj7 (1).png',
    'assets/chords/Emaj7 (2).png',
    'assets/chords/Emaj7 (3).png',
    'assets/chords/Emaj7 (4).png',
    'assets/chords/Emaj7 (5).png',
  ],
  "esus4": [
    "assets/chords/Esus4.png",
    'assets/chords/Esus4 (1).png',
    'assets/chords/Esus4 (2).png',
  ],

  //f

  "f": [
    'assets/chords/F.png',
    'assets/chords/F (1).png',
    'assets/chords/F (2).png',
    'assets/chords/F (3).png',
    'assets/chords/F (4).png',
    'assets/chords/F (5).png',
    'assets/chords/F (6).png',
  ],
  "fm": [
    "assets/chords/Fm.png",
    'assets/chords/Fm (1).png',
    'assets/chords/Fm (2).png',
  ],
  "f7": [
    "assets/chords/F7.png",
    'assets/chords/F7 (1).png',
    'assets/chords/F7 (2).png',
    'assets/chords/F7 (3).png',
  ],
  "fm7": [
    "assets/chords/Fm7.png",
    'assets/chords/Fm7 (1).png',
    'assets/chords/Fm7 (2).png',
  ],
  "fmaj7": [
    "assets/chords/Fmaj7.png",
    'assets/chords/Fmaj7 (1).png',
    'assets/chords/Fmaj7 (2).png',
    'assets/chords/Fmaj7 (3).png',
    'assets/chords/Fmaj7 (4).png',
    'assets/chords/Fmaj7 (5).png',
  ],
  "fsus4": [
    "assets/chords/Fsus4.png",
    'assets/chords/Fsus4 (1).png',
    'assets/chords/Fsus4 (2).png',
  ],

  "f#": [
    'assets/chords/F#.png'
  ],
  "f#m": [
    "assets/chords/F#m.png"
  ],
  "f#7": [
    "assets/chords/F#7.png"
  ],

  "f#maj7": [
    "assets/chords/F#maj7.png"
  ],
  "f#sus4": [
    "assets/chords/F#sus4.png"
  ],
  "f#sus2": [
    "assets/chords/F#sus2.png"
  ],

  //g

  "g": [
    'assets/chords/G.png',
    'assets/chords/G (1).png',
    'assets/chords/G (2).png',
    'assets/chords/G (3).png',
    'assets/chords/G (4).png',
    'assets/chords/G (5).png',
    'assets/chords/G (6).png',
  ],
  "gm": [
    "assets/chords/Gm.png",
    'assets/chords/Gm (1).png',
    'assets/chords/Gm (2).png',
  ],
  "g7": [
    "assets/chords/G7.png",
    'assets/chords/G7 (1).png',
    'assets/chords/G7 (2).png',
    'assets/chords/G7 (3).png',
  ],
  "gm7": [
    "assets/chords/Gm7.png",
    'assets/chords/Gm7 (1).png',
    'assets/chords/Gm7 (2).png',
  ],
  "gmaj7": [
    "assets/chords/Gmaj7.png",
    'assets/chords/Gmaj7 (1).png',
    'assets/chords/Gmaj7 (2).png',
    'assets/chords/Gmaj7 (3).png',
    'assets/chords/Gmaj7 (4).png',
    'assets/chords/Gmaj7 (5).png',
  ],
  "gsus4": [
    "assets/chords/Gsus4.png",
    'assets/chords/Gsus4 (1).png',
    'assets/chords/Gsus4 (2).png',
  ],

  "g#": [
    'assets/chords/G#.png'
  ],
  "g#m": [
    "assets/chords/G#m.png"
  ],
  "g#7": [
    "assets/chords/G#7.png"
  ],

  "g#maj7": [
    "assets/chords/G#maj7.png"
  ],
  "g#sus4": [
    "assets/chords/G#sus4.png"
  ], "g#sus2": [
    "assets/chords/G#sus2.png"
  ]
};
