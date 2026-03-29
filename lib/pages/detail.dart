import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    as firestore; // 'firestore' tiah kan auh lai
import 'package:flutter_chord_mod/flutter_chord.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import '../ads_manager.dart';
import '../constant.dart';
import '../musician/lyrics_chord.dart';
import '../pages/chord.dart';

const bool kShowAds = bool.fromEnvironment('SHOW_ADS', defaultValue: false);

class DetailsPage extends StatefulWidget {
  // A THAR: ID le Title lawng ap a si cang
  final String songId;
  final String title;

  const DetailsPage({
    super.key,
    required this.songId,
    required this.title,
  });

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  User? user = FirebaseAuth.instance.currentUser;
  AudioPlayer player = AudioPlayer();
  late ScrollController _scrollController;

  // A THAR: Database in lak dingmi local variables
  bool isLoading = true;
  bool chord = false;
  String singer = '';
  String composer = '';
  String verse1 = '';
  String verse2 = '';
  String verse3 = '';
  String verse4 = '';
  String verse5 = '';
  String songtrack = '';
  String chorus = '';
  String endingChorus = '';

  bool showChord = false;
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

  InterstitialAd? interstitialAd;
  late BannerAd banner;
  bool isAdReady = false;

  @override
  void initState() {
    super.initState();
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

    /*   _loadInterstitialAd();
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
    )..load();*/

    OrientationHelper()
        .setPreferredOrientations([DeviceOrientation.portraitUp]);
    favorite = favorites.any((song) => song['title'] == widget.title);

    // A THAR: Database in hla bia (lyrics) pawl va laak hmasatnak
    fetchSongDetails();
  }

  // A THAR: 1 Read lawng in Hla data laknak
  Future<void> fetchSongDetails() async {
    try {
      // FirebaseFirestore hmai ah 'firestore.' kan chap lai
      firestore.DocumentSnapshot doc = await firestore
          .FirebaseFirestore.instance
          .collection('hla')
          .doc(widget.songId)
          .get(const firestore.GetOptions(
              source: firestore.Source
                  .serverAndCache)); // Source hmai zongah firestore. a herh

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          chord = data['chord'] ?? false;
          singer = data['singer'] ?? '';
          composer = data['composer'] ?? '';
          verse1 = data['verse1'] ?? '';
          verse2 = data['verse2'] ?? '';
          verse3 = data['verse3'] ?? '';
          verse4 = data['verse4'] ?? '';
          verse5 = data['verse5'] ?? '';
          songtrack = data['songtrack'] ?? '';
          chorus = data['chorus'] ?? '';
          endingChorus = data['endingchorus'] ?? '';
          isLoading = false;
        });

