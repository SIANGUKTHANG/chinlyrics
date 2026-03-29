import 'dart:async';
import 'package:chinlyrics/laihlalyrics/model/song_model.dart';
import 'package:chinlyrics/musician/home.dart';
import 'package:chinlyrics/pages/offline_home.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';

import '../pages/bible/home.dart';
import '../pages/chawnghlang.dart';
import '../pages/khrihfa_hlabu.dart';
import 'detail.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  late Isar isar;
  final Box _recentBox = Hive.box('recentBox');

  // STATE VARIABLES
  bool _isSearching = false;
  List<SongModel> _searchResults = [];
  List<SongModel> _popularSongs = [];
  List<SongModel> _recentSongs = [];

  // ================= 1. CATEGORY THLENNAK (Na duhmi design te kha) =================
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Khrihfa Hlabu',
      'icon': Icons.library_music,
      'color': Colors.greenAccent
    },
    {
      'title': 'Chawnghlang',
      'icon': Icons.speaker_notes,
      'color': Colors.pinkAccent
    },
    {
      'title': 'Lai Bible',
      'icon': Icons.auto_stories,
      'color': Colors.blueAccent
    },
    {
      'title': 'Musician Note',
      'icon': Icons.music_note,
      'color': Colors.purpleAccent
    },
  ];

  @override
  void initState() {
    super.initState();
    isar = Isar.getInstance()!;
    _loadPopularSongs();
    _loadRecentSongs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularSongs() async {
    final popular =
        await isar.songModels.where().sortByLikesDesc().limit(5).findAll();
    if (mounted) {
      setState(() {
        _popularSongs = popular;
      });
    }
  }

  Future<void> _loadRecentSongs() async {
    if (_recentBox.isEmpty) return;

    List<Map<dynamic, dynamic>> recentsData =
        _recentBox.values.map((e) => Map<dynamic, dynamic>.from(e)).toList();
    recentsData
        .sort((a, b) => (b['viewedAt'] ?? 0).compareTo(a['viewedAt'] ?? 0));

    List<SongModel> loaded = [];
    for (var r in recentsData.take(10)) {
      String songId = r['id'];
      var song = await isar.songModels.filter().idEqualTo(songId).findFirst();
      if (song != null) loaded.add(song);
    }

    if (mounted) {
      setState(() {
        _recentSongs = loaded;
      });
    }
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await isar.songModels
        .filter()
        .group((q) => q
            .titleContains(query, caseSensitive: false)
            .or()
            .singerContains(query, caseSensitive: false)
            .or()
            .lyricsContains(query, caseSensitive: false))
        .findAll();

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _goToDetailAndSaveRecent(SongModel song) {
    FocusScope.of(context).unfocus();

    _recentBox.put(song.id, {
      'id': song.id,
      'viewedAt': DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongDetailPage(song: song)),
    ).then((_) {
      _loadRecentSongs();
    });
  }

  // ================= MODERN CARD DESIGN (ListTile Aiawh Tu) =================
  Widget _buildSongCard(SongModel song, {bool showLikes = false}) {
    bool isChord = song.isChord;
    bool hasAudio =
        song.soundtrack != null && song.soundtrack!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2), // Card background
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12, width: 0.5), // Tlang pan te
      ),
      child: InkWell(
        onTap: () => _goToDetailAndSaveRecent(song),
        borderRadius: BorderRadius.circular(15),
        // Hmeh tikah a shape ning in a mawi nakhnga
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. LEADING ICON BOX
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: isChord
                      ? Colors.blueAccent.withOpacity(0.15)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isChord ? Icons.piano : Icons.music_note,
                  color: isChord ? Colors.blueAccent : Colors.white70,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),

              // 2. TITLE & SINGER
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.singer,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Popular Songs caah Likes langhternak
                    if (showLikes) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.whatshot,
                              color: Colors.orangeAccent, size: 14),
                          const SizedBox(width: 4),
                          Text('${song.likes} Likes',
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ]
                  ],
                ),
              ),

              // 3. TRAILING ICONS (Audio Badge & Arrow)
              if (hasAudio) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic,
                      color: Colors.greenAccent, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white24, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Hla Kawlnak",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= SEARCH BAR =================
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    _runSearch(value);
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Hla min, satu, asiloah biafang...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            _runSearch('');
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.mic, color: Colors.blueAccent),
                          onPressed: () {},
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= DYNAMIC CONTENT =================
          Expanded(
            child:
                _isSearching ? _buildSearchResults() : _buildDefaultLibrary(),
          ),
        ],
      ),
    );
  }

  // ================= A: SEARCH RESULT LIST UI =================
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.white24),
            SizedBox(height: 15),
            Text("Hla na kawlmi a um lo.",
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSongCard(
            _searchResults[index]); // Card hmang in thlen cang
      },
    );
  }

  // ================= B: DEFAULT CATEGORY, POPULAR & RECENT UI =================
  Widget _buildDefaultLibrary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hla Phun (Browse)",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // CATEGORY GRID (Na duhmi design te kha)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.5,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return InkWell(
                onTap: () {
                  String title = cat['title'];
                  if (title == 'Khrihfa Hlabu') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const KhrihfaHlaBu()));
                  } else if (title == 'Chawnghlang') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChawngHlang()));
                  } else if (title == 'Lai Bible') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BiblePage()));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChordPage()));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cat['color'].withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat['icon'], color: cat['color'], size: 24),
                      const SizedBox(width: 8),
                      Text(cat['title'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // ================= POPULAR SONGS SECTION =================
          if (_popularSongs.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: Colors.orangeAccent, size: 22),
                SizedBox(width: 8),
                Text("Mipi Uar Bikmi (Popular)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _popularSongs.length,
              itemBuilder: (context, index) {
                // Card hmang in thlen cang, Likes langhternak he
                return _buildSongCard(_popularSongs[index], showLikes: true);
              },
            ),
            const SizedBox(height: 25),
          ],

          // ================= RECENT SONGS SECTION =================
          if (_recentSongs.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nihin Na Zohmi (Recent)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentBox.clear();
                      _recentSongs.clear();
                    });
                  },
                  child: const Text("Clear All",
                      style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentSongs.length,
              itemBuilder: (context, index) {
                return _buildSongCard(
                    _recentSongs[index]); // Card hmang in thlen cang
              },
            ),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }
}
