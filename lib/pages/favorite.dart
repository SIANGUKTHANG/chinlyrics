import 'dart:convert';
import 'dart:io';
import 'package:chinlyrics/ads_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import '../constant.dart';
import '../notifications/detail.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  bool isAdsLoading = false;
  bool isConnected = false;
  bool raise = false;
  var data = [];
  String category = 'all';
  bool adReady = false;
  RewardedAd? _rewardedAd;
  int tapCount = 0;
  TextEditingController textEditingController = TextEditingController();
  var searchHistory = [];
  var item = [];

  // A BIAPI: 'late' in chiah ahcun Ad on lio ah a rawk sual tawn caah Nullable (?) in kan chiah
  BannerAd? bottomAds;

  @override
  void initState() {
    super.initState();
    readFavoriteFile();
 /*    bottomAds = BannerAd(
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
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {},
              onAdImpression: (ad) {},
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
              },
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                loadAd();
              },
              onAdClicked: (ad) {});

          setState(() {
            adReady = true;
          });
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> readFavoriteFile() async {
    try {
      const fileName = 'favorite';
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final path = File(filePath);
      if (await path.exists()) {
        final content = await path.readAsString();
        final List<dynamic> l = json.decode(content) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          favorites.clear(); // HIKA HI CHAP HRIMHRIM A HAU (A hlun kha a hloh hmasa lai)
          for (var element in l) {
            favorites.add(element);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    bottomAds?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Favorite Songs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomSheet: (isAdsLoading && bottomAds != null)
          ? SizedBox(
        // AdSize.banner.height a aiah a tanglei hi hmang
        height: bottomAds!.size.height.toDouble(),
        width: bottomAds!.size.width.toDouble(),
        child: AdWidget(ad: bottomAds!),
      )
          : const SizedBox.shrink(),
      // A THAR: Background ah dawh tukmi dark gradient kan hman
      body: favorites.isEmpty
      // Favorite ah zeihmanh a um lo lio i a lang dingmi (Empty State)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border, size: 80, color: Colors.white24),
            ),
            const SizedBox(height: 20),
            const Text(
              "Favorite Hla A Um Lo",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Na duhmi hla pawl kha heart (❤) icon hmet law hika ah an ra um lai.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      )
      // Favorite hla list pawl langhter ning
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          var fav = favorites[index];

          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
              ),
              title: Text(
                fav['title'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  fav['singer'] ?? 'Unknown Singer',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
              onTap: () {
                // Original Routing & Ad Logic
                tapCount++;
                if (adReady && tapCount > 1) {
                  tapCount = 0;
                  _rewardedAd?.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                    _navigateToDetail(fav);
                  });
                } else {
                  _navigateToDetail(fav);
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Code thiang tein a um nakhnga Navigation function tawi te in ka tuah
  void _navigateToDetail(Map<dynamic, dynamic> fav) {
    Navigator.of(context).push(MaterialPageRoute(builder:
      (context) => DetailsPage(
      title: fav['title'] ?? '',
      chord: fav['chord'] ?? false,
      singer: fav['singer'] ?? '',
      composer: fav['composer'] ?? '',
      verse1: fav['verse 1'] ?? '',
      verse2: fav['verse 2'] ?? '',
      verse3: fav['verse 3'] ?? '',
      verse4: fav['verse 4'] ?? '',
      verse5: fav['verse 5'] ?? '',
      songtrack: fav['songtrack'] ?? '',
      chorus: fav['chorus'] ?? '',
      endingChorus: fav['endingchorus'] ?? '',
    ))).then((_) {
     readFavoriteFile(); // Hmanthlak le Min a thar in a lang colh cang lai
    });;
  }
}