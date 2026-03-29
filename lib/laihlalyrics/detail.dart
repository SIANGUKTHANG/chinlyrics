import 'dart:async';
import 'dart:io';
import 'package:chinlyrics/laihlalyrics/model/song_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/rendering.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class SongDetailPage extends StatefulWidget {
  final SongModel song;

  const SongDetailPage({super.key, required this.song});

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  // ================= AUDIO PLAYER & DOWNLOAD STATE =================
  AudioPlayer player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double progress = 0.0;
  bool isDownloaded = false;
  bool alreadyAxist = false;
  bool _isDownloading = false;
  bool _isLocalFile = false;
  late String urlPath;

  // ================= SCROLL & SETTINGS STATE =================
  bool _isScrolling = false;
  late ScrollController _scrollController;
  final Box _settingsBox = Hive.box('settingsBox');
  late final StreamSubscription _playerStateSub;
  late final StreamSubscription _durationSub;
  late final StreamSubscription _positionSub;
  double speedScroll = 6;
  bool _showChords = true;
  double _fontSize = 16.0;
  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    speedScroll = _settingsBox.get('scrollSpeed', defaultValue: 6.0);
    _showChords = _settingsBox.get('showChords', defaultValue: true);

    checkTrack();

    _playerStateSub = player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _durationSub = player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _positionSub = player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
  }

  // ================= HELPER FUNCTION =================
// Google Drive URL kha Direct Download Link ah a thleng tu
  String _getDirectDownloadUrl(String? uri) {
    if (uri!.contains("drive.google.com")) {
      try {
        // RegExp hmang in Drive ID lak a him bik (Split nakin a tha deuh)
        RegExp regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
        var match = regExp.firstMatch(uri);
        if (match != null && match.groupCount >= 1) {
          String fileId = match.group(1)!;
          // export=view nakin export=download hmang ahcun Dio nih a theihthiam deuh
         return 'https://drive.google.com/uc?export=download&id=$fileId';
        }
      } catch (e) {
        print("Drive ID laknak ah palhnak: $e");
      }
    }
    // Cloudinary asiloah adang URL cu a direct in ngah ko
    return uri;
  }

// ================= TRACK CHECK LOGIC =================
  Future<void> checkTrack() async {
    Directory dir = await getApplicationDocumentsDirectory();

    String safeTitle = widget.song.title.replaceAll(' ', '_');
    String safeSinger = widget.song.singer.replaceAll(' ', '_');
    String savePath = '${dir.path}/${safeTitle}_$safeSinger.mp3';

    File file = File(savePath);

    if (await file.exists()) {
      setState(() {
        alreadyAxist = true;
        _isLocalFile = true;
        urlPath = savePath;
      });

      await player.setSourceDeviceFile(savePath);
    }
  }

