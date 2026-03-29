import 'dart:async';
import 'package:chinlyrics/laihlalyrics/model/song_model.dart';
import 'package:chinlyrics/laihlalyrics/upload.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:chinlyrics/laihlalyrics/user/user_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';

import '../comments/lyrics.dart';
import '../detail.dart';
import '../notification.dart';

IsarHomeFeedPageState? homeFeedState;

class IsarHomeFeedPage extends StatefulWidget {
  const IsarHomeFeedPage({super.key});

  @override
  State<IsarHomeFeedPage> createState() => IsarHomeFeedPageState();
}

class IsarHomeFeedPageState extends State<IsarHomeFeedPage> {
  late Isar isar;
  Timer? _debounce;
  List<SongModel> _displayedPosts = [];
  List<SongModel> _allPosts = [];
  bool _isAppBarVisible = true;
  final ScrollController _scrollController = ScrollController();
  bool _isFetching = false;
  bool _searchByLyrics = false;
  final Box _settingsBox = Hive.box('settingsBox'); // Timestamp save tuahnak
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final Set<String> postIds = {};
  final List<String> filters = [
    'All',
    'Gospel',
    'Ramhla',
    'Zunhla',
    'Christmas',
    'Kumthar',
    'Kawl hla',
  ];

  @override
  void initState() {
    super.initState();
    homeFeedState = this;
    isar = Isar.getInstance()!;
    _runFilter();
    _syncSongsFromFirebase();
  }

// ================= ISAR IN LAAKNAK (PAGINATION UM LO IN) =================
  Future<void> _fetchFromIsar() async {
    setState(() => _isFetching = true);

    try {
      final selected = _selectedFilter.toLowerCase();
      final isFiltering = _selectedFilter != 'All';
      final isSearching = _searchQuery.isNotEmpty;

      // Isar hmang in tlar khat tein kawlnak
      final songs = await isar.songModels
          .filter()

          // 1. Category Filter Logic
          .optional(isFiltering, (q) {
            if (selected == 'gospel') {
              return q
                  .categoryEqualTo('gospel', caseSensitive: false)
                  .or()
                  .categoryEqualTo('pathian-hla', caseSensitive: false);
            } else if (selected == 'zunhla') {
              return q
                  .categoryEqualTo('zunhla', caseSensitive: false)
                  .or()
                  .categoryEqualTo('zun-hla', caseSensitive: false);
            } else if (selected == 'ramhla') {
              return q
                  .categoryEqualTo('ramhla', caseSensitive: false)
                  .or()
                  .categoryEqualTo('ram-hla', caseSensitive: false);
            } else if (selected == 'christmas') {
              return q
                  .categoryEqualTo('christmas', caseSensitive: false)
                  .or()
                  .categoryEqualTo('christmas-hla', caseSensitive: false);
            } else if (selected == 'kumthar') {
              return q
                  .categoryEqualTo('kumthar', caseSensitive: false)
                  .or()
                  .categoryEqualTo('kumthar-hla', caseSensitive: false);
            } else if (selected == 'kawl hla') {
              return q.categoryEqualTo('Kawl hla',
                  caseSensitive:
                      false); // Na filter hlun ah 'Kawl hla' ti na tial caah
            } else if (selected == 'blog') {
              return q.categoryEqualTo('Blog', caseSensitive: false);
            } else {
              return q.categoryEqualTo(_selectedFilter, caseSensitive: false);
            }
          })

          // 2. Search Logic (Lyrics Switch zoh chihnak)
          .optional(isSearching, (q) {
            if (_searchByLyrics) {
              // Switch ON a si ahcun: Title, Singer le Lyrics ah a kawl lai
              return q.group((q2) =>
                  q2.lyricsContains(_searchQuery, caseSensitive: false));
            } else {
              // Switch OFF a si ahcun: Title le Singer lawng ah a kawl lai
              return q.group((q2) => q2
                  .titleContains(_searchQuery, caseSensitive: false)
                  .or()
                  .singerContains(_searchQuery, caseSensitive: false));
            }
          })

          // 3. A tlarmi zapi laak dih
          .sortByCreatedAtDesc()
          .findAll();

      setState(() {
        _allPosts = songs;
        _displayedPosts = List.from(_allPosts);
        _isFetching = false;
      });
    } catch (e) {
      if (kDebugMode) print("Isar data laak lio ah palhnak: $e");
      setState(() => _isFetching = false);
    }
  }

// ================= FIREBASE IN A THAR UMMI LAAKNAK (BACKGROUND SYNC) =================
  Future<void> _syncSongsFromFirebase() async {
    try {
      // 1. Hive chungin a hlan i Sync kan rak tuah lio caan laaknak
      int lastFetchMillis = _settingsBox.get('lastHlaSyncTime', defaultValue: 0);

      firestore.Query query = firestore.FirebaseFirestore.instance.collection('songs');

      // 2. A hlan ah a rak la bal cangmi a si ahcun (0 a si lo ahcun) a caan hmang in a thar lawng laaknak
      if (lastFetchMillis > 0) {
        query = query.where('updatedAt',
            isGreaterThan: firestore.Timestamp.fromMillisecondsSinceEpoch(
                lastFetchMillis));
      }

      var snapshot = await query.get();

      // A thar a um lo ahcun donghter (App a ran tuknak ding hrampi a si)
      if (snapshot.docs.isEmpty) return;

      print('Mah hi a thar a si: ${snapshot.docs.length}');
      int maxTimestamp = lastFetchMillis;

      await isar.writeTxn(() async {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAtTimestamp = data['createdAt'];
          final updatedAtTimestamp = data['updatedAt'];

          // Sync a tuah lio ah a thar bikmi caan kha theih peng a hau
          if (updatedAtTimestamp != null &&
              updatedAtTimestamp is firestore.Timestamp) {
            if (updatedAtTimestamp.millisecondsSinceEpoch > maxTimestamp) {
              maxTimestamp = updatedAtTimestamp.millisecondsSinceEpoch;
            }
          }

          String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
          List<dynamic> likedByArray = data['likedBy'] ?? [];
          bool checkIsLiked = likedByArray.contains(currentUserUid);

          // Isar ah a um cia maw check hmasa
          var existingSong =
              await isar.songModels.filter().idEqualTo(doc.id).findFirst();
          final song = existingSong ?? SongModel();

          song
            ..id = doc.id
            ..title = data['title'] ?? ''
            ..singer = data['singer'] ?? ''
            ..soundtrack = data['soundtrack']
            ..category = data['category'] ?? ''
            ..isChord = data['isChord'] ?? false
            ..lyrics = data['lyrics'] ?? ''
            ..uploaderId = data['uploaderId'] ?? ''
            ..type = data['type'] ?? 'hla'
            ..approved = data['approved'] ?? false
            ..likes = data['likes'] ?? 0
            ..comments = data['comments'] ?? 0
            ..createdAt = createdAtTimestamp is firestore.Timestamp
                ? createdAtTimestamp.millisecondsSinceEpoch
                : (createdAtTimestamp ?? 0)
            ..updatedAt = updatedAtTimestamp is firestore.Timestamp
                ? updatedAtTimestamp.millisecondsSinceEpoch
                : (updatedAtTimestamp ?? 0)
            ..isLikedByMe = checkIsLiked;

          await isar.songModels.put(song);
        }
      });

      // 3. Sync tlamtling tein a dih tikah Hive ah Caan Thar Bik kha save tuahnak
      _settingsBox.put('lastHlaSyncTime', maxTimestamp);

      _runFilter();
    } catch (e) {
      if (kDebugMode) print("Firebase Sync palhnak: $e");
    }
  }

