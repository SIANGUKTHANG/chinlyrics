/*
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../constant.dart';

class ChordDetailPage extends StatefulWidget {
  final ChordModel song;

  const ChordDetailPage({super.key, required this.song,

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
  late YoutubePlayerController _controller;
  bool _showFloatingPlayer = false;
  Offset _floatingOffset =
  const Offset(20, 20); // Initial position of floating player
  double _floatingWidth = 300; // Initial width of the floating player
  double _floatingHeight = 120;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
  void _showPlayer() {
    setState(() {
      _showFloatingPlayer = true;
    });
  }

  void _closePlayer() {
    setState(() {
      _showFloatingPlayer = false;
      _controller.pause();
    });
  }



  @override
  Widget build(BuildContext context) {
    final sections = parseStructuredChords(widget.song.chords);
//print(_controller.value.position);
    return Scaffold(
    appBar: AppBar(

      title:  Text(
        widget.song.title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,

    ),
      floatingActionButton: _isScrolling
          ? FloatingActionButton(
backgroundColor: Colors.transparent,
        onPressed: _toggleAutoScroll,
        child: const Icon(Icons.arrow_downward,color: Colors.green,),
      )
          : widget.song.yt ==''?null : FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: (){
      if(_showFloatingPlayer){_closePlayer();}else{
        _showPlayer();
      }
        },
        child: !_showFloatingPlayer?Icon(Icons.play_arrow_sharp):null),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: GestureDetector(
              onLongPress: () => settings(context,),
              onDoubleTap: () => _toggleAutoScroll(), // You can adjust speed
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:MainAxisAlignment.start ,
                  children: [

                    SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '     singer : ${widget.song.singer}',
                          style: TextStyle(fontSize: 12+fontSize),
                        ),
                        Text('Key : ${widget.song.key}        ',
                            style: TextStyle(fontSize: 12+fontSize))
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...sections.map((section) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          Text(
                            section.name,
                            style:   TextStyle(
                                fontSize: 10+fontSize,
                              color: Colors.red,
                                fontWeight: FontWeight.w600,
                               ),
                          ),
                          const SizedBox(height: 6),
                          ...section.blocks.map((block) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                if (block.label != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 1.0),
                                    child:  Text(
                                      ' ${block.label!} ',
                                      style:   TextStyle(
                                        fontSize: 10+fontSize,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,

                                      ),
                                    ),
                                  ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final barsPerRow = _calculateBarsPerRow(constraints.maxWidth);
                                    final barWidth = (constraints.maxWidth - (barsPerRow - 1) * 8) / barsPerRow;

                                    return Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: block.bars
                                          .map((bar) => Container(
                                            margin: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: _buildChordBar(
                                                context, bar, barWidth),
                                          ))
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    }),
                    SizedBox(height: 100,)
                  ],
                ),
              ),
            ),
          ),

          // Floating YouTube player
          if (_showFloatingPlayer)
            Positioned(
              left: _floatingOffset.dx,
              top: _floatingOffset.dy,
              child: GestureDetector(
                onDoubleTap: (){
                  _closePlayer();
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Get the screen dimensions
                    final screenSize = MediaQuery.of(context).size;

                    // Define minimum and maximum sizes as proportions of the screen size
                    double minFloatingWidth = screenSize.width * 0.6; // 20% of screen width
                    double minFloatingHeight = screenSize.height * 0.2; // 10% of screen height
                    double maxFloatingWidth = screenSize.width * 0.8; // 80% of screen width
                    double maxFloatingHeight = screenSize.height * 0.2; // 50% of screen height

                    // Update position
                    _floatingOffset += Offset(details.focalPointDelta.dx,
                        details.focalPointDelta.dy);

                    // Dynamically resize the floating player based on scale
                    double newWidth = (_floatingWidth * details.scale)
                        .clamp(minFloatingWidth, maxFloatingWidth);
                    double newHeight = (_floatingHeight * details.scale)
                        .clamp(minFloatingHeight, maxFloatingHeight);

                    // Apply size changes only if they are significant
                    if ((newWidth - _floatingWidth).abs() > 5 ||
                        (newHeight - _floatingHeight).abs() > 5) {
                      _floatingWidth = newWidth;
                      _floatingHeight = newHeight;
                    }

                    // Ensure the floating player stays within the screen bounds
                    _floatingOffset = Offset(
                      _floatingOffset.dx
                          .clamp(0, screenSize.width - _floatingWidth),
                      _floatingOffset.dy
                          .clamp(0, screenSize.height - _floatingHeight),
                    );
                  });
                },
                child: Container(
                  width: _floatingWidth,
                  height: _floatingHeight,
color: Colors.transparent,
                  child: YoutubePlayer(
                    aspectRatio: 16/9,
                    controller: _controller,
                    showVideoProgressIndicator: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  int _calculateBarsPerRow(double width) {
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 800) return 4;
    return 5;
  }

  /// Parses full string from server into sections with blocks
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
        // It's a section name (e.g., intro, verse)
        if (currentSection != null) {
          sections
              .add(ChordSection(name: currentSection, blocks: currentBlocks));
        }
        currentSection = trimmed;
        currentBlocks = [];
        currentLabel = null;
      } else if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
        // It's a part label (e.g., <guitar only>)
        currentLabel = trimmed.substring(1, trimmed.length - 1);
      } else if (trimmed.contains('|')) {
        // It's a chord line
        currentBlocks.add(
          ChordBlock(label: currentLabel, bars: _extractBars(trimmed)),
        );
        currentLabel = null; // Reset after using
      }
    }

    if (currentSection != null) {
      sections.add(ChordSection(name: currentSection, blocks: currentBlocks));
    }

    return sections;
  }


  List<Map>  _splitChordsWithNotes(String bar, [int transposeShift = 0]) {
    final regex = RegExp(
        r'(\|\:|\:\||\|\||\||D\.C\.|D\.S\.|Fine|Coda|Segno|To Coda|~|>)' + // group(1): symbol
            r'|' +
            r'(?:\{([^\}]+)\})?' +                 // group(2): chord group
            r'([A-G][#b♭]?(?:\/[A-G][#b♭]?)?[a-zA-Z0-9#b♭]*)?' + // group(3): chord (like C, Am, A/C#)
            r'(_)?' +// group(4): underscore (optional)
            r'(\[[0-9#b.,̣̇\s]+\])?' // ✅ now includes # and b

      //    r'(\[[0-9.,̣̇\s]+\])?' // group(5): notes               // group(5): notes
    );


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

      if (isRest && group == null && (chord == null || chord.isEmpty)) {
        return {'chord': '_', 'note': notes}; // rest with notes
      }

      if (group != null) {
        final chords = group.split(',').map((c) =>
        transposeShift != 0
            ? transposeChord(c.trim(), transposeShift)
            : c.trim()).toList();
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

  /// Build one bar widget
  Widget _buildChordBar(BuildContext context, String bar, double width) {

    final beats = _splitChordsWithNotes(bar.trim(),transposeShift);

    return Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).focusColor,
        ),
        child:   Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: beats.map((beat) {
            if (beat.containsKey('symbol')) {
              final symbol = beat['symbol']!;
              return AutoSizeText(
                symbol,
                style: TextStyle(
                  fontSize: 12+fontSize,
                  fontWeight: FontWeight.bold,
                  color: symbolColor[symbol] ?? Colors.orange,
                ),
              );
            }

            final noteList = List<String>.from(beat['note'] ?? []);

            // 💤 Rest
            if (beat.containsKey('chord') && beat['chord'] == '_') {
              return Column(
                children: [
                  AutoSizeText("_", style: TextStyle(fontSize: 12+fontSize,)),
                  if (noteList.isNotEmpty)
                    Row(
                      children: List.generate(noteList.length, (i) {
                        return Row(
                          children: [
                            AutoSizeText(noteList[i],style:   TextStyle(fontSize: 6+fontSize,color: Colors.green)),
                            if (i < noteList.length - 1)
                              AutoSizeText(',',style:   TextStyle(fontSize: 6+fontSize,)), // Add comma except for last
                          ],
                        );
                      }),
                    )
                ],
              );
            }

            // 🎵 Chord Group
            if (beat.containsKey('chordGroup')) {
              return Column(
                children: [
                  AutoSizeText('${beat['chordGroup'].join(',')}', style:   TextStyle(fontSize: 11+fontSize, fontWeight: FontWeight.w600)),
                  if (noteList.isNotEmpty)
                    Row(
                      children: List.generate(noteList.length, (i) {
                        return Row(
                          children: [
                            AutoSizeText(noteList[i],style:   TextStyle(fontSize: 6+fontSize,color: Colors.green)),
                            if (i < noteList.length - 1)
                              AutoSizeText(',',style:   TextStyle(fontSize: 6+fontSize)), // Add comma except for last
                          ],
                        );
                      }),
                    )
                ],
              );
            }

            // 🎵 Normal Chord
            if (beat.containsKey('chord')) {
              final chord = beat['chord']!;
              final root = _extractRoot(chord);
              final suffix = chord.substring(root.length);
              return Column(
                children: [
                  RichText(

                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,

                      children: [
                        TextSpan(text: root, style: TextStyle(fontSize: 12+fontSize, fontWeight: FontWeight.bold,)),
                        TextSpan(text: suffix, style: TextStyle(fontSize: 12+fontSize,fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (noteList.isNotEmpty)
                    Row(
                      children: List.generate(noteList.length, (i) {
                        return Row(
                          children: [
                            AutoSizeText(noteList[i],style:   TextStyle(fontSize: 6+fontSize,color: Colors.green)),
                            if (i < noteList.length - 1)
                              Text(',',style:   TextStyle(fontSize: 6+fontSize,)), // Add comma except for last
                          ],
                        );
                      }),
                    )
                ],
              );
            }

            return const SizedBox();
          }).toList(),
        )

    );
  }

  /// Extract root note for styling
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
// repeat markers
    final tokens = <String>[];

    // Step 1: Replace repeat markers with tokens to preserve them during split
    String temp = input
        .replaceAll('|:', ' <<REPSTART>> ')
        .replaceAll(':|', ' <<REPEND>> ')
        .replaceAll('||', ' <<DOUBLEBAR>> ');

    // Step 2: Split on single bar |
    final raw = temp.split('|');

    for (var part in raw) {
      part = part.trim();
      if (part.isEmpty) continue;

      // Restore symbols
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


  void _toggleAutoScroll() {
    if (_isScrolling) {
      _scrollController.jumpTo(_scrollController.offset);
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _isScrolling = false;
        });
      }
    } else {
      if (!_scrollController.hasClients) return;
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _isScrolling = true;
        });
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        maxScroll,
        duration: Duration(seconds: (maxScroll / speedScroll).round()),
        curve: Curves.linear,
      ).whenComplete(() {
        // IMPORTANT: Check if widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    }
  }

  void settings(BuildContext context) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings', style: TextStyle(fontSize: 16)),

                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scroll speed: ${speedScroll.toInt()}', style: TextStyle(fontSize: 12)),
                  SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 1,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                    ),
                    child: Slider(
                      value: speedScroll,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: speedScroll.toInt().toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          speedScroll = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: Icon(Icons.remove,size: 16),
                          onPressed: (){
                            if(fontSize > -2 ){
                              setState(() {
                                fontSize --;
                              });
                            }
                          }),
                      Text('FontSize',style: TextStyle(fontSize: 12),),
                      IconButton(
                          icon: Icon(Icons.add,size: 16),
                          onPressed: () {
                            if(fontSize < 8 ){
                              setState(() {
                                fontSize ++;
                              });
                            }
                          }),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove,size: 16),
                        onPressed: () => setState(() => transposeShift--),
                      ),
                      Text('Transpose',style: TextStyle(fontSize: 12),),
                      IconButton(
                        icon: Icon(Icons.add,size: 16,),
                        onPressed: () => setState(() => transposeShift++),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Check if widget is still mounted before calling setState
                    if (mounted) {
                      setState(() {});
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ChordSection {
  final String name;
  final List<ChordBlock> blocks;

  ChordSection({required this.name, required this.blocks});
}

class ChordBlock {
  final String? label; // e.g. "Piano only"
  final List<String> bars;

  ChordBlock({this.label, required this.bars});
}


*/
