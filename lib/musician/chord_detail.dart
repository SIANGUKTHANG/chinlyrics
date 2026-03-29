import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'add_chord.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ChordDetailPage extends StatefulWidget {
  final String songId;
  final String title;

  const ChordDetailPage({
    super.key,
    required this.songId,
    required this.title,
  });

  @override
  State<ChordDetailPage> createState() => _ChordDetailPageState();
}

class _ChordDetailPageState extends State<ChordDetailPage> {
  int transposeShift = 0;
  late ScrollController _scrollController;
  bool _isScrolling = false;
  double speedScroll = 10;
  double fontSize = 0;
  final List<double> speedOptions = [1, 3, 6, 10, 14, 17, 20];
  late BannerAd banner;
  bool isAdsLoading = false;
  bool isLoading = true;
  bool isGeneratingPdf = false;

  String singer = '';
  String chords = '';
  String key = '';
  String status = '';
  String type = '';
  String email = '';
  String ytLink = '';

  Future<void> fetchSongDetails() async {
    try {
      // FirebaseFirestore hmai ah 'firestore.' kan chap lai
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('musicianChords')
          .doc(widget.songId)
          .get(const GetOptions(
              source: Source
                  .serverAndCache)); // Source hmai zongah firestore. a herh

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          singer = data['singer'] ?? '';
          chords = data['chords'] ?? '';
          key = data['key'] ?? '';
          status = data['status'] ?? '';
          type = data['type'] ?? '';
          email = data['uploaderEmail'] ?? '';
          ytLink = data['ytLink'] ?? '';
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Hla lak lio ah palhnak: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSongDetails();
    _scrollController = ScrollController();
    /* banner = BannerAd(
      adUnitId: AdHelper.detailBannerAdUnitId,
      size: AdSize.fullBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isAdsLoading = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          isAdsLoading = false;
          ad.dispose();
        },
      ),
    )..load();*/
  }

  @override
  void dispose() {
    _scrollController.dispose();
    banner.dispose();
    super.dispose();
  }

  void _toggleAutoScroll() {
    if (_isScrolling) {
      _scrollController.jumpTo(_scrollController.offset);
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
      }
    } else {
      if (!_scrollController.hasClients) return;
      if (mounted) {
        setState(() {
          _isScrolling = true;
        });
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController
          .animateTo(
        maxScroll,
        duration: Duration(seconds: (maxScroll / speedScroll).round()),
        curve: Curves.linear,
      )
          .whenComplete(() {
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    }
  }


// ==========================================
  // A THAR: PDF Tuahnak (Myanmar Font Support he)
  // ==========================================
  Future<void> _shareAsPdf() async {
    setState(() => isGeneratingPdf = true);

    try {
      final pdf = pw.Document();
      final sections = parseStructuredChords(chords);

      const double fixedBarWidth = 132.0;
      const double spacing = 4.0;

      // --- 1. FONT KHA KAN LOAD LAI ---
      // Na pubspec.yaml i na min pek mi he aa khat hrimhrim a hau mu
      final ByteData fontData = await rootBundle.load('assets/fonts/NotoSansMyanmar-Regular.ttf');
      final pw.Font myanmarFont = pw.Font.ttf(fontData);

      final ByteData boldFontData = await rootBundle.load('assets/fonts/NotoSansMyanmar-Bold.ttf');
      final pw.Font myanmarFontBold = pw.Font.ttf(boldFontData);

      pdf.addPage(
          pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(24),

              // --- 2. THEME AH FONT KAN PEK LAI ---
              // Hi nih hin a PDF page dihlak caah Myanmar font a hmanter cang lai
              theme: pw.ThemeData.withFont(
                base: myanmarFont,
                bold: myanmarFontBold,
              ),

              build: (pw.Context context) {
                return [
                  // 1. HEADER
                  pw.Header(
                      level: 0,
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(widget.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 6),
                            pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text("Singer: $singer", style: const pw.TextStyle(fontSize: 11)),
                                  pw.Text("Key: $key", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                                ]
                            ),
                            pw.SizedBox(height: 8),
                          ]
                      )
                  ),
                  pw.SizedBox(height: 12),

                  // 2. CHORD SECTIONS
                  ...sections.map((section) {
                    return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(section.name.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                          ),
                          pw.SizedBox(height: 6),
                          ...section.blocks.map((block) {
                            return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  if (block.label != null)
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                                      child: pw.Text('> ${block.label!}', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.blue800)),
                                    ),

                                  // Bars Grid
                                  pw.Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: block.bars.map((bar) {
                                      final beats = _splitChordsWithNotes(bar.trim(), transposeShift);

                                      return pw.Container(
                                          width: fixedBarWidth,
                                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          decoration: pw.BoxDecoration(
                                            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                          ),
                                          child: pw.Row(
                                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                            children: beats.map((beat) {
                                              String textToShow = "";
                                              PdfColor color = PdfColors.black;

                                              if (beat.containsKey('symbol')) {
                                                textToShow = beat['symbol']!;
                                                color = PdfColors.red;
                                              } else if (beat.containsKey('chord') && beat['chord'] == '_') {
                                                textToShow = "_";
                                              } else if (beat.containsKey('chordGroup')) {
                                                textToShow = beat['chordGroup']!.join(',');
                                                color = PdfColors.blue;
                                              } else if (beat.containsKey('chord')) {
                                                textToShow = beat['chord']!;
                                              }

                                              return pw.Text(
                                                  textToShow,
                                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)
                                              );
                                            }).toList(),
                                          )
                                      );
                                    }).toList(),
                                  ),
                                  pw.SizedBox(height: 6),
                                ]
                            );
                          }).toList()
                        ]
                    );
                  }).toList()
                ];
              }
          )
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/${widget.title}_Chord.pdf");
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Chord for ${widget.title}');

    } catch (e) {
      debugPrint("PDF Share Error: $e");
    } finally {
      setState(() => isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = parseStructuredChords(chords);
    return Scaffold(
      appBar: _isScrolling
          ? null
          : AppBar(
              // Thianghlim tein
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              centerTitle: true,
              actions: [
                // A THAR: Share Button
                isGeneratingPdf
                    ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                )
                    : IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: chords.isEmpty ? null : _shareAsPdf,
                  tooltip: 'Share as PDF',
                ),
              ],
            ),

      // Floating Action Buttons (Auto Scroll le YouTube Player)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'scroll_btn',
            backgroundColor:
                _isScrolling ? Colors.transparent : Colors.transparent,
            onPressed: _toggleAutoScroll,
            child: Icon(
              _isScrolling ? Icons.stop : Icons.unfold_more,
              color: _isScrolling ? Colors.red : Colors.white,
            ),
          ),
        ],
      ),
      bottomSheet: isAdsLoading
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: AdSize.banner.height.toDouble(),
              width: MediaQuery.of(context).size.width,
              child: AdWidget(ad: banner),
            )
          : const SizedBox(height: 1),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: GestureDetector(
          onLongPress: () => settings(context),
          onDoubleTap: () => _toggleAutoScroll(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _isScrolling
                    ? const SizedBox(height: 100)
                    : const SizedBox(height: 20),

                // Singer le Key langhternak Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mic,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            singer,
                            style: TextStyle(
                                fontSize: 14 + fontSize,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'Key: $key',
                          style: TextStyle(
                              fontSize: 14 + fontSize,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chords Sections
                ...sections.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          section.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12 + fontSize,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...section.blocks.map((block) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (block.label != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  '> ${block.label!} ',
                                  style: TextStyle(
                                    fontSize: 11 + fontSize,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final barsPerRow =
                                    _calculateBarsPerRow(constraints.maxWidth);
                                final barWidth = (constraints.maxWidth -
                                        (barsPerRow - 1) * 8) /
                                    barsPerRow;

                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: block.bars
                                      .map((bar) => Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 2.0),
                                            child: _buildChordBar(
                                                context, bar, barWidth),
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  int _calculateBarsPerRow(double width) {
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 800) return 4;
    return 5;
  }

  Widget _buildChordBar(BuildContext context, String bar, double width) {
    final beats = _splitChordsWithNotes(bar.trim(), transposeShift);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06), // Glassmorphism style
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: beats.map((beat) {
          if (beat.containsKey('symbol')) {
            final symbol = beat['symbol']!;
            return Text(
              symbol,
              style: TextStyle(
                  fontSize: 12 + fontSize,
                  fontWeight: FontWeight.bold,
                  color: symbolColor[symbol] ?? Colors.orange),
            );
          }

          final noteList = List<String>.from(beat['note'] ?? []);

          if (beat.containsKey('chord') && beat['chord'] == '_') {
            return Column(
              children: [
                Text("_",
                    style: TextStyle(
                        fontSize: 12 + fontSize, color: Colors.white54)),
                if (noteList.isNotEmpty)
                  Row(
                      children: List.generate(noteList.length, (i) {
                    return Row(children: [
                      Text(noteList[i],
                          style: TextStyle(
                              fontSize: 8 + fontSize,
                              color: Colors.greenAccent)),
                      if (i < noteList.length - 1)
                        Text(',',
                            style: TextStyle(
                                fontSize: 8 + fontSize, color: Colors.white54)),
                    ]);
                  }))
              ],
            );
          }

          if (beat.containsKey('chordGroup')) {
            return Column(
              children: [
                Text('${beat['chordGroup'].join(',')}',
                    style: TextStyle(
                        fontSize: 12 + fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
                if (noteList.isNotEmpty)
                  Row(
                      children: List.generate(noteList.length, (i) {
                    return Row(children: [
                      Text(noteList[i],
                          style: TextStyle(
                              fontSize: 8 + fontSize,
                              color: Colors.greenAccent)),
                      if (i < noteList.length - 1)
                        Text(',',
                            style: TextStyle(
                                fontSize: 8 + fontSize, color: Colors.white54)),
                    ]);
                  }))
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
                          style: TextStyle(
                              fontSize: 14 + fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(
                          text: suffix,
                          style: TextStyle(
                              fontSize: 12 + fontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent)),
                    ],
                  ),
                ),
                if (noteList.isNotEmpty)
                  Row(
                      children: List.generate(noteList.length, (i) {
                    return Row(children: [
                      Text(noteList[i],
                          style: TextStyle(
                              fontSize: 8 + fontSize,
                              color: Colors.greenAccent)),
                      if (i < noteList.length - 1)
                        Text(',',
                            style: TextStyle(
                                fontSize: 8 + fontSize, color: Colors.white54)),
                    ]);
                  }))
              ],
            );
          }

          return const SizedBox();
        }).toList(),
      ),
    );
  }

  // --- LOGIC FUNCTIONS (Unchanged, just cleaner formatting) ---

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
        if (currentSection != null)
          sections
              .add(ChordSection(name: currentSection, blocks: currentBlocks));
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
    if (currentSection != null)
      sections.add(ChordSection(name: currentSection, blocks: currentBlocks));
    return sections;
  }

  List<Map> _splitChordsWithNotes(String bar, [int transposeShift = 0]) {
    final regex = RegExp(
        r'(\|\:|\:\||\|\||\||D\.C\.|D\.S\.|Fine|Coda|Segno|To Coda|~|>)' +
            r'|' +
            r'(?:\{([^\}]+)\})?' +
            r'([A-G][#b♭]?(?:\/[A-G][#b♭]?)?[a-zA-Z0-9#b♭]*)?' +
            r'(_)?' +
            r'(\[[0-9#b.,̣̇\s]+\])?');

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

  String _extractRoot(String chord) {
    final match = RegExp(r'^[A-G][#b]?').firstMatch(chord);
    return match?.group(0) ?? chord;
  }

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

  // --- SETTINGS DIALOG (Dark Mode UI) ---
  void settings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              // Dark Dialog background
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Settings',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scroll speed',
                          style:
                              TextStyle(fontSize: 14, color: Colors.white70)),
                      Text('${speedScroll.toInt()}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.blueAccent,
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16.0),
                    ),
                    child: Slider(
                      value: speedScroll,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (value) =>
                          setDialogState(() => speedScroll = value),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size',
                          style:
                              TextStyle(fontSize: 14, color: Colors.white70)),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.white54),
                              onPressed: () {
                                if (fontSize > -2) setState(() => fontSize--);
                                setDialogState(() {});
                              }),
                          Text('${fontSize > 0 ? '+' : ''}${fontSize.toInt()}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.white54),
                              onPressed: () {
                                if (fontSize < 8) setState(() => fontSize++);
                                setDialogState(() {});
                              }),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transpose',
                          style:
                              TextStyle(fontSize: 14, color: Colors.white70)),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.white54),
                              onPressed: () {
                                setState(() => transposeShift--);
                                setDialogState(() {});
                              }),
                          Text(
                              '${transposeShift > 0 ? '+' : ''}$transposeShift',
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.white54),
                              onPressed: () {
                                setState(() => transposeShift++);
                                setDialogState(() {});
                              }),
                        ],
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    if (mounted) setState(() {});
                    Navigator.of(context).pop();
                  },
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
