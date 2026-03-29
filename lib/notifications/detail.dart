import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // A THAR: Firestore import
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chord_mod/flutter_chord.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import '../ads_manager.dart';
import '../constant.dart';
import '../pages/chord.dart';

const bool kShowAds = bool.fromEnvironment('SHOW_ADS', defaultValue: false);

class DetailsPage extends StatefulWidget {
  final String title;
  final bool chord;
  final String singer;
  final String composer;
  final String verse1;
  final String verse2;
  final String verse3;
  final String verse4;
  final String verse5;
  final String songtrack;
  final String chorus;
  final String endingChorus;

  const DetailsPage({
    super.key,
    required this.title,
    required this.chord,
    required this.composer,
    required this.singer,
    required this.verse1,
    required this.verse2,
    required this.verse3,
    required this.verse4,
    required this.verse5,
    required this.songtrack,
    required this.chorus,
    required this.endingChorus,
  });

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  User? user = FirebaseAuth.instance.currentUser;
  AudioPlayer player = AudioPlayer();
  late ScrollController _scrollController;
  bool _isExpanded = false;
  int transpose = 0;
  bool favorite = false;
  bool _chordChecked = false;
  bool showFullScreen = false;
  bool downloading = false;
  double progress = 0.0;
  bool isDownloaded = false;
  bool alreadyAxist = false;

  int maxduration = 100;
  int currentpos = 0;
  String currentpostlabel = "00:00";
  String maxDurationlabel = "00:00";
  bool isplaying = false;
  late String urlPath;
  double fontSize = 15;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isScrolling = false;
  double speedScroll = 6;
  bool isAdsLoading = false;
// A THAR: Interstitial Ad caah
  InterstitialAd? interstitialAd;
  late BannerAd banner;
  bool isAdReady = false;

  @override
  void initState() {
    checkTrack();
    _scrollController = ScrollController();

    player.onDurationChanged.listen((Duration event) {
      maxduration = event.inMilliseconds;
      maxDurationlabel = _formatDuration(maxduration);
    });

    player.onPositionChanged.listen((Duration event) {
      currentpos = event.inMilliseconds;
      currentpostlabel = _formatDuration(currentpos);
      setState(() {});
    });

    _loadInterstitialAd();
    banner = BannerAd(
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
    )..load();
    OrientationHelper()
        .setPreferredOrientations([DeviceOrientation.portraitUp]);
    favorite = favorites.any((song) => song['title'] == widget.title);
    super.initState();

  }

