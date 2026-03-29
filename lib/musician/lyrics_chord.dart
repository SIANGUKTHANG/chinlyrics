import 'package:flutter/material.dart';

import '../pages/chord.dart';

Widget buildLyricSection(
    BuildContext context,
    String text,
    bool showChord, {
      double verticalPadding = 0.0,
      double leftPadding = 0.0, // <-- PARAMETER THAR KAN CHAP
      List<FontFeature>? fontFeatures,
      FontWeight fontWeight = FontWeight.normal,
      FontStyle fontStyle = FontStyle.normal,
      Color textColor = Colors.white70,
      double fontSize = 16.0,
    }) {

  // 1. CHORD PHIH A SI AHCUN (Lyrics lawng)
  if (!showChord) {
    String cleanLyrics = text.replaceAll(RegExp(r'\[.*?\]'), '');

    return Padding(
      // symmetric(vertical) in only(top, bottom, left) ah kan thleng
      padding: EdgeInsets.only(
        top: verticalPadding > 0.0 ? verticalPadding : 8.0,
        bottom: verticalPadding > 0.0 ? verticalPadding : 8.0,
        left: leftPadding, // <-- Left padding a hmang lai
      ),
      child: Text(
        cleanLyrics,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          height: 1.5,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          fontFeatures: fontFeatures,
        ),
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
      chordsList.add(splitPart[0]);
      lyricsList.add(splitPart.length > 1 ? splitPart[1] : "");
    } else {
      chordsList.add("");
      lyricsList.add(part);
    }
  }

  Widget wrapContent = Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: List.generate(chordsList.length, (index) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- CHORD ---
          if (chordsList[index].isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                handleChordTap(context, chordsList[index]);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0, bottom: 2.0),
                child: Text(
                  chordsList[index],
                  style:   TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    fontSize: fontSize-2,
                  ),
                ),
              ),
            ),

          // --- LYRICS ---
          Text(
            lyricsList[index],
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              height: 1.2,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              fontFeatures: fontFeatures,
            ),
          ),
        ],
      );
    }),
  );

  // Padding a um ahcun a pek lai
  if (verticalPadding > 0.0 || leftPadding > 0.0) {
    return Padding(
      padding: EdgeInsets.only(
        top: verticalPadding,
        bottom: verticalPadding,
        left: leftPadding, // <-- Left padding a hmang lai
      ),
      child: wrapContent,
    );
  }

  return wrapContent;
}