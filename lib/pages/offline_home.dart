import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:chinlyrics/ads_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constant.dart';
import 'detail.dart';

bool hasLoadedSongsOnce = false;

// ignore: must_be_immutable
class OfflineHome extends StatefulWidget {
  OfflineHome({super.key});

  var listData = [];

  @override
  State<OfflineHome> createState() => _OfflineHomeState();
}

class _OfflineHomeState extends State<OfflineHome> {
  var data = [];
  String category = 'all';
  bool isAdsLoading = false;
  bool isLoading = false;
  bool isConnected = false;
  bool raise = false;
  bool adReady = false;
  int random = Random().nextInt(4) + 1;
  late BannerAd banner;
  RewardedAd? _rewardedAd;
  int tapCount = 0;
  TextEditingController textEditingController = TextEditingController();
  var searchHistory = [];
  int updateList = 0;

  /// Loads a rewarded ad.
  void loadAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
              onAdShowedFullScreenContent: (ad) {},
              // Called when an impression occurs on the ad.
              onAdImpression: (ad) {},
              // Called when the ad failed to show full screen content.
              onAdFailedToShowFullScreenContent: (ad, err) {
                // Dispose the ad here to free resources.
                ad.dispose();
              },
              // Called when the ad dismissed full screen content.
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                loadAd();
              },
              // Called when a click is recorded for an ad.
              onAdClicked: (ad) {});

          setState(() {
            adReady = true;
          });

          // Keep a reference to the ad so you can show it later.
          _rewardedAd = ad;
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  @override
  void initState() {
/*
  loadAd();

    banner = BannerAd(
      adUnitId: AdHelper.homeBannerAdUnitId,
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
*/

    readLocal();
    if (!hasLoadedSongsOnce) {
      hasLoadedSongsOnce = true;
      checkData();
    }

    super.initState();
  }

  Future<void> checkData() async {
    const fileName = 'hla';
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    try {
      // 1. Load from local file immediately
      if (await file.exists()) {
        final localData = json.decode(await file.readAsString()) as List;

        // fetch from API
        final response = await http.get(
            Uri.parse('https://laihlalyrics.itrungrul.com/api/songs/length'));
        final data = jsonDecode(response.body);

        int newLength = data['length'];

        // compare
        bool hasChanged = localData.length != newLength;
        if(hasChanged){
          readAndRetrieve();
        }

      } else {
        readAndRetrieve();
      }
    } catch (e) {
      readLocal();
      debugPrint("Failed to read or download JSON: $e");
    }
  }

  Future<void> readAndRetrieve() async {
 setState(() {
   isLoading = true;
 });
    const fileName = 'hla';
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    try {

      // 2. Download latest version in background
      await Dio().download(
        url, // Make sure you defined this as your server file URL
        filePath,
      );

      // 3. Reload after successful download
      final newData = json.decode(await file.readAsString()) as List;

      newData.sort((a, b) =>
          a["title"].toLowerCase().compareTo(b["title"].toLowerCase()));

      setState(() {
        widget.listData = newData;
        data = newData;
        isLoading = false;
      });

      debugPrint("Data updated from latest download.");
    } catch (e) {
      debugPrint("Failed to read or download JSON: $e");
     setState(() {
       isLoading = false;
     });
    }
  }

  Future<void> readLocal() async {
    if (kDebugMode) {
      print('call local');
    }
    const fileName = 'hla';
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    try {
      // 1. Load from local file immediately
      if (await file.exists()) {
        final localData = json.decode(await file.readAsString()) as List;

        localData.sort((a, b) =>
            a["title"].toLowerCase().compareTo(b["title"].toLowerCase()));

        setState(() {
          widget.listData = localData;
          data = localData;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _filterJsonData(String searchTerm, category) {
    setState(() {
      widget.listData = data.where((element) {
        final categ = element['category'];
        final title = element['title'].toLowerCase();
        final singer = element['singer'].toLowerCase();
        final searchLower = searchTerm.toLowerCase();

        return category == 'all'
            ? title.contains(searchLower) || singer.contains(searchLower)
            : (title.contains(searchLower) || singer.contains(searchLower)) &&
                categ.contains(category);
      }).toList();
    });
  }

  @override
  void dispose() {
    // banner.dispose();
    // _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: SearchBar(
          onChanged: (value) {
            _filterJsonData(value, category);
          },
          hintText: 'title or singer ',
          hintStyle: WidgetStateProperty.all(GoogleFonts.alike(fontSize: 20)),
          trailing: [
            DropdownButton<String>(
              value: category,
              icon:
                  const Icon(Icons.filter_list_rounded, color: Colors.white70),
              style: const TextStyle(color: Colors.white70),
              underline: Container(),
              onChanged: (String? newValue) {
                setState(() {
                  category = newValue!;

                  if (category == 'all') {
                    widget.listData = data;
                  } else {
                    widget.listData =
                        data.where((e) => e['category'] == category).toList();
                  }
                });
              },
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Songs')),
                DropdownMenuItem(
                    value: 'pathian-hla', child: Text('Pathian Hla')),
                DropdownMenuItem(
                    value: 'christmas-hla', child: Text('Christmas Hla')),
                DropdownMenuItem(
                    value: 'kumthar-hla', child: Text('Kumthar Hla')),
                DropdownMenuItem(
                    value: 'thitumnak-hla', child: Text('Thitum Hla')),
                DropdownMenuItem(value: 'ram-hla', child: Text('Ram Hla')),
                DropdownMenuItem(value: 'zun-hla', child: Text('Zun Hla')),
                DropdownMenuItem(
                    value: 'hladang', child: Text('Hla Dang Dang')),
              ],
            )
          ],
        ),
      ),
      bottomSheet: isAdsLoading
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: AdSize.banner.height.toDouble(),
              width: MediaQuery.of(context).size.width,
              child: AdWidget(
                ad: banner,
              ))
          : Container(
              height: 1,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          checkData();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Expanded(
                    child: ListView.builder(
                        itemCount: widget.listData.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListTile(
                                  onTap: () {
                                    tapCount++;
                                    if (adReady && tapCount >= 3) {
                                      tapCount = 0;
                                      _rewardedAd?.show(onUserEarnedReward:
                                          (AdWithoutView ad,
                                              RewardItem rewardItem) {
                                        // Reward the user for watching an ad.
                                        Get.to(()=>DetailsPage(
                                          title: widget.listData[index]
                                              ['title'],
                                          chord: widget.listData[index]
                                              ['chord'],
                                          singer: widget.listData[index]
                                              ['singer'],
                                          composer: widget.listData[index]
                                              ['composer'],
                                          verse1: widget.listData[index]
                                              ['verse1'],
                                          verse2: widget.listData[index]
                                              ['verse2'],
                                          verse3: widget.listData[index]
                                              ['verse3'],
                                          verse4: widget.listData[index]
                                              ['verse4'],
                                          verse5: widget.listData[index]
                                              ['verse5'],
                                          songtrack: widget.listData[index]
                                              ['songtrack'],
                                          chorus: widget.listData[index]
                                              ['chorus'],
                                          endingChorus: widget.listData[index]
                                              ['endingchorus'],
                                        ));
                                      });
                                    } else {
                                      Get.to(()=>DetailsPage(
                                        title: widget.listData[index]
                                                ['title'] ??
                                            '',
                                        chord: widget.listData[index]
                                                ['chord'] ??
                                            false,
                                        singer: widget.listData[index]
                                                ['singer'] ??
                                            '',
                                        composer: widget.listData[index]
                                                ['composer'] ??
                                            '',
                                        verse1: widget.listData[index]
                                                ['verse1'] ??
                                            '',
                                        verse2: widget.listData[index]
                                                ['verse2'] ??
                                            '',
                                        verse3: widget.listData[index]
                                                ['verse3'] ??
                                            '',
                                        verse4: widget.listData[index]
                                                ['verse4'] ??
                                            '',
                                        verse5: widget.listData[index]
                                                ['verse5'] ??
                                            '',
                                        songtrack: widget.listData[index]
                                                ['songtrack'] ??
                                            '',
                                        chorus: widget.listData[index]
                                                ['chorus'] ??
                                            '',
                                        endingChorus: widget.listData[index]
                                                ['endingchorus'] ??
                                            "",
                                      ));
                                    }
                                  },
                                  leading:
                                      widget.listData[index]['songtrack'] != ''
                                          ? const Icon(
                                              Icons.mic_external_on_sharp,
                                              color: Colors.red,
                                            )
                                          : const Icon(
                                              Icons.music_note,
                                              color: Colors.white,
                                            ),
                                  title: Text(
                                    "'${widget.listData[index]['title']}'",
                                    style: GoogleFonts.zillaSlab(
                                        color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    widget.listData[(index)]['singer'],
                                    style: GoogleFonts.beauRivage(
                                        color: Colors.white70),
                                  ),
                                  trailing: widget.listData[index]['chord']
                                      ? const Icon(Icons.piano)
                                      : const SizedBox(),
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
            SizedBox(height: AdSize.banner.height.toDouble()),
          ],
        ),
      ),
    );
  }
}
