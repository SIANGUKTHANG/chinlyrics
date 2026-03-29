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
import 'add_chord.dart';
import 'chord_detail.dart';
import 'edit_chord.dart';

class ChordPage extends StatefulWidget {
  const ChordPage({super.key});

  @override
  State<ChordPage> createState() => _ChordPageState();
}

class _ChordPageState extends State<ChordPage> {
  String searchTerm = '';
  bool showSearch = false;
  bool showFavoritesOnly = false;
  bool adReady = false;
  bool isAdsLoading = false;
  late BannerAd banner;
  RewardedAd? _rewardedAd;
  final home = Hive.box('chord');

  List<dynamic> songs = [];
  List<dynamic> filter = [];
  List<String> favoriteIds = [];
  int tapCount = 0;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    readLocal();
    readAndRetrieve();
/*
    // Ads pawl a nung in on piak a si
    _loadBannerAd();
    loadAd();*/
  }

  // A THAR: 1 Read lawng in Metadata laknak
  Future<void> readAndRetrieve({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('Firebase in Metadata (metamusic) lak a si...');
    }

    try {
      if (forceRefresh) {
        DocumentSnapshot indexDoc = await FirebaseFirestore.instance
            .collection('metamusic')
            .doc('part_1')
            .get(const GetOptions(source: Source.serverAndCache));

        if (indexDoc.exists && indexDoc.data() != null) {
          Map<String, dynamic> data = indexDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> songsMap = data['songs_map'] ?? {};

          List<dynamic> newData = [];

          songsMap.forEach((key, value) {
            newData.add({
              'id': key,
              'title': value['title'] ?? value['t'] ?? 'Unknown',
              'singer': value['singer'] ?? value['a'] ?? 'Unknown Artist',
              'uploaderUid': value['uploaderUid'] ?? 'unknown',
            });
          });

          newData.sort((a, b) => (a["title"] ?? "")
              .toString()
              .toLowerCase()
              .compareTo((b["title"] ?? "").toString().toLowerCase()));

          setState(() {
            songs = newData;
            filter = newData;
          });
          const fileName = 'musician_chords';
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$fileName');

          await compute(jsonEncode, newData).then((value) {
            return file.writeAsString(value);
          });
          debugPrint("Metadata in data thar lak a tlamtling.");
        }
      }
    } catch (e) {
      debugPrint("Data check/lak lio ah palhnak a um: $e");
    }
  }

  Future<void> readLocal() async {
    const fileName = 'musician_chords';
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
          songs = localData;
          filter = localData;
        });
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  void _loadBannerAd() {
    banner = BannerAd(
      adUnitId: AdHelper.homeBannerAdUnitId,
      size: AdSize.fullBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => isAdsLoading = true),
        onAdFailedToLoad: (ad, err) {
          isAdsLoading = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  void loadAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadAd();
            },
          );
          setState(() {
            adReady = true;
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) => debugPrint('RewardedAd failed: $err'),
      ),
    );
  }

  void _loadFavorites() {
    final cached = home.get('musicianFavorites');
    if (cached != null && cached is List) {
      setState(() {
        favoriteIds = List<String>.from(cached.cast<String>());
      });
    }
  }

  void _toggleFavorite(String docId) {
    setState(() {
      if (favoriteIds.contains(docId)) {
        favoriteIds.remove(docId);
      } else {
        favoriteIds.add(docId);
      }
      home.put('musicianFavorites', favoriteIds);
    });
  }

  @override
  void dispose() {
    //banner.dispose();
    //_rewardedAd?.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // A hrampi rong cu a dum in
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showFavoritesOnly ? 'Favorite Chords' : 'Musician Notes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // Favorite a si ahcun a sen, a si lo ahcun a var in a lang lai
                color: showFavoritesOnly ? Colors.redAccent : Colors.white,
                fontSize: 16,
              ),
            ),
            if (songs.isNotEmpty)
              Text(
                'Total: ${songs.length} songs',
                style: TextStyle(fontSize: 11, color: Colors.purpleAccent.withOpacity(0.7)),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(showSearch ? Icons.close : Icons.search,
                color: Colors.purpleAccent), // Search icon rong thlen a si
            onPressed: () => setState(() {
              showSearch = !showSearch;
              if (!showSearch) {
                textEditingController.clear();
                searchTerm = '';
                _filterSongs('');
              }
            }),
          ),
          IconButton(
              icon: const Icon(Icons.add, color: Colors.purpleAccent),
              onPressed: () => _createNewChord(context)),
        ],
      ),
      bottomSheet: isAdsLoading
          ? Container(
        height: AdSize.banner.height.toDouble(),
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AdWidget(ad: banner),
      )
          : const SizedBox(height: 1),
      body: Column(
        children: [
          if (showSearch) _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.purpleAccent, // Loading rong
              backgroundColor: Colors.grey[900],
              onRefresh: () async {
                await readAndRetrieve(forceRefresh: true);
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> doc =
                  songs[index] as Map<String, dynamic>;
                  String docId = doc['id'];
                  bool isFav = favoriteIds.contains(docId);

                  if (showFavoritesOnly && !isFav) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    // Card rong kha Purple he aa tlak in a rawimi
                    color: Colors.purpleAccent.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      // Card tlang (border) zong Purple in
                      side: BorderSide(color: Colors.purpleAccent.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.purpleAccent.withOpacity(0.15),
                        child: Icon(
                          Icons.music_note,
                          // Status a langhning rong thlen a si
                          color :Colors.purpleAccent,
                        ),
                      ),
                      title: Text(doc['title'] ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['singer'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white54)),
                      trailing: IconButton(
                        icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.purpleAccent.withOpacity(0.5)),
                        onPressed: () => _toggleFavorite(docId),
                      ),
                      onTap: () {
                        tapCount++;
                        if (adReady && tapCount >= 2 && _rewardedAd != null) {
                          tapCount = 0;
                          _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
                            _navigateToDetail(doc);
                          });
                        } else {
                          _navigateToDetail(doc);
                        }
                      },
                      onLongPress: () => _showActionDialog(context, docId, doc),
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

  void _navigateToDetail(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChordDetailPage(
            title: data['title'] ?? '', songId: data['id'] ?? ''),
      ),
    );
  }

  void _createNewChord(BuildContext context) async {
    final titleController = TextEditingController();
    final singerController = TextEditingController();

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add New Chord'),
        content: Column(
          children: [
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: titleController,
              placeholder: 'Song Title',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: singerController,
              placeholder: 'Singer Name',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  singerController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Next', style: TextStyle(color: Colors.purpleAccent)),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddChordPage(
            title: titleController.text,
            singer: singerController.text,
            ytController: '',
            chordKey: 'C',
            edit: 'Add New Chord',
            chordsController: '',
          ),
        ),
      ).then((_) => readAndRetrieve(forceRefresh: true));
    }
  }

  void _showActionDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isUploader = currentUser?.uid == data['uploaderUid'];
    final bool isAdmin = currentUser?.email == 'itrungrul@gmail.com';
    final bool canEdit = isUploader || isAdmin;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(data['title'] ?? 'Options'),
        message: const Text('Zeidah tuah na duh?'),
        actions: [
          if (canEdit)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditChord(
                      title: data['title'] ?? '',
                      songId: data['id'],
                    ),
                  ),
                ).then((_) => readAndRetrieve(forceRefresh: true));
              },
              child: const Text('Edit Chord', style: TextStyle(color: Colors.purpleAccent)),
            ),
          if (canEdit)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('musicianChords')
                    .doc(docId)
                    .delete();
                await firestore.FirebaseFirestore.instance
                    .collection('metamusic')
                    .doc('part_1')
                    .update({
                  'songs_map.$docId': firestore.FieldValue.delete(),
                });
                readAndRetrieve(forceRefresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hloh (Delete) a si cang.')));
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.purpleAccent)),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withOpacity(0.05), // Search Bar rong thlen a si
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: _buildSearchField(),
    );
  }

  TextFormField _buildSearchField() {
    return TextFormField(
      controller: textEditingController,
      maxLines: 1,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.purpleAccent, // Cursor rong
      cursorHeight: 20,
      onChanged: (value) => _filterSongs(value),
      decoration: const InputDecoration(
        hintText: 'Hla min / Satu kawlnak...',
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
        icon: Icon(Icons.search, color: Colors.purpleAccent), // Search icon thlen
      ),
    );
  }

  void _filterSongs(String searchTerm) {
    setState(() {
      songs = filter.where((element) {
        final title = (element['title'] ?? '').toString().toLowerCase();
        final singer = (element['singer'] ?? '').toString().toLowerCase();
        final searchLower = searchTerm.toLowerCase();

        return title.contains(searchLower) || singer.contains(searchLower);
      }).toList();
    });
  }
}