// Filter asiloah Search thlen tikah
  void _runFilter() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchFromIsar();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    if (homeFeedState == this) homeFeedState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // Hlan i na Search TextField tangte ah hika hi va chap
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isAppBarVisible ? 56.0 : 0.0,
                child: AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  title: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 300), () {
                          _searchQuery = value;
                          _runFilter();
                        });
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _searchByLyrics
                            ? 'Lyrics chungah kawl...'
                            : 'Title asiloah Singer kawl...',
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontSize: 14),

                        // ================= HIKA HI KAN THLENG (Icon Button Switcher) =================
                        // ================= LAM 2: ICON SWITCHER (A dawh bik) =================
                        prefixIcon: Tooltip(
                          message: _searchByLyrics
                              ? "Title/Singer ah thleng"
                              : "Lyrics ah thleng",
                          child: IconButton(
                            icon: Icon(
                              _searchByLyrics ? Icons.lyrics : Icons.title,
                              // A on le off ning in Icon aa thleng lai
                              color: _searchByLyrics
                                  ? Colors.blueAccent
                                  : Colors.white54,
                              size: 22, // Size hme tein chiah khawh a si
                            ),
                            onPressed: () {
                              setState(() {
                                _searchByLyrics =
                                    !_searchByLyrics; // True/False aa thleng lai
                              });
                              if (_searchQuery.isNotEmpty) {
                                _runFilter();
                              }
                            },
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10), // Hika zong ka remh deuh
                      ),
                    ),
                  ),
                  actions: [
                    StreamBuilder<firestore.QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null
                          ? firestore.FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('notifications')
                              .where('isRead', isEqualTo: false)
                              .limit(
                                  10) // ================= HIKA HI CHAP =================
                              .snapshots()
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        int unreadCount = 0;
                        if (snapshot.hasData) {
                          unreadCount = snapshot.data!.docs.length;
                        }

                        return IconButton(
                          onPressed: () {
                            // Hika ah setState in 0 ah thlen a hau ti lo, Firebase nih a tuah cang lai
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Notifications()),
                            );
                          },
                          icon: Badge(
                            isLabelVisible: unreadCount > 0,
                            // 10 a phanh ahcun "10+" in a lang lai
                            label: Text(
                              unreadCount >= 10
                                  ? '10+'
                                  : unreadCount.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            backgroundColor: Colors.redAccent,
                            child: const Icon(Icons.notifications_none,
                                color: Colors.white54),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isAppBarVisible ? 56.0 : 0.0,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedFilter == filters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filters[index],
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white)),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: Colors.grey[900],
                          onSelected: (bool selected) {
                            setState(() => _selectedFilter = filters[index]);
                            _runFilter();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: _displayedPosts.isEmpty
                    ? Center(
                        child: const Text("Hla a um rih lo",
                            style: TextStyle(color: Colors.white54)),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {},
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          // Scroll thlak tikah a nuam (smooth) nakhnga
                          itemCount: _displayedPosts.length + 1,
                          // A tanglei loading hmunhma caah +1 kan chap
                          itemBuilder: (context, index) {
                            // ================= A TANGLEI BIK (BOTTOM) INDICATOR =================
                            if (index == _displayedPosts.length) {
                              // 1. Firebase in data a laak lio a si ahcun a tanglei ah Circular Loading a lang lai
                              if (_isFetching) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                          color: Colors.blueAccent,
                                          strokeWidth: 2.5),
                                    ),
                                  ),
                                );
                              }

                              // 3. A laak lio zong a si lo, a dih zong a dih rih lo ahcun a lawng in a um lai
                              else {
                                return const SizedBox(height: 50);
                              }
                            }

                            // Normal Post Card
                            final post = _displayedPosts[index];
                            return _buildPostCard(post, context, index);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String extractLyrics(String input) {
    // Remove chords like [C], [Am], [G7], etc.
    final noChords = input.replaceAll(RegExp(r'\[.*?\]'), '');

    // Clean extra spaces
    return noChords.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildPostCard(SongModel post, BuildContext context, int index) {
    bool isChord = post.isChord ?? false;
    String postType = post.type ?? 'hla';
    String categoryText = post.category ?? 'Gospel';

    String rawLyrics = post.lyrics ?? '';
    String previewLyrics =
        rawLyrics.replaceAll('{verse}', '').replaceAll('{chorus}', '').trim();
    int time = post.updatedAt ?? 0;
    String formattedTime = formatTime(time);

    Color catColor;
    switch (categoryText) {
      case 'Gospel' || 'pathian-hla':
        catColor = Colors.green;
        break;
      case 'Ramhla' || 'ram-hla':
        catColor = Colors.orange;
        break;
      case 'Zunhla||zun-hla':
        catColor = Colors.pinkAccent;
        break;
      case 'Christmas' || 'christmas-hla':
        catColor = Colors.redAccent;
        break;
      case 'Kumthar' || 'kumthar-hla':
        catColor = Colors.purpleAccent;
        break;
      case 'Kawl hla':
        catColor = Colors.cyan;
        break;
      case 'All':
        catColor = Colors.white;
        break;
      default:
        catColor = Colors.blueAccent;
    }

    return GestureDetector(
      onLongPress: () {
        _showActionDialog(context, post.id, post, index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: UserHeaderWidget(
                    uid: post.uploaderId ?? 'unknown_id',
                    timeText: formattedTime,
                    fallbackName: 'laihla lyrics user',
                  ),
                ),
                if (postType == 'blog') ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.deepPurpleAccent.withOpacity(0.5),
                          width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.article,
                            size: 12, color: Colors.deepPurpleAccent),
                        SizedBox(width: 4),
                        Text('BLOG',
                            style: TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (postType != 'blog') ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: catColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isChord ? Icons.music_note : Icons.menu_book,
                            size: 14, color: catColor),
                        const SizedBox(width: 4),
                        Text(categoryText,
                            style: TextStyle(
                                color: catColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ]
              ],
            ),

            const SizedBox(height: 15),

            // 1. TITLE HIGHLIGHT TUAHNAK
            _buildHighlightedText(
              post.title ?? 'No Title',
              _searchQuery, // TextField in an tialmi query kha kan pe
              const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 2),

            // 2. SINGER HIGHLIGHT TUAHNAK
            postType == 'blog'
                ? const SizedBox()
                : Row(
                    children: [
                      const Text("Satu: ",
                          style: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic)),
                      Expanded(
                        child: _buildHighlightedText(
                          post.singer ?? 'Unknown',
                          _searchQuery,
                          const TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 10),

            // 3. LYRICS PREVIEW HIGHLIGHT TUAHNAK (maxLines: 4 in)
            _buildHighlightedText(
              extractLyrics(previewLyrics),
              _searchQuery,
              const TextStyle(color: Colors.white, height: 1.5),
              maxLines: 4, // Tlar 4 lawng langhter ding
            ),

            const SizedBox(height: 8),

            // ================= 4. LINKS LE ICONS LANGHTERNAK =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // Text cu kehlei ah, Icon cu orhlei ah a thawn lai
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SongDetailPage(
                                  song: post,
                                )));
                  },
                  child: Text(
                    postType == 'blog'
                        ? 'Read More '
                        : isChord
                            ? "View with Chords"
                            : "See Full Lyrics",
                    style: const TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.w500),
                  ),
                ),

                // Audio le Chord Icon Kuang
                Row(
                  children: [
                    // Chord A Um Ahcun (Purple Color in)
                    if (post.isChord == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.purpleAccent.withOpacity(0.1),
                              width: 0.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.piano,
                                size: 14, color: Colors.purpleAccent),
                            SizedBox(width: 4),
                            Text("Chords",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.purpleAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                    // Chord le Soundtrack a pahnih in a um ahcun a karlak awng
                    if (post.isChord == true &&
                        post.soundtrack != null &&
                        post.soundtrack!.trim().isNotEmpty)
                      const SizedBox(width: 8),

                    // Soundtrack A Um Ahcun (Green Color in)
                    if (post.soundtrack != null &&
                        post.soundtrack!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.pinkAccent.withOpacity(0.3),
                              width: 0.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mic, size: 14, color: Colors.pinkAccent),
                            SizedBox(width: 4),
                            Text("Audio",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.pinkAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const Divider(color: Colors.white24, height: 30),

            // ================= 5. ACTION BUTTONS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                    post.isLikedByMe == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    "${post.likes}",
                    () => _toggleLike(post),
                    color:
                        post.isLikedByMe == true ? Colors.red : Colors.white54),
                _buildActionButton(
                    Icons.chat_bubble_outline, "${post.comments ?? 0}", () {
                  // HIKA AH UPLOADER ID KAN CHAP
                  showCommentBottomSheet(
                      context, post.id, post.title, post.uploaderId ?? '');

                }, color: Colors.white70),
                _buildActionButton(Icons.share, "Share", () {
                  _shareSongAsPdf(post);
                }, color: Colors.white70),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback function,
      {required Color color}) {return InkWell(
      onTap: function,
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white54))
        ]),
      ),
    );}