// ================= DOWNLOAD LOGIC =================
  Future<void> downloadFile(String uri, String fileName) async {
    try {
      setState(() {
        _isDownloading = true;
        progress = 0.0;
        isDownloaded = false;
      });

      Directory dir = await getApplicationDocumentsDirectory();
      String savePath = '${dir.path}/$fileName';
      Dio dio = Dio();

      // Direct URL kan lak lai (Drive a si ah thlenmi a chuak lai, Cloudinary a si ah a sining in a chuak lai)
      String finalUrl = _getDirectDownloadUrl(uri);

      await dio.download(
        finalUrl,
        savePath,
        onReceiveProgress: (rcv, total) {
          // total hi -1 a si lo lawngah za-ah-zeizat (percentage) a tuak khawh lai
          if (total != -1 && mounted) {
            setState(() {
              progress = rcv / total;
            });
          }
        },
       options:    Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 30),
          )
      );

      // Download a dih bak in hika ah a ra lai
      if (!mounted) return;
      setState(() {
        isDownloaded = true;
        alreadyAxist = true;
        urlPath = savePath;
        _isDownloading = false;
        progress = 1.0;
      });
      _settingsBox.put('download_${widget.song.id}', true);
      await player.setSourceDeviceFile(savePath);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          progress = 0.0;
        });
      }

      // Error a chuah ahcun mipi theihter nak
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Download tuah khawh a si lo! Network asiloah Link check tthan mu.")),
        );
      }
    }
  }

  // ================= SCROLL & SETTINGS UI =================
  void _toggleAutoScroll() {
    if (_isScrolling) {
      _scrollController.jumpTo(_scrollController.offset);
      if (mounted) setState(() => _isScrolling = false);
    } else {
      if (!_scrollController.hasClients) return;
      if (mounted) setState(() => _isScrolling = true);
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController
          .animateTo(
        maxScroll,
        duration: Duration(seconds: (maxScroll / speedScroll).round()),
        curve: Curves.linear,
      )
          .whenComplete(() {
        if (mounted) setState(() => _isScrolling = false);
      });
    }
  }

  void _showSettingsPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding:
                const EdgeInsets.only(top: 10, bottom: 30, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10))),
                const Text("Hla Settings",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // SCROLL SPEED
                Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.blueAccent),
                    const SizedBox(width: 15),
                    const Text("Auto-Scroll Speed",
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                    const Spacer(),
                    Text("${speedScroll.toInt()}x",
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: speedScroll,
                  min: 1.0,
                  max: 20.0,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) {
                    setModalState(() => speedScroll = val);
                    setState(() => speedScroll = val);
                    _settingsBox.put('scrollSpeed', val);
                  },
                ),
                const Divider(color: Colors.white12, height: 20),

                // SHOW CHORDS TOGGLE
                if (widget.song.isChord == true) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.purpleAccent,
                    title: const Row(
                      children: [
                        Icon(Icons.queue_music, color: Colors.purpleAccent),
                        SizedBox(width: 15),
                        Text("Chords Langhter",
                            style:
                                TextStyle(color: Colors.white, fontSize: 15)),
                      ],
                    ),
                    value: _showChords,
                    onChanged: (val) {
                      setModalState(() => _showChords = val);
                      setState(() => _showChords = val);
                      _settingsBox.put('showChords', val);
                    },
                  ),
                  const Divider(color: Colors.white12, height: 20),
                ],

                // SHARE AS PDF
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: const Text("PDF in Print / Share",
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    _shareSongAsPdf(widget.song);
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showFontSizeSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 90,
              right: 15,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ]),
                  child: StatefulBuilder(builder: (context, setPopupState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Cafang Ngan/Hme",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.text_fields,
                                color: Colors.white54, size: 14),
                            Expanded(
                              child: Slider(
                                value: _fontSize,
                                min: 12.0,
                                max: 36.0,
                                activeColor: Colors.blueAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (value) {
                                  setPopupState(() => _fontSize = value);
                                  setState(() => _fontSize = value);
                                },
                              ),
                            ),
                            const Icon(Icons.text_fields,
                                color: Colors.white, size: 24),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _durationSub.cancel();
    _positionSub.cancel();

    player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }


  String sanitize(String input) {
    return input.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }
  @override
  Widget build(BuildContext context) {
    bool hasAudio = widget.song.soundtrack != null &&
        widget.song.soundtrack!.trim().isNotEmpty;
    Color catColor = Colors.blueAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: widget.song.soundtrack == null ||
              widget.song.soundtrack == ''
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.blue.withOpacity(0.4),
              onPressed: () async {
                if (_isLocalFile) {
                  // PLAY / PAUSE
                  if (_isPlaying) {
                    await player.pause();
                  } else {
                    await player.resume();
                  }
                } else {
                  // DOWNLOAD
                  String safeTitle = sanitize(widget.song.title);
                  String safeSinger = sanitize(widget.song.singer);
                  String fileName = '${safeTitle}_$safeSinger.mp3';

                  await downloadFile(widget.song.soundtrack!, fileName);

                  setState(() {
                    _isLocalFile = true;
                  });
                }
              },
              child: Icon(
                _isPlaying ? Icons.pause_circle_sharp : Icons.play_circle_sharp,
                color: Colors.white,
                size: 40,
              ),
            ),

      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isAppBarVisible) setState(() => _isAppBarVisible = false);
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isAppBarVisible) setState(() => _isAppBarVisible = true);
          }

          // HIKA HI A BIAPI TUK: false a si a hau, cuticun BottomNav zongah a tlun/phan kho ve lai
          return false;
        },
        child: Container(
          padding: const EdgeInsets.only(top: 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E2130), Colors.black],
                stops: [0.0, 0.4]),
          ),
          child: Column(
            children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isAppBarVisible ? 100.0 : 0.0,
                child: SingleChildScrollView( // <--- This prevents the overflow during animation
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(

                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Category Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(widget.song.category ?? 'Hla',
                                    style: TextStyle(
                                        color: catColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              // Title
                              Text(
                                widget.song.title ?? 'No Title',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2),
                              ),
                              const SizedBox(height: 8),
                              // Singer
                              if (widget.song.type != 'blog')
                                Row(
                                  children: [
                                    const Icon(Icons.mic, color: Colors.white54, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        widget.song.singer ?? 'Unknown',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Settings Buttons
                        Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.text_fields, color: Colors.white70),
                                onPressed: _showFontSizeSettings),
                            IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white70),
                                onPressed: _showSettingsPopup),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= AUDIO PLAYER (Download he a mawi mi) =================
                      if (hasAudio && !_isScrolling)
                         Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            SliderTheme(
                                              data: SliderTheme.of(context)
                                                  .copyWith(
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                        enabledThumbRadius:
                                                            6.0),
                                                overlayShape:
                                                    const RoundSliderOverlayShape(
                                                        overlayRadius: 14.0),
                                                trackHeight: 3,
                                                activeTrackColor:
                                                    Colors.blueAccent,
                                              ),
                                              child: Slider(
                                                min: 0,
                                                max: _duration.inSeconds
                                                            .toDouble() >
                                                        0
                                                    ? _duration.inSeconds
                                                        .toDouble()
                                                    : 1.0,
                                                value: _isDownloading
                                                    ? progress
                                                    : _position.inSeconds
                                                        .toDouble()
                                                        .clamp(
                                                            0,
                                                            _duration
                                                                .inSeconds
                                                                .toDouble()),
                                                onChanged: (value) async {
                                                  final position = Duration(
                                                      seconds: value.toInt());
                                                  await player.seek(position);
                                                },
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(_formatTime(_position),
                                                    style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12)),
                                                Text(_formatTime(_duration),
                                                    style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12)),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_isDownloading)
                                    _buildDownloadIndicator(),
                                ],
                              ),


                      const Divider(
                          color: Colors.white12,
                          height: 1,
                          indent: 25,
                          endIndent: 25),

                      // ================= LYRICS BODY =================
                      GestureDetector(
                        onDoubleTap: _toggleAutoScroll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8),
                          width: double.infinity,
                          child:widget.song.type == 'blog'
                              ? _buildFormattedText(widget.song.lyrics ?? '')
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLyricsUI(widget.song.lyrics ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LYRICS & CHORDS WIDGET (Na rak tuahmi) =================
  List<Widget> _buildLyricsUI(String rawLyrics) {
    List<Widget> widgets = [];
    List<String> blocks = rawLyrics.split(RegExp(r'(?=\{verse\}|\{chorus\})'));

    for (String block in blocks) {
      if (block.trim().isEmpty) continue;

      bool isChorus = block.startsWith('{chorus}');
      String lyricsBlock = block.split('{').last.split('}').first.toString();

      String cleanText =
          block.replaceAll('{verse}', '').replaceAll('{chorus}', '').trim();

      if (cleanText.isEmpty) continue;

      widgets.add(
        Container(
          width: double.infinity,
          decoration: isChorus
              ? BoxDecoration(
                  border: Border(
                  left: BorderSide(
                      color: Colors.blueAccent.withOpacity(0.8), width: 3),
                ))
              : null,
          child: _buildLyricSectionWithChords(
            text: cleanText,
            lyricsBlock: lyricsBlock,
            showChord: _showChords, // Settings toggle he aa pehtlai cang
            isChorus: isChorus,
          ),
        ),
      );
    }
    return widgets;
  }

  // UI chung i na duhmi zawnah hika te hi va chap
  Widget _buildDownloadIndicator() {
    if (!_isDownloading) {
      return const SizedBox.shrink(); // Download a tuah lo ahcun thup
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Downloading audio...",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                // 45% ti bantuk in a lang lai
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress, // 0.0 in 1.0
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // Na Code thengte kha laakmi a si (A langhning mawi tein remhchih mi)
  Widget _buildLyricSectionWithChords(
      {required String text,
      required String lyricsBlock,
      required bool showChord,
      required bool isChorus})
  {
    double currentFontSize = isChorus ? _fontSize + 1 : _fontSize;
    FontWeight fw = isChorus ? FontWeight.bold : FontWeight.w600;
    Color txtColor = isChorus ? Colors.white : Colors.white70;
    double leftPad = isChorus ? 20.0 : 0.0;

    // 1. CHORD PHIH (OFF) A SI AHCUN
    if (!showChord) {
      String cleanLyrics = text.replaceAll(RegExp(r'\[.*?\]'), '');
      return Padding(
        padding: EdgeInsets.only(bottom: 15.0, left: leftPad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$lyricsBlock ⤵️',
              style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: currentFontSize - 3,
                  height: 1.6,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              cleanLyrics,
              style: TextStyle(
                  color: txtColor, fontSize: currentFontSize, fontWeight: fw),
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
        chordsList.add(splitPart[0]);
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
                fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 15.0, left: leftPad),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            // A tang lei ah aa tlar nakhnga
            children: List.generate(chordsList.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CHORD
                  if (chordsList[index].isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // Chord hmeh tikah Action (Thn: Chord Detail langhter)
                      },
                      child: Text(
                        chordsList[index],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                            fontSize: currentFontSize - 4),
                      ),
                    ),
                  // LYRIC
                  Text(
                    lyricsList[index],
                    style: TextStyle(
                        color: txtColor,
                        fontSize: currentFontSize,
                        fontWeight: fw),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }


  // ================= PDF SHARE WIDGETS =================
  Future<void> _shareSongAsPdf(SongModel post) async {
    final pdf = pw.Document();

    // 1. Load Fonts
    final tFont = await PdfGoogleFonts.notoSansRegular();
    final tFontBold = await PdfGoogleFonts.notoSansBold();

    // 2. Build the PDF Document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header: Title and Singer
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    post.title ?? 'No Title',
                    style: pw.TextStyle(font: tFontBold, fontSize: 24,color:  PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    post.singer ?? 'Unknown Artist',
                    style: pw.TextStyle(
                      font: tFont,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
              ),
            ),

            // Lyrics & Chords Body
            ..._buildPdfLyricsUI(post.lyrics ?? '', tFont, tFontBold),

            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            pw.Center(
              child: pw.Text(
                "Laihla Lyrics App in ka rak share mi a si.",
                style: pw.TextStyle(font: tFont, fontSize: 10, color: PdfColors.grey600),
              ),
            ),

            pw.SizedBox(height: 10),
            pw.Text(
              "Download Link:",
              style: pw.TextStyle(font: tFontBold, fontSize: 10, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 15),
            // Android Clickable Link
            pw.UrlLink(
              destination: 'https://play.google.com/store/apps/details?id=chinplus.info.laihlalyrics.laihla_lyrics',
              child: pw.Text(
                "Android App: Click hika ah hmet",
                style: pw.TextStyle(
                  font: tFont,
                  fontSize: 10,
                  color: PdfColors.blue, // Blue indicates it's a link
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),

            pw.SizedBox(height: 4),

            // iOS Clickable Link
            pw.UrlLink(
              destination: 'https://apps.apple.com/ie/app/laihla-lyrics/id6479561333',
              child: pw.Text(
                "iOS App: Click hika ah hmet",
                style: pw.TextStyle(
                  font: tFont,
                  fontSize: 10,
                  color: PdfColors.blue,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // 3. Share or Save the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${sanitize(post.title ?? 'Hla')}.pdf',
    );
  }
  // Helper method to parse lyrics and float chords ABOVE the text for the PDF
  List<pw.Widget> _buildPdfLyricsUI(String rawLyrics, pw.Font tFont, pw.Font tFontBold) {
    List<pw.Widget> pdfWidgets = [];

    // Split lyrics by Verse/Chorus blocks just like your UI
    List<String> blocks = rawLyrics.split(RegExp(r'(?=\{verse\}|\{chorus\})'));

    for (String block in blocks) {
      if (block.trim().isEmpty) continue;

      bool isChorus = block.startsWith('{chorus}');

      // Get the label (e.g., "verse", "chorus")
      String lyricsBlockLabel = "";
      if (block.contains('{') && block.contains('}')) {
        lyricsBlockLabel = block.split('{').last.split('}').first.toString();
      }

      // Remove the tag from the text
      String cleanText = block.replaceAll(RegExp(r'\{.*?\}'), '').trim();
      if (cleanText.isEmpty) continue;

      double leftPad = isChorus ? 20.0 : 0.0;
      pw.Font currentFont = isChorus ? tFontBold : tFont;

      // Add the Verse/Chorus Header
      pdfWidgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(top: 15, bottom: 8, left: leftPad),
          child: pw.Text(
            '$lyricsBlockLabel ',
            style: pw.TextStyle(
              font: tFontBold,
              color: PdfColors.pink,
              fontSize: 12,
            ),
          ),
        ),
      );

      // Split the block into individual lines
      List<String> lines = cleanText.split('\n');

      for (String line in lines) {
        if (line.trim().isEmpty) {
          pdfWidgets.add(pw.SizedBox(height: 10)); // Empty line spacing
          continue;
        }

        // 1. CHORDS HIDDEN
        if (!_showChords) {
          String noChordsLine = line.replaceAll(RegExp(r'\[.*?\]'), '');
          pdfWidgets.add(
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: 6, left: leftPad),
              child: pw.Text(
                noChordsLine,
                style: pw.TextStyle(font: currentFont, fontSize: 14),
              ),
            ),
          );
        }
        // 2. CHORDS SHOWN (Float above text)
        else {
          List<String> chordsList = [];
          List<String> lyricsList = [];
          List<String> parts = line.split('[');

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

          pdfWidgets.add(
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: 10, left: leftPad),
              child: pw.Wrap(
                // WrapCrossAlignment.end ensures the bottom lyric texts align perfectly
                // on the same baseline, even if some words don't have chords above them.
                crossAxisAlignment: pw.WrapCrossAlignment.end,
                children: List.generate(chordsList.length, (index) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // Render Chord (if it exists)
                      if (chordsList[index].isNotEmpty)
                        pw.Text(
                          chordsList[index],
                          style: pw.TextStyle(
                            font: tFontBold,
                            fontSize: 10,
                            color: PdfColors.purple,
                          ),
                        ),

                      // Render Lyric snippet
                      pw.Text(
                        lyricsList[index],
                        style: pw.TextStyle(
                          font: currentFont,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        }
      }
    }
    return pdfWidgets;
  }

  Widget _buildFormattedText(String text, {int? maxLines}) {
    final RegExp linkOrHashtagRegExp =
    RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+|#\w+)', caseSensitive: false);
    List<TextSpan> spans = [];

    text.splitMapJoin(
      linkOrHashtagRegExp,
      onMatch: (Match match) {
        String matchText = match.group(0)!;

        if (matchText.startsWith('#')) {
          // Hashtag caah
          spans.add(TextSpan(
              text: matchText,
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)));
        } else {
          // Link caah
          spans.add(TextSpan(
            text: matchText,
            style: const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                fontSize: 15),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                String urlString = matchText.startsWith('www.')
                    ? 'https://$matchText'
                    : matchText;
                final Uri url = Uri.parse(urlString);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
          ));
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        // Ca sasawh caah (Font size 15)
        spans.add(TextSpan(
            text: nonMatch,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.4)));
        return '';
      },
    );

    return RichText(
      maxLines: maxLines,
      // A thar
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      // A thar
      text: TextSpan(children: spans),
    );
  }
}