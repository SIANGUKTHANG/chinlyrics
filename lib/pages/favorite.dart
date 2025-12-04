
import 'package:chinlyrics/ads_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constant.dart';
import 'detail.dart';

// ignore: must_be_immutable
class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  bool isAdsLoading = false;
  bool isConnected = false;
  bool raise = false;
  var data = [];
  String category = 'all';
  bool adReady = false;
  late BannerAd banner;
  RewardedAd? _rewardedAd;
  int tapCount = 0;
  TextEditingController textEditingController = TextEditingController();
  var searchHistory = [];
  var item = [];

  late BannerAd bottomAds;

  @override
  void initState() {
    super.initState();
 /*   bottomAds = BannerAd(
      //ca-app-pub-6997241259854420~8257797802
      adUnitId:  AdHelper.homeBannerAdUnitId,
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
    loadAd();*/
  }


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
  void dispose() {
    // bottomAds.dispose();
    // _rewardedAd?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black87,
            leading: Container(),
            title: Text(
              'Favorite',
              style: GoogleFonts.vastShadow(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1),
            ),
          ),
          backgroundColor: Colors.black,
          bottomSheet: isAdsLoading?SizedBox(
              height: AdSize.banner.height.toDouble(),
              width: MediaQuery.of(context).size.width,
              child: AdWidget(
                ad: bottomAds,
              )):const SizedBox(),
          body: Column(
            children: [
              favorites.isEmpty
                  ? Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 50),
                  child: const Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              )
                  : Expanded(
                child: ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ListTile(
                              onTap: () {
                                tapCount++;
                                if (adReady && tapCount >= 3) {
                                  tapCount = 0;
                                  _rewardedAd?.show(
                                      onUserEarnedReward:
                                          (AdWithoutView ad, RewardItem reward) {
                                            Get.to(() =>DetailsPage(
                                              title: favorites[index]['title']??'',
                                              chord: favorites[index]['chord']??false,
                                              singer: favorites[index]['singer']??'',
                                              composer: favorites[index]['composer']??'',
                                              verse1: favorites[index]['verse 1']??'',
                                              verse2: favorites[index]['verse 2']??'',
                                              verse3: favorites[index]['verse 3']??'',
                                              verse4: favorites[index]['verse 4']??'',
                                              verse5: favorites[index]['verse 5']??'',
                                              songtrack: favorites[index]
                                              ['songtrack']??'',
                                              chorus: favorites[index]['chorus']??'',
                                              endingChorus: favorites[index]
                                              ['endingchorus']??'',
                                            ));
                                      });
                                  print( favorites[index]
                                  ['songtrack']);
                                }else{
                                  Get.to(() => DetailsPage(
                                    title: favorites[index]['title']??'',
                                    chord: favorites[index]['chord']??false,
                                    singer: favorites[index]['singer']??'',
                                    composer: favorites[index]['composer']??'',
                                    verse1: favorites[index]['verse 1']??'',
                                    verse2: favorites[index]['verse 2']??'',
                                    verse3: favorites[index]['verse 3']??'',
                                    verse4: favorites[index]['verse 4']??'',
                                    verse5: favorites[index]['verse 5']??'',
                                    songtrack: favorites[index]
                                    ['songtrack']??'',
                                    chorus: favorites[index]['chorus']??'',
                                    endingChorus: favorites[index]
                                    ['endingchorus']??'',
                                  ));
                                }
                               print( favorites[index]
                               ['songtrack']);
                              },
                              leading: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                              title: Text(
                                favorites[index]['title'],
                                style: GoogleFonts.zillaSlab(
                                    color: Colors.white),
                              ),
                              subtitle: Text(
                                favorites[index]['singer'],
                                style: GoogleFonts.beauRivage(
                                    color: Colors.white70),
                              ),
                            ),
                          ),
                          Container(
                            height: 0.2,
                            width:
                            MediaQuery.of(context).size.width / 1.5,
                            color: Colors.white,
                          )
                        ],
                      );
                    }),
              ),
              SizedBox(height: AdSize.banner.height.toDouble()),
            ],
          ),
        ),
      ),
    );
  }
}