// ================= CAAN (TIME) LANGHTERNAK REMHMI =================
  String formatTime(int millis) {
    // 1. Firebase in a rami a lawng asiloah 1970 a si sual ahcun "Nihin" in hman tthan
    if (millis <= 0 || millis < 1000000000000) {
      // Milliseconds hi thongthong (trillions) in a um a hau, a tlawm tuk ahcun a hman lo ti a theih khawh
      return "Unknown time"; // Asiloah "Just now" ti zong in tuah khawh a si
    }

    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(date);

    // 2. Hmailei caan (Future) a si sual ahcun "Just now" in langhter
    if (diff.isNegative) return "Just now";

    // 3. Na duhmi format te
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? "1 day ago" : "${diff.inDays} days ago";
    }

    // A sau tuk cangmi cu a thla le a ni in langhter
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _toggleLike(SongModel post) async {
    // Current User ID laak hmasa
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserUid.isEmpty) {
      // Login tuah lomi an si ahcun Like tuah khawh a si lo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Like tuah dingin Login tuah a hau."),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final isLiked = post.isLikedByMe ?? false;

    // 1. UI le Isar ah a rang in thlennak
    setState(() {
      post.isLikedByMe = !isLiked;
      post.likes += isLiked ? -1 : 1;
    });

    await isar.writeTxn(() async {
      await isar.songModels.put(post);
    });

    // 2. Firebase ah nambat le ID Cazin thlennak
    try {
      await firestore.FirebaseFirestore.instance
          .collection('songs')
          .doc(post.id)
          .update({
        'likes': firestore.FieldValue.increment(isLiked ? -1 : 1),

        // ================= HIKA HI CHAP =================
        // Like tuah cia a si i a hmeh tthan ahcun Cazin chungin a min phiat (arrayRemove)
        // Like thar a hmeh ahcun Cazin chungah a min chap (arrayUnion)
        'likedBy': isLiked
            ? firestore.FieldValue.arrayRemove([currentUserUid])
            : firestore.FieldValue.arrayUnion([currentUserUid]),
      });
    } catch (e) {
      if (kDebugMode) print("Firebase Like thlennak ah palhnak: $e");
    }
  }

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
    }
    return pdfWidgets;
  }

  String sanitize(String input) {
    return input.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  void _showActionDialog(
      BuildContext context, String docId, SongModel data, int index) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isUploader = currentUser?.uid == data.uploaderId;
    final bool isAdmin = currentUser?.email == 'itrungrul@gmail.com';
    final bool canEdit = isUploader || isAdmin;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(data.title ?? 'Options'),
        message: const Text('Zeidah tuah na duh?'),
        actions: [
          if (canEdit)
            CupertinoActionSheetAction(
              onPressed: () async {
                // ================= A THAR IN REMHMI (SongModel to Map) =================
                Map<String, dynamic> songMap = {
                  'id': docId,
                  'title': data.title,
                  'singer': data.singer,
                  'soundtrack': data.soundtrack,
                  'category': data.category,
                  'isChord': data.isChord,
                  'lyrics': data.lyrics,
                  'type': data.type,
                };

                Navigator.pop(context); // Popup phih hmasa a tha

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UploadPage(
                            editSong: songMap))); // songMap kan kuat cang
                // =====================================================================
              },
              child: const Text('Edit Chord'),
            ),
          if (canEdit)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                try {
                  // 1. Firebase chung in a tak in phiahnak (Delete)
                  await firestore.FirebaseFirestore.instance
                      .collection('songs')
                      .doc(docId)
                      .delete();

                  // 2. Isar (Phone chung) in phiahnak
                  await isar.writeTxn(() async {
                    final song = await isar.songModels
                        .filter()
                        .idEqualTo(docId)
                        .findFirst();

                    if (song != null) {
                      await isar.songModels.delete(song.isarId);
                    }
                  });

                  // 3. UI chung in nunter tthannak (Hla a tlau colh lai)
                  setState(() {
                    _allPosts.removeWhere((p) => p.id == docId);
                    _displayedPosts.removeWhere((p) => p.id == docId);
                    postIds.remove(docId);
                  });
                } catch (e) {
                  if (kDebugMode) print("Firebase Delete palhnak: $e");
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ),
    );
  }

// ================= FEED CAAH HIGHLIGHT TUAHNAK =================
  Widget _buildHighlightedText(String text, String query, TextStyle style,
      {int? maxLines}) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(
            TextSpan(text: text.substring(start, indexOfMatch), style: style));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: style.copyWith(
          backgroundColor: Colors.yellowAccent.withOpacity(0.3),
          color: Colors.yellowAccent,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return RichText(
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      text: TextSpan(children: spans),
    );
  }
}
