import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../ads_manager.dart';
import 'detail.dart';
import 'edit_song.dart';

bool hasLoadedSongsOnce = false;

class OfflineHome extends StatefulWidget {
  const OfflineHome({super.key});

  @override
  State<OfflineHome> createState() => _OfflineHomeState();
}

class _OfflineHomeState extends State<OfflineHome> {
  final Box userBox = Hive.box('userBox');
  String category = 'all';
  List<dynamic> allSongs = [];
  List<dynamic> visibleSongs = [];
  int tapCount = 0;
  RewardedAd? _rewardedAd;
  bool adReady = false;
  bool isAdsLoading = false;
  late BannerAd banner;
  Timer? _debounce;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    readLocal();
    if (!hasLoadedSongsOnce) {
      hasLoadedSongsOnce = true;
      readAndRetrieve();
    }

/*    loadAd();
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
    )..load();*/
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
            onAdClicked: (ad) {},
          );

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

  // A DIKMI FETCH NING (1 Read in Metadata lak)
  Future<void> readAndRetrieve({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('Firebase in Metadata (part_1) lak a si...');
    }

    try {
      if (allSongs.isEmpty || forceRefresh) {
        // 1. 'metadata' document pakhat te lawng lak
        DocumentSnapshot indexDoc = await FirebaseFirestore.instance
            .collection('metadata')
            .doc('part_1')
            .get(const GetOptions(source: Source.serverAndCache));

        if (indexDoc.exists && indexDoc.data() != null) {
          Map<String, dynamic> data = indexDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> songsMap = data['songs_map'] ?? {};

          List<dynamic> newData = [];

          // 2. Map chung i data kha List ah thlen
          songsMap.forEach((key, value) {
            newData.add({
              'id': key,
              // Hla ID (Mah hi Detail Page ah kan ap lai)
              'title': value['title'] ?? 'Untitled',
              'singer': value['singer'] ?? 'Unknown artist',
              'chord': value['chord'] ?? false,
              'songtrack': value['track'] ?? '',
              // UI he aa mil nakhnga
              // Note: 'category' cu index ah a tel lo caah a tanglei ah filter kan remh tlawmpal lai
            });
          });

          // ABC in remhnak
          newData.sort((a, b) => (a["title"] ?? "")
              .toString()
              .toLowerCase()
              .compareTo((b["title"] ?? "").toString().toLowerCase()));

          if (!mounted) return;
          setState(() {
            allSongs = newData;
            visibleSongs = newData;
          });

          const fileName = 'laihlalyrics';
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$fileName');
          await compute(jsonEncode, newData).then((value) {
            return file.writeAsString(value);
          });

          debugPrint("Metadata in data thar lak le save a si cang.");
        }
      } else {
        debugPrint("Data aa thleng lo. Local data kan hmang ko lai.");
      }
    } catch (e) {
      debugPrint("Data check/lak lio ah palhnak a um: $e");
    }
  }

  Future<void> readLocal() async {
    const fileName = 'laihlalyrics';
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    try {
      if (await file.exists()) {
        final localData = json.decode(await file.readAsString()) as List;

        localData.sort((a, b) => (a["title"] ?? "")
            .toString()
            .toLowerCase()
            .compareTo((b["title"] ?? "").toString().toLowerCase()));

        setState(() {
          allSongs = localData;
          visibleSongs = localData;
        });
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  @override
  void dispose() {
    if (isAdsLoading) {
      banner.dispose();
    }
    _rewardedAd?.dispose();
    textEditingController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: isAdsLoading
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: AdSize.banner.height.toDouble(),
              width: MediaQuery.of(context).size.width,
              child: AdWidget(ad: banner),
            )
          : const SizedBox(height: 1),
      body: Column(
        children: [
          const SizedBox(height: 60),
          _buildSearchBar(),
          Expanded(
            child: visibleSongs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No songs found.",
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                        Text("Try searching something else.",
                            style: TextStyle(
                              color: Colors.white70,
                            )),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await readAndRetrieve(forceRefresh: true);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: visibleSongs.length,
                      itemBuilder: (context, index) {
                        final item = visibleSongs[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white10,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              onLongPress: () =>
                                  _showActionDialog(context, item['id'], item),
                              onTap: () {
                                tapCount++;
                                if (adReady && tapCount >= 2) {
                                  tapCount = 0;
                                  _rewardedAd?.show(
                                    onUserEarnedReward: (AdWithoutView ad,
                                        RewardItem rewardItem) {
                                      _navigateToDetail(item);
                                    },
                                  );
                                } else {
                                  _navigateToDetail(item);
                                }
                              },
                              leading: item['songtrack'] != null && item['songtrack'] != ''
                                  ? const Icon(Icons.mic, color: Colors.red)
                                  : const Icon(Icons.music_note,
                                      color: Colors.white),
                              title: Text(
                                "'${item['title'] ?? 'Unknown'}'",
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                item['singer'] ?? 'Unknown Artist',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: item['chord'] == true
                                  ? const Icon(Icons.piano, color: Colors.blue)
                                  : const SizedBox(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // BIAPI: Detail Page ah ID le Title lawng ap a si cang
  void _navigateToDetail(dynamic item) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=>
        DetailsPage(
          songId: item['id'], // <-- ID ap a si
          title: item['title'] ?? '', // <-- Title ap a si
          // Verse pawl ap a hau ti lo!
        )));

  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        const SizedBox(width: 5),
        Expanded(
          child: _buildSearchField(),
        ),
        const SizedBox(width: 10),
        // _buildCategoryDropdown(),
        const SizedBox(width: 10),
      ],
    );
  }

  TextFormField _buildSearchField() {
    return TextFormField(
      controller: textEditingController,
      maxLines: 1,
      cursorColor: Colors.white70,
      cursorHeight: 20,
      onChanged: (value) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();

        _debounce = Timer(const Duration(milliseconds: 100), () {
          _filterSongs(value, category);
        });
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        hintText: 'Search by title or singer',
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white38, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            textEditingController.clear();
            _filterSongs('', category);
          },
        ),
      ),
    );
  }

  void _filterSongs(String searchTerm, String currentCategory) {
    setState(() {
      visibleSongs = allSongs.where((element) {
        final title = (element['title'] ?? '').toString().toLowerCase();
        final singer = (element['singer'] ?? '').toString().toLowerCase();
        final searchLower = searchTerm.toLowerCase();

        bool matchesSearch =
            title.contains(searchLower) || singer.contains(searchLower);
        return matchesSearch;
        // Note: Category filtering cu atu lio ahcun ka phih rih, zeicahtiah Index ah category kan rak save lo.
      }).toList();
    });
  }

  // A BIAPI: Hika ah docId timi String in kan thlen cang
  void _showActionDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final bool isAdmin = currentUser?.email == 'itrungrul@gmail.com';

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(data['title'] ?? 'Options'),
        message: const Text('Zeidah tuah na duh?'),
        actions: [
          if (isAdmin)
            CupertinoActionSheetAction(
              onPressed: () async {
                firestore.DocumentSnapshot doc = await firestore
                    .FirebaseFirestore.instance
                    .collection('hla')
                    .doc(docId)
                    .get(const firestore.GetOptions(
                        source: firestore.Source.serverAndCache));
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditLyrics(
                      doc: doc,
                    ),
                  ),
                ).then((_) => readAndRetrieve(forceRefresh: true));
              },
              child: const Text('Edit Chord'),
            ),
          if (isAdmin)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                // docId hmangin hloh a si
                await FirebaseFirestore.instance
                    .collection('hla')
                    .doc(docId)
                    .delete();
                await firestore.FirebaseFirestore.instance
                    .collection('metadata')
                    .doc('part_1')
                    .update({
                  'songs_map.$docId': firestore.FieldValue.delete(),
                });
                readAndRetrieve(forceRefresh: true);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
