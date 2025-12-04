import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chinlyrics/ads_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chord_mod/flutter_chord.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../constant.dart';
import 'chord.dart';
import 'khrifahlabu_slide.dart';

// Add a compile-time flag so ads are disabled by default during debugging.
// Re-enable ads at build/run with: --dart-define=SHOW_ADS=true
const bool kShowAds = bool.fromEnvironment('SHOW_ADS', defaultValue: false);

// ignore: must_be_immutable
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
  AudioPlayer player = AudioPlayer();
  late ScrollController _scrollController;
  bool _isExpanded = false;
  int transpose = 0;
  bool dropDown = false;
  bool checkScroll = false;
  bool isCheck = false;
  bool _chordChecked = false;

  bool favorite = false;
  bool isAdsLoading = false;

  // Make the banner nullable so code is safe when ads are disabled.
  BannerAd? bottomBanner;
  bool isConnected = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int random = Random().nextInt(4) + 1;

  bool downloading = false;
  double progress = 0.0;
  bool isDownloaded = false;
  bool alreadyAxist = false;

  int maxduration = 100;
  int currentpos = 0;
  String currentpostlabel = "00:00";
  String maxDurationlabel = "00:00";
  bool isplaying = false;
  bool f = true;
  bool audioplayed = false;
  late String urlPath;
  int currentIndex = 0;
  double fontSize = 14;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isScrolling = false;
  double speedScroll = 10;

  final List<double> speedOptions = [1, 3, 6, 10, 14, 17, 20];

  void loadInterstitialAd() {
    // Don't load interstitials when ads are disabled (debugging).
    if (!kShowAds) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {},
          );

          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> downloadFile(String uri, fileName) async {
    try {
      setState(() {
        downloading = true;
      });

      Directory? dir = await getTemporaryDirectory();
      // Directory? dir =  await getExternalStorageDirectory();
      String savePath = '${(dir.path)}/$fileName';
      //  String savePath = '$directory/$fileName';

      Dio dio = Dio();

      String urii = uri.split('/d/')[1].split('/')[0];

      dio.download(
        'https://drive.google.com/uc?export=view&id=$urii',
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (rcv, total) async {
          setState(() {
            var percentage = ((rcv / total) * 100).floorToDouble();
            progress = percentage / 100;
          });
          if (progress == 1.0) {
            setState(() {
              isDownloaded = true;
              downloads.put(fileName, [
                widget.title,
                widget.singer,
                savePath,
                widget.composer,
                widget.verse1,
                widget.chorus,
                widget.verse2,
                widget.verse3,
                widget.verse4,
                widget.verse5,
                widget.endingChorus
              ]);

              alreadyAxist = true;
              urlPath = savePath;
            });
            // preload audio so it plays instantly
            await player.setSourceDeviceFile(savePath);
          }
        },
      );
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'You need internet connection'
              '\n to download',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      alreadyAxist = false;
    }
  }

  checkTrack() async {
    Directory dir = await getTemporaryDirectory();
    String savePath = '${dir.path}/${widget.title}${widget.singer}.mp3';

    File file = File(savePath);

    if (await file.exists()) {
      setState(() {
        alreadyAxist = true;
        urlPath = savePath;
      });

      // PRELOAD AUDIO SOURCE
      await player.setSourceDeviceFile(savePath);
    }
  }

  @override
  void initState() {
    checkTrack();
    _scrollController = ScrollController();

    player.onDurationChanged.listen((Duration event) {
      maxduration = event.inMilliseconds;

      //generating the duration label
      int shours = Duration(milliseconds: maxduration).inHours;
      int sminutes = Duration(milliseconds: maxduration).inMinutes;
      int sseconds = Duration(milliseconds: maxduration).inSeconds;

      int rminutes = sminutes - (shours * 60);
      int rseconds = sseconds - (sminutes * 60 + shours * 60 * 60);

      maxDurationlabel = "$rminutes:$rseconds";
    });

    player.onPositionChanged.listen((Duration event) {
      currentpos =
          event.inMilliseconds; //get the current position of playing audio

      //generating the duration label
      int shours = Duration(milliseconds: currentpos).inHours;
      int sminutes = Duration(milliseconds: currentpos).inMinutes;
      int sseconds = Duration(milliseconds: currentpos).inSeconds;

      int rminutes = sminutes - (shours * 60);
      int rseconds = sseconds - (sminutes * 60 + shours * 60 * 60);

      currentpostlabel = "$rminutes:$rseconds";

      setState(() {
        //refresh the UI
      });
    });

    OrientationHelper()
        .setPreferredOrientations([DeviceOrientation.portraitUp]);

    /*     bottomBanner = BannerAd(

      adUnitId: AdHelper.detailBannerAdUnitId,//'ca-app-pub-6997241259854420/9686503852',

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

     loadInterstitialAd();
*/
    favorite = favorites.any((song) => song['title'] == widget.title);
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    _scrollController.dispose();
    bottomBanner?.dispose();
    // Only interact with ad objects when ads are enabled.
/*    if (kShowAds) {
      if (_isInterstitialAdReady && random == 2) {
        _interstitialAd?.show();
      }
      // Use null-aware dispose to avoid disposing an uninitialized banner.

      _interstitialAd?.dispose();
    }*/
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
          key: _scaffoldKey,
            appBar: AppBar(
              leading: const SizedBox(),
              // centerTitle: true,
              title: Text(
                'title : ${widget.title}',
                style: GoogleFonts.aldrich(
                    color: Colors.white,
                    fontStyle: FontStyle.normal,
                    fontSize: 14),
              ),
              actions: [
                GestureDetector(

                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => LyricsViewer(
                                title: widget.title,
                                verse1: widget.verse1,
                                verse2: widget.verse2,
                                verse3: widget.verse3,
                                verse4: widget.verse4,
                                verse5: widget.verse5,
                                endingChorus: widget.endingChorus,
                                chorus: widget.chorus,
                              )));
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.slideshow,
                        color: Colors.white,
                      ),
                    ),),
                GestureDetector(
                    onTap: () {
                      if (favorite) {
                        setState(() {
                          favorites.removeWhere(
                              (song) => song['title'] == widget.title);
                          removeFavoriteData(widget.title);

                          favorite = false;
                        });
                      } else {
                        setState(() {
                          addFavoriteData({
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
                          });
                          favorites.add({
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
                            'endingchorus': widget.endingChorus
                          });

                          favorite = true;
                        });
                      }
                    },
                    child: favorite
                        ? const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                        )
                        : const Icon(
                            Icons.favorite_border,
                            color: Color.fromRGBO(255, 255, 255, 1),
                          )),
                GestureDetector(onTap:(){
                // i want to open whenn click here
                  _scaffoldKey.currentState!.openEndDrawer();

                }, child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.settings),
                ))
              ],
              bottom: PreferredSize(
                preferredSize:
                    alreadyAxist ? const Size.fromHeight(20) : Size.zero,
                child: alreadyAxist
                    ? Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              Text(currentpostlabel.toString()),
                              Expanded(
                                child: Slider(
                                  activeColor: Colors.red,
                                  inactiveColor: Colors.grey,
                                  value: double.parse(currentpos.toString()),
                                  min: 0,
                                  max: double.parse(maxduration.toString()),
                                  divisions: maxduration,
                                  label: currentpostlabel,
                                  onChanged: (value) async {
                                    int seekval = value.round();
                                    player
                                        .seek(Duration(milliseconds: seekval));
                                    setState(() {
                                      currentpos = seekval;
                                    });
                                  },
                                ),
                              ),
                              Text(maxDurationlabel.toString()),
                            ],
                          ),
                        ),
                      )
                    : downloading
                    ? LinearProgressIndicator(

                  backgroundColor: Colors.grey,
                  color: Colors.pink,
                  value: (progress * 100) > 5
                      ? progress
                      : 0.10, // 0.0 to 1.0
                ): const SizedBox(),
              ),
            ),
            endDrawer:   Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Settings",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    // 📌 Scroll Speed
                    Text("Scroll Speed: ${speedScroll.toInt()}"),
                    SizedBox(
                    //  height: 15,
                      child: Slider(
                        value: speedScroll,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (v) => setState(() => speedScroll = v),

                      ),
                    ),
                    const Divider(),

                    // 📌 Font Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Font Size"),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (fontSize > 12) {
                                  setState(() => fontSize--);

                                }
                              },
                            ),
                            Text(fontSize.toInt().toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (fontSize < 36) {
                                  setState(() => fontSize++);

                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),

                    const Divider(),

                    // 📌 Change Chord Button
                    ListTile(
                      leading: const Icon(Icons.music_note),
                      title: const Text("Change Chords"),
                      onTap: () {
                        Navigator.pop(context);
                        // add your chord transposer
                      },
                    ),

                    // 📌 Download Track
                    ListTile(
                      onTap: alreadyAxist? (){ Navigator.pop(context);}: ()async {
    await downloadFile(widget.songtrack,
    '${widget.title + widget.singer}.mp3');
    Navigator.pop(context);},
                      leading: const Icon(Icons.download),
                      title: const Text("Download Track"),



                    ),

                    // 📌 Info
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text("About Song"),
                      onTap: () {},
                    )
                  ],
                ),
              ),
            ),
            bottomSheet:
                // Only show the ad widget when ads are enabled and banner exists.
                (isAdsLoading && bottomBanner != null)
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: AdSize.banner.height.toDouble(),
                        width: MediaQuery.of(context).size.width,
                        child: AdWidget(
                          ad: bottomBanner!,
                        ))
                    : Container(
                        height: 1,
                      ),
            floatingActionButton: _isScrolling
                ? FloatingActionButton(
                    backgroundColor: Colors.transparent,
                    onPressed: _toggleAutoScroll,
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.green,
                    ),
                  )
                : alreadyAxist
                    ? Card(
                        color: Colors.red.shade900,
                        child: IconButton(
                          onPressed: () async {
                            if (!isplaying) {
                              await player.setSourceDeviceFile(urlPath);
                              await player.resume();

                              setState(() {
                                isplaying = true;
                                audioplayed = true;
                              });
                            } else {
                              player.pause();
                              setState(() {
                                isplaying = false;
                                audioplayed = false;
                              });
                            }
                          },
                          icon: Icon(
                            isplaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      )
                    : downloading
                        ? SizedBox(
                            height: 60,
                            width: 100,
                            child: Card(
                              color: Colors.red.shade900,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      backgroundColor: Colors.grey,
                                      color: Colors.green,
                                      value: (progress * 100) > 5
                                          ? progress
                                          : 0.10, // 0.0 to 1.0
                                    ),
                                  ),

                                  // Text inside the circle
                                  Center(
                                    child: Text(
                                      "    ${(progress * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : widget.songtrack == ''
                            ? const SizedBox()
                            : Card(
                                color: Colors.red.shade900,
                                child: TextButton.icon(
                                    onPressed: () async {
                                      await downloadFile(widget.songtrack,
                                          '${widget.title + widget.singer}.mp3');
                                    },
                                    label: const Text(
                                      'Track',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(
                                      Icons.cloud_download,
                                      color: Colors.green,
                                    )),
                              ),
            body: SlidingUpPanel(
                color: Colors.transparent,
                body: SingleChildScrollView(
                  controller: _scrollController,
                  child: GestureDetector(
                    onLongPress: () => settings(
                      context,
                    ),
                    onDoubleTap: () => _toggleAutoScroll(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          widget.composer == ''
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: AutoSizeText(
                                    'Phan : ${widget.composer}',
                                    style: GoogleFonts.alumniSans(
                                        letterSpacing: 2,
                                        color: Colors.white,
                                        fontStyle: FontStyle.normal,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                          widget.singer == ''
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: AutoSizeText(
                                    'Sa      : ${widget.singer}',
                                    style: GoogleFonts.alumniSans(
                                        letterSpacing: 1,
                                        color: Colors.white,
                                        fontStyle: FontStyle.normal,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                          const SizedBox(
                            height: 10,
                          ),
                          Chords(
                            vpadding: MediaQuery.of(context).size.width ~/ 4,
                            cpadding: MediaQuery.of(context).size.width ~/ 3,
                            verse: widget.verse1,
                            chorus: widget.chorus,
                            ending: widget.endingChorus,
                            showChord: _isExpanded,
                            scrollSpeed: transpose,
                            fontSize: fontSize,
                          ),
                          Chords(
                            vpadding: MediaQuery.of(context).size.width ~/ 4,
                            cpadding: MediaQuery.of(context).size.width ~/ 3,
                            verse: widget.verse2,
                            chorus: widget.chorus,
                            ending: widget.endingChorus,
                            showChord: _isExpanded,
                            scrollSpeed: transpose,
                            fontSize: fontSize,
                          ),
                          Chords(
                            vpadding: MediaQuery.of(context).size.width ~/ 4,
                            cpadding: MediaQuery.of(context).size.width ~/ 3,
                            verse: widget.verse3,
                            chorus: widget.chorus,
                            ending: widget.endingChorus,
                            showChord: _isExpanded,
                            scrollSpeed: transpose,
                            fontSize: fontSize,
                          ),
                          Chords(
                            vpadding: MediaQuery.of(context).size.width ~/ 4,
                            cpadding: MediaQuery.of(context).size.width ~/ 3,
                            verse: widget.verse4,
                            chorus: widget.chorus,
                            ending: widget.endingChorus,
                            showChord: _isExpanded,
                            scrollSpeed: transpose,
                            fontSize: fontSize,
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 10.0),
                            padding: const EdgeInsets.all(6.0),
                            child: widget.endingChorus == ''
                                ? Container()
                                : LyricsRenderer(
                                    showChord: _isExpanded,
                                    lyrics: widget.endingChorus,
                                    textStyle: GoogleFonts.akayaKanadaka(
                                        color: Colors.white70,
                                        fontSize: fontSize *
                                            MediaQuery.of(context)
                                                .textScaleFactor,
                                        fontStyle: FontStyle.normal),
                                    chordStyle:
                                        const TextStyle(color: Colors.green),
                                    lineHeight: 0,
                                    widgetPadding: 100,
                                    transposeIncrement: transpose,
                                    onTapChord: () {},
                                  ),
                          ),
                          const SizedBox(
                            height: 300,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                panelBuilder: (controller) {
                  return widget.chord == false
                      ? const SizedBox()
                      //
                      : Container(
                          decoration: const BoxDecoration(
                              color: Colors.black87,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            // padding: const EdgeInsets.symmetric(vertical: 16.0),
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _chordChecked,
                                        onChanged: (value) {
                                          setState(() {
                                            _chordChecked = value!;
                                            _isExpanded = !_isExpanded;
                                          });
                                        },
                                      ),
                                      const Text('chord',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                          padding: const EdgeInsets.all(2),
                                          onPressed: () {
                                            setState(() {
                                              transpose--;
                                            });
                                          },
                                          icon: const Icon(Icons.remove)),
                                      Text(
                                        transpose.toString(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      IconButton(
                                          padding: const EdgeInsets.all(2),
                                          onPressed: () {
                                            setState(() {
                                              transpose++;
                                            });
                                          },
                                          icon: const Icon(Icons.add)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                }));

  }

  void settings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scroll speed: ${speedScroll.toInt()}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 1,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12.0),
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
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: () {
                            if (fontSize > 12) {
                              setState(() {
                                fontSize--;
                              });
                            }
                          }),
                      const Text(
                        'FontSize',
                        style: TextStyle(fontSize: 12),
                      ),
                      IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () {
                            if (fontSize < 36) {
                              setState(() {
                                fontSize++;
                              });
                            }
                            if (fontSize == 36) {
                              setState(() {
                                fontSize = 12;
                              });
                            }
                          }),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Check if widget is still mounted before calling setState
                    if (mounted) {
                      setState(() {});
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleAutoScroll() {
    if (_isScrolling) {
      _scrollController.jumpTo(_scrollController.offset);
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _isScrolling = false;
        });
      }
    } else {
      if (!_scrollController.hasClients) return;
      if (mounted) {
        // Check if widget is still mounted
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
        // IMPORTANT: Check if widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    }
  }
}
