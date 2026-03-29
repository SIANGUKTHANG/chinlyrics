import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chord_mod/flutter_chord.dart';
import 'package:flutter_guitar_chord/flutter_guitar_chord.dart';
import 'package:guitar_chord_library/guitar_chord_library.dart';

class Chords extends StatelessWidget {
    Chords(
      {Key? key,
      this.fontSize,
      this.vpadding,
      this.cpadding,
      this.verse,
      this.chorus,
      this.ending,
      this.scrollSpeed,
      this.showChord})
      : super(key: key);

  final chordStyle =   TextStyle(color: Colors.green,fontWeight: FontWeight.bold,
  decoration: TextDecoration.underline,);
  final int? vpadding;
  final int? cpadding;
  final String? verse;
  final int? scrollSpeed;
  final String? chorus;
  final String? ending;
  final bool? showChord;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    // Flutter thar ah textScaleFactor hman ning a dikmi
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double finalFontSize = (fontSize ?? 14) * textScale;
    int currentIndex = 0;
    return Column(
      children: [
        // Verse
        if (verse != null && verse!.isNotEmpty)
         showChord!? Builder(builder: (context) {
            return LyricsRenderer(
              showChord: showChord ?? false,
              lyrics: verse ?? '',
              textStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white70,

                fontSize: finalFontSize,
              ),
              chordStyle: chordStyle,
              widgetPadding: vpadding ?? 0,
              lineHeight: 1.1,

              onTapChord: (String chord) => handleChordTap(context, chord),
              transposeIncrement: scrollSpeed ?? 0,
            );
          }):Text(verse!.replaceAll(RegExp(r'\[(.*?)\]'), ''),style: TextStyle(
           fontWeight: FontWeight.w600,
           color: Colors.white70,

           fontSize: finalFontSize,
         ),),


        // Chorus
        if (chorus != null && chorus!.isNotEmpty)
          showChord!? Builder(builder: (context) {
            return Container(
              margin: const EdgeInsets.only(left: 20),
              child:  LyricsRenderer(
                chorusStyle: TextStyle(fontWeight: FontWeight.w600),
                lyrics: chorus ?? '',
                textStyle: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: finalFontSize,
                  fontStyle: FontStyle.normal,
                ),
                chordStyle: chordStyle,
                lineHeight: 0,
                showChord: showChord ?? false,
                widgetPadding: cpadding ?? 0,
                onTapChord: (String chord) => handleChordTap(context, chord),
                transposeIncrement: scrollSpeed ?? 0,
              ),
            );
          }):Padding(
            padding: const EdgeInsets.only(top: 10,left: 30.0,bottom: 10),
            child: Text(chorus!.replaceAll(RegExp(r'\[(.*?)\]'), ''),style:TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: finalFontSize,
              fontStyle: FontStyle.normal,
            ) ,),
          ),

      ],
    );
  }


}

// A BIAPI BIK: Chord hmeh tikah Package hmang in a suainak
void handleChordTap(BuildContext context, String tappedChord) {
  String searchKey = normalizeChord(tappedChord);

  // 1. Guitar Chord Library in data kawlnak
  var instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);
  var allKeys = instrument.getKeys(false) ?? [];

  List<dynamic> foundPositions = [];
  String? foundChordName;

  try {
    for (var k in allKeys) {
      var chordsInKey = instrument.getChordsByKey(k) ?? [];

      for (var c in chordsInKey) {
        if (_isChordMatch(c.chordKey, c.suffix, searchKey)) {
          foundPositions = c.chordPositions ?? [];
          foundChordName = tappedChord;
          break;
        }
      }
      if (foundPositions.isNotEmpty) break;
    }
  } catch (e) {
    if (kDebugMode) print("Chord kawl lio ah palhnak: $e");
  }

  if (foundPositions.isEmpty) {
    if (kDebugMode) print("Chord not found in library: $searchKey");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sorry!", style: TextStyle(color: Colors.white)),
        content: Text("'$tappedChord' chord hi hmuh a si lo.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.green)),
          )
        ],
      ),
    );
    return;
  }

  // 2. Dialog chungah FlutterGuitarChord hmang in a suainak (StatefulBuilder He)
  int currentIndex = 0; // A THAR: Dialog thawkka ah dot number theihnak

  showDialog(
    context: context,
    builder: (context) {
      // A BIAPI BIK: Dialog chunglawng ah a color thleng tu ding StatefulBuilder
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(12),
              height: 400,
              width: 200,
              child: Column(
                children: [
                  Text(
                    foundChordName ?? tappedChord,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),

                  Expanded(
                    child: PageView.builder(
                      itemCount: foundPositions.length,
                      // Swipe na tuah fatin dot thleng nakhnga
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        var pos = foundPositions[index];
                        return Center(
                          child: FlutterGuitarChord(
                            tabBackgroundColor: Colors.blue,
                            fingerSize: 30,
                            differentStringStrokes: true,
                            barColor: Colors.white54,
                            stringStroke: 1,
                            stringColor: Colors.white,
                            barStroke: 3,
                            labelOpenStrings: true,
                            firstFrameColor: Colors.green,
                            firstFrameStroke: 8,
                            baseFret: pos.baseFret,
                            chordName: '',
                            frets: pos.frets is List
                                ? pos.frets.join(' ')
                                : pos.frets.toString(),
                            fingers: pos.fingers is List
                                ? pos.fingers.join(' ')
                                : pos.fingers.toString(),
                            totalString: 6,
                            barCount: 4,
                            mutedColor: Colors.red,
                            tabForegroundColor: Colors.white,
                            labelColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // A THAR: Indicator Dots tuahnak
                  if (foundPositions.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        foundPositions.length,
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

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// CHORD MIN (NAME) CHECK TUAHTU FUNCTION THAR (Hihi class tang bikah chap)
bool _isChordMatch(
    String libraryKey, String librarySuffix, String searchedChord)
{
  String search = searchedChord.toLowerCase();
  String key = libraryKey.toLowerCase();
  String suffix = librarySuffix.toLowerCase();

  // 1. Exact match (Tahchunhnak: C7 == C7)
  if (key + suffix == search) return true;

  // 2. Major chord (Search: "C", Library: "C" + "major")
  if (suffix == 'major' && (search == key || search == '${key}maj'))
    return true;

  // 3. Minor chord (Search: "Cm", Library: "C" + "minor")
  if (suffix == 'minor' && (search == '${key}m' || search == '${key}min'))
    return true;

  // 4. Minor 7 chord (Search: "Cm7", Library: "C" + "minor7")
  if ((suffix == 'minor7' || suffix == 'm7') && search == '${key}m7')
    return true;

  // 5. Major 7 chord (Search: "Cmaj7", Library: "C" + "major7")
  if ((suffix == 'major7' || suffix == 'maj7') && search == '${key}maj7')
    return true;

  // 6. Diminished (Search: "Cdim", Library: "C" + "dim")
  if (suffix == 'dim' && search == '${key}dim') return true;

  // 7. Augmented (Search: "Caug", Library: "C" + "aug")
  if (suffix == 'aug' && search == '${key}aug') return true;

  return false;
}

String normalizeChord(String chord) {
  String lower = chord.toLowerCase();
  Map<String, String> flatMap = {
    "ab": "g#",
    "bb": "a#",
    "db": "c#",
    "eb": "d#",
    "gb": "f#",
  };

  if (lower.length >= 2 && flatMap.containsKey(lower.substring(0, 2))) {
    return flatMap[lower.substring(0, 2)]! + lower.substring(2);
  }
  return lower;
}