  // Interstitial Ad Load Tuahnak
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId, // ads_manager.dart ah hihi a um a hau
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _finishReportAndPop(); // Ad an khar tikah Page a kir lai
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _finishReportAndPop(); // Ad a fail zongah Page cu a kir thiamthiam lai
            },
          );

          setState(() {
            interstitialAd = ad;
            isAdReady = true;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
          isAdReady = false;
        },
      ),
    );
  }

  // Upload Dih In Page Kirnak Function
  void _finishReportAndPop() {

    if (mounted) Navigator.pop(context, true);
  }

  String _formatDuration(int milliseconds) {
    int shours = Duration(milliseconds: milliseconds).inHours;
    int sminutes = Duration(milliseconds: milliseconds).inMinutes;
    int sseconds = Duration(milliseconds: milliseconds).inSeconds;

    int rminutes = sminutes - (shours * 60);
    int rseconds = sseconds - (sminutes * 60 + shours * 60 * 60);
    return "${rminutes.toString().padLeft(2, '0')}:${rseconds.toString().padLeft(2, '0')}";
  }

  Future<void> checkTrack() async {
    Directory dir = await getTemporaryDirectory();
    String savePath = '${dir.path}/${widget.title}${widget.singer}.mp3';
    File file = File(savePath);

    if (await file.exists()) {
      setState(() {
        alreadyAxist = true;
        urlPath = savePath;
      });
      await player.setSourceDeviceFile(savePath);
    }
  }

  Future<void> downloadFile(String uri, String fileName) async {
    try {
      setState(() {
        downloading = true;
        progress = 0.0;
        isDownloaded = false;
      });

      Directory dir = await getTemporaryDirectory();
      String savePath = '${dir.path}/$fileName';
      Dio dio = Dio();
      String finalUrl = '';

      if (uri.contains("drive.google.com")) {
        String fileId = uri.split('/d/')[1].split('/')[0];
        finalUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
      } else {
        finalUrl = uri;
      }

      await dio.download(
        finalUrl,
        savePath,
        onReceiveProgress: (rcv, total) async {
          setState(() {
            progress = rcv / total;
          });

          if (progress >= 1.0) {
            setState(() {
              isDownloaded = true;
              alreadyAxist = true;
              urlPath = savePath;
              downloading = false;
            });
            await player.setSourceDeviceFile(savePath);
          }
        },
      );
    } catch (e) {
      print("Download error: $e");
      setState(() {
        downloading = false;
        progress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    player.dispose();
    _scrollController.dispose();
    banner.dispose();
    interstitialAd!.show();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _isScrolling
          ? null
          : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'title : ${widget.title}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                color: favorite ? Colors.redAccent : Colors.white),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: _buildBottomPlayerSection(),
        ),
      ),
      endDrawer: showFullScreen ? null : _buildSettingsDrawer(),
      floatingActionButton: alreadyAxist
          ? GestureDetector(
        onTap: () async {
          if (!isplaying) {
            await player.resume();
            setState(() => isplaying = true);
          } else {
            await player.pause();
            setState(() => isplaying = false);
          }
        },
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.redAccent,
          child: Icon(isplaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 30),
        ),
      )
          : downloading
          ? CircleAvatar(
        child: CircularProgressIndicator(
          backgroundColor: Colors.white24,
          color: Colors.redAccent,
          value: progress,
        ),
      )
          : widget.songtrack.isNotEmpty
          ? IconButton(
          onPressed: () => downloadFile(widget.songtrack,
              '${widget.title}${widget.singer}.mp3'),
          icon: CircleAvatar(
              backgroundColor: Colors.white12,
              child: Icon(
                Icons.cloud_download,
                color: Colors.green,
              )))
          : _isScrolling
          ? FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: _toggleAutoScroll,
        child: const Icon(Icons.arrow_downward,
            color: Colors.green),
      )
          : FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: _toggleAutoScroll,
        child: const Text(''),
      ),
      bottomSheet: isAdsLoading
          ? Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: AdSize.banner.height.toDouble(),
        width: MediaQuery.of(context).size.width,
        child: AdWidget(ad: banner),
      )
          : const SizedBox(height: 1),
      body: GestureDetector(
        onDoubleTap: () {
          _toggleAutoScroll();
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: _isScrolling ? 80 : 0),
                    _buildSongInfoHeader(),
                    SizedBox(height: showFullScreen ? 1 : 12),
                    _buildChordSection(widget.verse1),
                    _buildChordSection(widget.verse2),
                    _buildChordSection(widget.verse3),
                    _buildChordSection(widget.verse4),
                    _buildChordSection(widget.verse5),
                    if (widget.endingChorus.isNotEmpty)
                      _isExpanded
                          ? Container(
                        margin:
                        const EdgeInsets.only(left: 10.0, top: 10),
                        padding: const EdgeInsets.all(12.0),
                        child: LyricsRenderer(
                          widgetPadding:
                          MediaQuery.of(context).size.width ~/ 3,
                          showChord: _isExpanded,
                          lyrics: widget.endingChorus,
                          textStyle: TextStyle(
                              color: Colors.white70, fontSize: fontSize),
                          chordStyle:
                          const TextStyle(color: Colors.greenAccent),
                          lineHeight: 0,
                          transposeIncrement: transpose,
                          onTapChord: (String chord) =>
                              handleChordTap(context, chord),
                        ),
                      )
                          : Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          widget.endingChorus
                              .replaceAll(RegExp(r'\[(.*?)\]'), ''),
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.singer.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Sa: ${widget.singer}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis))),
              ],
            ),
          const SizedBox(height: 6),
          if (widget.composer.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Text('Phan: ${widget.composer}',
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChordSection(String verse) {
    if (verse.isEmpty) return const SizedBox();
    return Chords(
      vpadding: MediaQuery.of(context).size.width ~/ 6,
      cpadding: MediaQuery.of(context).size.width ~/ 4,
      verse: verse,
      chorus: widget.chorus,
      ending: widget.endingChorus,
      showChord: _isExpanded,
      scrollSpeed: transpose,
      fontSize: fontSize,
    );
  }

  Widget _buildBottomPlayerSection() {
    if (alreadyAxist) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                        overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14.0),
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        activeColor: Colors.redAccent,
                        inactiveColor: Colors.white24,
                        value: currentpos.toDouble(),
                        min: 0,
                        max: maxduration.toDouble() > 0
                            ? maxduration.toDouble()
                            : 100,
                        onChanged: (value) async {
                          await player
                              .seek(Duration(milliseconds: value.round()));
                          setState(() => currentpos = value.round());
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentpostlabel,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text(maxDurationlabel,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else if (downloading) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[900],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Downloading track...",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              backgroundColor: Colors.white24,
              color: Colors.redAccent,
              value: progress,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // --- LOGIC FUNCTIONS ---

  void _toggleFavorite() {
    setState(() {
      if (favorite) {
        favorites.removeWhere((song) => song['title'] == widget.title);
        removeFavoriteData(widget.title);
        favorite = false;
      } else {
        var songData = {
          'title': widget.title,
          'chord': widget.chord,
          'composer': widget.composer,
          'singer': widget.singer,
          'verse 1': widget.verse1,
          'verse 2': widget.verse2,
          'verse 3': widget.verse3,
          'verse 4': widget.verse4,
          'verse 5': widget.verse5,
          'chorus': widget.chorus,
          'songtrack': widget.songtrack,
          'ending chorus': widget.endingChorus
        };
        addFavoriteData(songData);

        favorite = true;
      }
    });
  }

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




  // --- SETTINGS DRAWER ---
  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Settings",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // Scroll Speed
              _buildDrawerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Scroll Speed: ${speedScroll.toInt()}",
                        style: const TextStyle(color: Colors.white70)),
                    SliderTheme(
                      data: SliderThemeData(
                          thumbColor: Colors.blueAccent,
                          activeTrackColor: Colors.blueAccent,
                          inactiveTrackColor: Colors.white12),
                      child: Slider(
                        value: speedScroll,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (v) => setState(() => speedScroll = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Font Size
              _buildDrawerCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Font Size",
                        style: TextStyle(color: Colors.white70)),
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              if (fontSize > 12) setState(() => fontSize--);
                            }),
                        Text(fontSize.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                        IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              if (fontSize < 36) setState(() => fontSize++);
                            }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chord Settings
              if (widget.chord)
                _buildDrawerCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _chordChecked,
                                  activeColor: Colors.blueAccent,
                                  onChanged: (value) {
                                    setState(() {
                                      _chordChecked = value!;
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                ),
                                const Text("Chord",
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                IconButton(
                                    padding: const EdgeInsets.all(2),
                                    onPressed: () =>
                                        setState(() => transpose--),
                                    icon: const Icon(Icons.remove,
                                        color: Colors.white)),
                                Text(transpose.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                IconButton(
                                    padding: const EdgeInsets.all(2),
                                    onPressed: () =>
                                        setState(() => transpose++),
                                    icon: const Icon(Icons.add,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      // Padding te ka remh deuh ListTile he a rem nakhnga
      child: child,
    );
  }
}

