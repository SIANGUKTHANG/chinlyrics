import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chord_mod/flutter_chord.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banner_carousel/banner_carousel.dart';

import 'chords.dart';

class Chords extends StatelessWidget {
   const Chords(
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
   final chordStyle = const TextStyle(
    color: Colors.green,
  );
  // Typed fields for better safety and analyzer compliance
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
    return Column(
      children: [
        //verse 1
        (verse == null || verse == '')
            ? Container()
            : Builder(builder: (context) {
          return LyricsRenderer(
            showChord: showChord ?? false,
            lyrics: verse ?? '',
            textStyle: GoogleFonts.alike(
                color: Colors.white70,
                fontSize:
                (fontSize ?? 14) * MediaQuery.of(context).textScaleFactor),
            chordStyle: chordStyle,
            widgetPadding: vpadding ?? 0,
            lineHeight: 0,
            onTapChord: (String chord) {

              // Convert flats (Bb, Eb, Abmaj7) → sharps (A#, D#, G#maj7)
              String key = normalizeChord(chord);

              if (!constantChord.containsKey(key)) {
                print("Chord not found: $key");
                return;
              }

              List<String> images = constantChord[key]!;

              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      height: 450,
                      width: 300,
                      child: Column(
                        children: [
                          Text(
                            chord,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),

                          const SizedBox(height: 10),

                          Expanded(
                            child: BannerCarousel(
                              height: 350,
                              activeColor: Colors.red,
                              disableColor: Colors.white54,
                              animation: true,
                              customizedBanners: images
                                  .map((imgPath) => Image.asset(imgPath, fit: BoxFit.contain))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            transposeIncrement: scrollSpeed ?? 0,
          );
        }),
        const SizedBox(height: 10,),
        //verse 1 chorus
        (verse == null || verse == '')
            ? Container()
            : (chorus == null || chorus == '')
            ? Container()
            : Builder(builder: (context) {
          return Container(
            margin: const EdgeInsets.only(left: 40),
            child: LyricsRenderer(
              lyrics: chorus ?? '',
              textStyle: GoogleFonts.acme(
                color: Colors.white70,
                fontSize:
                (fontSize ?? 14) * MediaQuery.of(context).textScaleFactor,
                fontStyle: FontStyle.normal,
              ),
              chordStyle: chordStyle,
              lineHeight: 0,
              showChord: showChord ?? false,
              widgetPadding: cpadding ?? 0,
              onTapChord: (String chord) {

                // Convert flats (Bb, Eb, Abmaj7) → sharps (A#, D#, G#maj7)
                String key = normalizeChord(chord);

                if (!constantChord.containsKey(key)) {
                  if (kDebugMode) {
                    print("Chord not found: $key");
                  }
                  return;
                }

                List<String> images = constantChord[key]!;

                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        height: 450,
                        width: 300,
                        child: Column(
                          children: [
                            Text(
                              chord,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),

                            const SizedBox(height: 10),

                            Expanded(
                              child: BannerCarousel(
                                height: 350,
                                activeColor: Colors.red,
                                disableColor: Colors.white54,
                                animation: true,
                                customizedBanners: images
                                    .map((imgPath) => Image.asset(imgPath, fit: BoxFit.contain))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              transposeIncrement: scrollSpeed ?? 0,
            ),
          );
        }),
        const SizedBox(height: 10,),
      ],
    );
  }

   String normalizeChord(String chord) {
     String lower = chord.toLowerCase();

     // Map flats to sharps
     Map<String, String> flatMap = {
       "ab": "g#",
       "bb": "a#",
       "db": "c#",
       "eb": "d#",
       "gb": "f#",
     };

     // Check if the first two characters are flat chords
     if (lower.length >= 2 && flatMap.containsKey(lower.substring(0, 2))) {
       String rootSharp = flatMap[lower.substring(0, 2)]!;
       return rootSharp + lower.substring(2); // keep suffix (m, 7, maj7, sus4...)
     }

     return lower; // already sharp or natural
   }

}
