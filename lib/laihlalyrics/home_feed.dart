/*
import 'dart:async';
import 'package:chinlyrics/laihlalyrics/upload.dart';
import 'package:chinlyrics/laihlalyrics/user/user_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'comment_ui.dart';
import 'detail.dart';
import 'notification.dart';

HomeFeedPageState? homeFeedState;

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => HomeFeedPageState();
}

class HomeFeedPageState extends State<HomeFeedPage> {
  final Box _songsBox = Hive.box('songsBox');
  final Box _likedBox = Hive.box('likedBox');
  Timer? _debounce;
  List<Map<String, dynamic>> _displayedPosts = [];
  List<Map<String, dynamic>> _allPosts = [];

  final ScrollController _scrollController = ScrollController();
  firestore.DocumentSnapshot? _lastDocument;
  bool _isFetching = false;
  bool _hasMore = true;
  late VoidCallback _scrollListener;

  String _selectedFilter = 'All';
  String _searchQuery = '';
  final Set<String> postIds = {};
  final List<String> filters = [
    'All',
    'Gospel',
    'Blog',
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
    _loadFromHive();
    _fetchSongsFromFirebase();

    _scrollListener = () {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 400 &&
          !_isFetching &&
          _hasMore) {
        _fetchSongsFromFirebase(isNextPage: true);
      }
    };
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();

    // Page a thih tikah theihternak thianh
    if (homeFeedState == this) homeFeedState = null;
    super.dispose();
  }

  // =========================================================================
  // NA RUAHNING BANTUK IN LOCAL IN UI UPDATE TUAHNAK (A THAR KAN CHAP MI)
  // =========================================================================
// 1. Hla thar thun tikah
  void insertNewPost(Map<String, dynamic> newPost) {
    if (!mounted) return;
    setState(() {
      if (!postIds.contains(newPost['id'])) {
        _allPosts.insert(0, newPost); // A cunglei bik ah thun
        postIds.add(newPost['id']);
        _runFilter(); // UI mawi tein a thleng lai
      }
    });

    // Hive ah save tuah a hau ti lo. App on/Refresh tikah Firebase in a thiangmi a ra lai.

    // Scroll kha a cunglei bik ah cawiter
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 2. Hla remh (Edit) tikah
  void updatePostLocally(Map<String, dynamic> updatedPost) {
    if (!mounted) return;
    setState(() {
      int index = _allPosts.indexWhere((p) => p['id'] == updatedPost['id']);
      if (index != -1) {
        _allPosts[index] = updatedPost; // A hlun kha a thar in phih
        _runFilter();
      }
    });

    // Hive ah save tuah a hau ti lo.
  }

  void _loadFromHive() {
    if (_songsBox.isNotEmpty) {
      List<Map<String, dynamic>> localSongs =
          _songsBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

      localSongs.sort(
          (a, b) => (b['createdAtInt'] ?? 0).compareTo(a['createdAtInt'] ?? 0));

      for (var song in localSongs) {
        if (song['id'] != null) {
          postIds.add(song['id']);
        }
      }

      setState(() {
        _allPosts = localSongs;
        _displayedPosts = localSongs;
      });
      _runFilter();
    }
  }

// ================= 3. FIREBASE IN DATA LAAKNAK =================
  Future<void> _fetchSongsFromFirebase({bool isNextPage = false}) async {
    if (_isFetching || !_hasMore || !mounted) return;
    setState(() => _isFetching = true);

    int fetchLimit = 5;

    try {
      firestore.Query query = firestore.FirebaseFirestore.instance
          .collection('songs')
          .orderBy('updatedAt', descending: true)
          .limit(fetchLimit);

      if (isNextPage && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      var snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isFetching = false;
        });
        return;
      }

      // ================= A BIAPI BIK REMHNAK =================
      // Hla 5 na laak ah, 5 a tlin lo (tahchunhnak: 3 lawng a phan) ahcun a dong cang ti na theih khawh
      bool hasMoreData = snapshot.docs.length == fetchLimit;

      _lastDocument = snapshot.docs.last;

      if (!isNextPage) {
        _allPosts.clear();
        _displayedPosts.clear();
        postIds.clear();
      }

      Map<String, dynamic> batch = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data.putIfAbsent('id', () => doc.id);

        firestore.Timestamp? tsCreated = data['createdAt'] as firestore.Timestamp?;
        data['createdAtInt'] = tsCreated?.millisecondsSinceEpoch ?? 0;

        firestore.Timestamp? tsUpdated = data['updatedAt'] as firestore.Timestamp?;
        data['updatedAtInt'] = tsUpdated?.millisecondsSinceEpoch ?? data['createdAtInt'];

        data.remove('createdAt');
        data.remove('updatedAt');

        data['isLikedByMe'] = _likedBox.containsKey(doc.id);

        batch[doc.id] = data;

        if (!postIds.contains(data['id'])) {
          postIds.add(data['id']);
          _allPosts.add(data);
        } else {
          int index = _allPosts.indexWhere((post) => post['id'] == data['id']);
          if (index != -1) {
            _allPosts[index] = data;
          }
        }
      }

      await _songsBox.putAll(batch);

      _allPosts.sort((a, b) => (b['createdAtInt'] ?? 0).compareTo(a['createdAtInt'] ?? 0));

      setState(() {
        _hasMore = hasMoreData; // Hika ah a dong maw dong lo kan theihter
      });

      _runFilter();

    } catch (e) {
      if (kDebugMode) print("Firebase laaknak ah buainak: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }
  void _runFilter() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      List<Map<String, dynamic>> results = List.from(_allPosts);

      if (_selectedFilter != 'All') {
        results = results
            .where((post) => post['category'] == _selectedFilter)
            .toList();
      }

      if (_searchQuery.isNotEmpty) {
        results = results.where((post) {
          final title = (post['title'] ?? '').toString().toLowerCase();
          final singer = (post['singer'] ?? '').toString().toLowerCase();
          final lyrics = (post['lyrics'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();

          return title.contains(query) ||
              singer.contains(query) ||
              lyrics.contains(query);
        }).toList();
      }
      if (!mounted) return;
      setState(() {
        _displayedPosts = results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
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

              _debounce = Timer(const Duration(milliseconds: 300), () {
                _searchQuery = value;
                _runFilter();
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Hla asiloah Satu min kawl...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                    unreadCount >= 10 ? '10+' : unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
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
      body: Column(
        children: [
          Container(
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
                            color: isSelected ? Colors.black : Colors.white)),
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
          Expanded(
            child: _displayedPosts.isEmpty
                ? Center(
                    child: const Text("Hla a um rih lo",
                        style: TextStyle(color: Colors.white54)),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      if (!mounted) return;
                      try {
                        _lastDocument = null;
                        _hasMore = true;
                        postIds.clear();
                        _allPosts.clear(); // 👈 ADD THIS
                        _displayedPosts.clear();
                        await _fetchSongsFromFirebase();
                      } catch (e) {
                        // fallback to Hive
                        _loadFromHive();
                      }
                    },
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
                          // 2. Laak ding hla a dih cang ahcun Text in a lang lai
                          else if (!_hasMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30.0),
                              child: Center(
                                child: Text("Hla a um ti lo",
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic)),
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
    );
  }

  Widget _buildPostCard(
      Map<String, dynamic> post, BuildContext context, int index)
  {
    bool isChord = post['isChord'] ?? false;
    bool isApproved = post['approved'] ?? false;
    String postType = post['type'] ?? 'hla';
    String categoryText = post['category'] ?? 'Gospel';

    String rawLyrics = post['lyrics'] ?? '';
    String previewLyrics =
        rawLyrics.replaceAll('{verse}', '').replaceAll('{chorus}', '').trim();
    int time = post['createdAtInt'] ?? 0;
    String formattedTime = formatTime(time);

    Color catColor;
    switch (categoryText) {
      case 'Gospel':
        catColor = Colors.green;
        break;
      case 'Ramhla':
        catColor = Colors.orange;
        break;
      case 'Zunhla':
        catColor = Colors.pinkAccent;
        break;
      case 'Christmas':
        catColor = Colors.redAccent;
        break;
      case 'Kumthar':
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
        _showActionDialog(context, post['id'], post, index);
      },
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SongDetailPage(song: post)));
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
                    uid: post['uploaderId'] ?? 'unknown_id',
                    fallbackName: post['uploaderName'] ?? 'Admin',
                    fallbackPhotoUrl: post['uploaderPhotoUrl'],
                    timeText: formattedTime,
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
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
                      if (postType != 'blog')
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Tooltip(
                            message: isApproved
                                ? "Admin nih a check cang mi a si"
                                : "Admin nih a check rih lo (Pending)",
                            triggerMode: TooltipTriggerMode.tap,
                            showDuration: const Duration(seconds: 3),
                            decoration: BoxDecoration(
                              color:
                                  isApproved ? Colors.green : Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.white24, width: 1),
                            ),
                            textStyle: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            preferBelow: false,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  shape: BoxShape.circle),
                              child: Icon(
                                  isApproved ? Icons.verified : Icons.warning,
                                  color: isApproved ? Colors.blue : Colors.red,
                                  size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ]
              ],
            ),
            const SizedBox(height: 15),
            Text(post['title'] ?? 'No Title',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            postType == 'blog'
                ? const SizedBox()
                : Text("Satu: ${post['singer'] ?? 'Unknown'}",
                    style: const TextStyle(
                        color: Colors.white70, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Text(previewLyrics,
                style: const TextStyle(color: Colors.white, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            GestureDetector(
              onLongPress: () {
                _showActionDialog(context, post['id'], post, index);
              },
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongDetailPage(song: post)));
              },
              child: Text(
                postType == 'blog'
                    ? 'Read More '
                    : isChord
                        ? "View Full Chords"
                        : "See Full Lyric",
                style: const TextStyle(
                    color: Colors.blueAccent, fontWeight: FontWeight.w500),
              ),
            ),
            const Divider(color: Colors.white24, height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                    post['isLikedByMe'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    "${post['likes'] ?? 0}",
                    () => _toggleLike(post),
                    color: post['isLikedByMe'] == true
                        ? Colors.red
                        : Colors.white54),
                _buildActionButton(
                    Icons.chat_bubble_outline, "${post['comments'] ?? 0}", () {
                  // HIKA AH UPLOADER ID KAN CHAP
                  showCommentBottomSheet(context, post['id'], post['title'],
                      post['uploaderId'] ?? '');
                }, color: Colors.white70),
                _buildActionButton(Icons.share, "Share", () {
                  _shareSong(post);
                }, color: Colors.white70),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback function,
      {required Color color}) {
    return InkWell(
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
    );
  }

  String formatTime(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${date.year}-${date.month}-${date.day}";
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final String postId = post['id'];
    final String uploaderId = post['uploaderId'] ?? '';
    final String songTitle = post['title'] ?? 'Hla';
    final currentUser = FirebaseAuth.instance.currentUser;

    bool isCurrentlyLiked = _likedBox.containsKey(postId);

    setState(() {
      if (isCurrentlyLiked) {
        post['isLikedByMe'] = false;
        post['likes'] = ((post['likes'] ?? 0) - 1).clamp(0, 999999);
        _likedBox.delete(postId);
      } else {
        post['isLikedByMe'] = true;
        post['likes'] = (post['likes'] ?? 0) + 1;
        _likedBox.put(postId, true);
      }
    });

    try {
      firestore.DocumentReference postRef =
          firestore.FirebaseFirestore.instance.collection('songs').doc(postId);

      if (!isCurrentlyLiked) {
        // 1. Like count karhter
        await postRef.update({'likes': firestore.FieldValue.increment(1)});

        // ================= A THAR: LIKE NOTIFICATION KUATNAK =================
        // Hla ngeitu cu amah a si lo lawngah notification a kuat lai
        if (currentUser != null &&
            currentUser.uid != uploaderId &&
            uploaderId.isNotEmpty) {
          await firestore.FirebaseFirestore.instance
              .collection('users')
              .doc(uploaderId)
              .collection('notifications')
              .add({
            'type': 'like',
            'title': 'Like Na Hmuh',
            'message':
                '${currentUser.displayName ?? "User"} nih na hla "$songTitle" an uar (Like).',
            'isRead': false,
            'createdAt': firestore.FieldValue.serverTimestamp(),
            'postId': postId,
            'senderId': currentUser.uid,
          });
        }
      } else {
        // Unlike tuahnak
        await postRef.update({'likes': firestore.FieldValue.increment(-1)});
      }
      await _songsBox.put(postId, post);
    } catch (e) {
      if (kDebugMode) print("Like tuah lio ah palhnak: $e");
    }
  }

  void _shareSong(Map<String, dynamic> post) {
    final String text =
        "🎵 ${post['title']}\n🎤 Satu: ${post['singer']}\n\n${post['lyrics']}\n\nLaihla Lyrics App in ka rak share mi a si.";
    Share.share(text);
  }

  void _showActionDialog(BuildContext context, String docId,
      Map<String, dynamic> data, int index) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isUploader = currentUser?.uid == data['uploaderId'];
    final bool isAdmin = currentUser?.email == 'xiangoke13@gmail.com';
    final bool canEdit = isUploader || isAdmin;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(data['title'] ?? 'Options'),
        message: const Text('Zeidah tuah na duh?'),
        actions: [
          if (canEdit)
            CupertinoActionSheetAction(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UploadPage(editSong: data)));
                if (result == true) {
                  // Edit a dih tikah UI ah kan rak remh cang lai (HomeFeedPage auto reload a hau ti lo)
                  Navigator.pop(context); // Dialog thianhnak
                }
              },
              child: const Text('Edit Chord'),
            ),
          if (canEdit)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                await firestore.FirebaseFirestore.instance
                    .collection('songs')
                    .doc(docId)
                    .delete();
                setState(() {
                  _allPosts.removeWhere((post) => post['id'] == docId);
                  _displayedPosts
                      .removeWhere((post) => post['id'] == docId); // 👈 ADD
                  postIds.remove(docId);
                });
                _songsBox.delete(docId);
                _runFilter();
                Navigator.pop(context);
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
}
*/