        checkTrack();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Hla lak lio ah palhnak: $e");
      setState(() => isLoading = false);
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _finishReportAndPop();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _finishReportAndPop();
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
    // widget.singer si ti loin singer (local var) hman a si
    String savePath = '${dir.path}/${widget.title}$singer.mp3';
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
              bottom: downloading || alreadyAxist
                  ? PreferredSize(
                      preferredSize: Size.fromHeight(30),
                      child: _buildBottomPlayerSection(),
                    )
                  : null,
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
              : songtrack.isNotEmpty
                  ? IconButton(
                      onPressed: () => downloadFile(songtrack,
                          '${widget.title}$singer.mp3'), // Local singer var hman
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

      // A THAR: Loading lio ahcun CircularProgressIndicator a lang lai
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : GestureDetector(
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
                          // widget.verse si ti loin, local verse hman a si

                          buildLyricSection(
                            context,
                            verse1,
                            showChord,

                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                          ),

                          chorus == '' || chorus.isEmpty
                              ? SizedBox()
                              : buildLyricSection(
                                  context,
                                  chorus,
                                  showChord,
                                  verticalPadding: 8.0,
                                  leftPadding: 30.0, // <-- HIHI NA CHAP LAI
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,     fontSize: fontSize,
                                  //  textColor: Colors.yellowAccent,
                                ),

                          verse2 == '' || verse2.isEmpty
                              ? SizedBox()
                              : buildLyricSection(context, verse2, showChord,
                                  fontWeight: FontWeight.w500,     fontSize: fontSize,),

                          verse2 == '' || verse2.isEmpty
                              ? SizedBox()
                              : chorus == '' || chorus.isEmpty
                                  ? SizedBox()
                                  : buildLyricSection(
                                      context,
                                      chorus,
                                      showChord,
                                      verticalPadding: 8.0,
                                      leftPadding: 30.0,     fontSize: fontSize,
                                      fontWeight:
                                          FontWeight.bold, // A chah in langhter
                                      fontStyle:
                                          FontStyle.italic, // A awn in langhter
                                    ),

                          verse3 == '' || verse3.isEmpty
                              ? SizedBox()
                              : buildLyricSection(context, verse3, showChord,
                                  fontWeight: FontWeight.w500,     fontSize: fontSize,),

                          verse3 == '' || verse3.isEmpty
                              ? SizedBox()
                              : chorus == '' || chorus.isEmpty
                                  ? SizedBox()
                                  : buildLyricSection(
                                      context,
                                      chorus,
                                      showChord,     fontSize: fontSize,
                                      verticalPadding: 8.0,
                                      leftPadding: 30.0, // <-- HIHI NA CHAP LAI
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),

                          verse4 == '' || verse4.isEmpty
                              ? SizedBox()
                              : buildLyricSection(context, verse4,      fontSize: fontSize,showChord,
                                  fontWeight: FontWeight.w500),

                          verse4 == '' || verse4.isEmpty
                              ? SizedBox()
                              : chorus == '' || chorus.isEmpty
                                  ? SizedBox()
                                  : buildLyricSection(
                                      context,
                                      chorus,     fontSize: fontSize,
                                      showChord,
                                      verticalPadding: 8.0,
                                      leftPadding: 30.0, // <-- HIHI NA CHAP LAI
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),

                          verse5 == '' || verse5.isEmpty
                              ? SizedBox()
                              : buildLyricSection(context, verse5,      fontSize: fontSize,showChord,
                                  fontWeight: FontWeight.w500),

                          verse5 == '' || verse5.isEmpty
                              ? SizedBox()
                              : chorus == '' || chorus.isEmpty
                                  ? SizedBox()
                                  : buildLyricSection(
                                      context,
                                      chorus,     fontSize: fontSize,
                                      showChord,
                                      verticalPadding: 8.0,
                                      leftPadding: 30.0, // <-- HIHI NA CHAP LAI
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),

                          if (endingChorus.isNotEmpty)
                            buildLyricSection(
                              context,
                              endingChorus,
                              showChord,     fontSize: fontSize,
                              verticalPadding: 8.0,
                              // A hlat deuh nakhnga
                              fontWeight: FontWeight.w600,
                              // Semi-bold
                              textColor: Colors.white70,
                              // A rong tlawmpal a thim deuh mi
                              fontFeatures: [FontFeature.tabularFigures()],
                            )
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
          if (singer.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Sa: $singer',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis))),
              ],
            ),
          const SizedBox(height: 6),
          if (composer.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Text('Phan: $composer',
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
      chorus: chorus,
      ending: endingChorus,
      showChord: showChord,
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

  void _toggleFavorite() {
    setState(() {
      if (favorite) {
        favorites.removeWhere((song) => song['title'] == widget.title);
        removeFavoriteData(widget.title);
        favorite = false;
      } else {
        var songData = {
          'title': widget.title,
          'chord': chord,
          'composer': composer,
          'singer': singer,
          'verse 1': verse1,
          'verse 2': verse2,
          'verse 3': verse3,
          'verse 4': verse4,
          'verse 5': verse5,
          'chorus': chorus,
          'songtrack': songtrack,
          'ending chorus': endingChorus
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

  void _showReportDialog() {
    TextEditingController reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              const Text("Report Error", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: reportController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  "Tahchunhnak: Verse 1 aa palh, asiloah Chord a hman lo...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                if (reportController.text.trim().isEmpty) {

                  return;
                }

                _submitReport(reportController.text.trim());
              },
              child:
                  const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport(String issue) async {
    try {
      var songQuery = await FirebaseFirestore.instance
          .collection('hla')
          .where('title', isEqualTo: widget.title)
          .where('singer', isEqualTo: singer)
          .get();

      for (var doc in songQuery.docs) {
        var songData = doc.data();
        songData['status'] = 'pending';
        songData['type'] = 'report';
        songData['uploaderUid'] = user?.uid;
        songData['reportMessage'] =
            issue; // A THAR: User nih an tialmi palhnak (issue) kan save chih

        await FirebaseFirestore.instance.collection('songToEdit').add(songData);
        await FirebaseFirestore.instance.collection('hla').doc(doc.id).delete();
      }

      await firestore.FirebaseFirestore.instance
          .collection('metadata')
          .doc('part_1')
          .update({
        'songs_map.${widget.songId}': firestore.FieldValue.delete(),
      });

      // Firebase thun a lim bakah Ad a lang lai
      if (isAdReady && interstitialAd != null) {
        interstitialAd!.show();
      } else {
        // Ad a rak um lo asiloah internet a chiat ahcun Ad lang lo in a kir colh lai
        _finishReportAndPop();
      }



      if (mounted) Navigator.pop(context);
    } catch (e) {
     }
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            /// 🔹 HEADER
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// 🔹 SCROLL SPEED
            _buildSection(
              title: "Scroll Speed",
              trailing: speedScroll.toInt().toString(),
              child: Slider(
                value: speedScroll,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (v) => setState(() => speedScroll = v),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 FONT SIZE
            _buildSection(
              title: "Font Size",
              trailing: fontSize.toInt().toString(),
              child: Slider(
                value: fontSize,
                min: 12,
                max: 36,
                divisions: 24,
                onChanged: (v) => setState(() => fontSize = v),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 CHORD SECTION
            if (chord)
              _buildDrawerCard(
                child: Column(
                  children: [
                    /// Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _chordChecked,
                          activeColor: Colors.blueAccent,
                          onChanged: (value) {
                            setState(() {
                              _chordChecked = value!;
                              showChord = !showChord;
                            });
                          },
                        ),
                        const Text("Show Chords",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// Transpose
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Transpose",
                            style: TextStyle(color: Colors.white70)),
                        Row(
                          children: [
                            _circleButton(Icons.remove,
                                    () => setState(() => transpose--)),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                transpose.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _circleButton(Icons.add,
                                    () => setState(() => transpose++)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            /// 🔹 REPORT
            _buildDrawerCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.report_problem,
                      color: Colors.orangeAccent, size: 20),
                ),
                title: const Text("Report Error",
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  "Hla bia / Chord a palh mi chimnak",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String trailing,
    required Widget child,
  }) {
    return _buildDrawerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Text(
                trailing,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 18),
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
      child: child,
    );
  }
}
