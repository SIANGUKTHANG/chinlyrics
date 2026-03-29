import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chinlyrics/laihlalyrics/user/follow_widget.dart';
import 'package:chinlyrics/laihlalyrics/user/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'comments/post.dart';
import 'create_post.dart';
import 'isar/home.dart';
import 'model/post_model.dart';

class FeedPage extends StatefulWidget {
  // Isar instance na main in a rami a si ahcun parameter in laak asiloah global in laak khawh a si.
  // Tahchunhnak ah global variable 'isar' a um cang tiin ka ruah mu.

  const FeedPage({
    super.key,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Map<String, dynamic>> _posts = [];
  List<String> _myFollowingList = [];
  late Isar isar;
  bool searchBar = true;
  bool _isLoadingInitial = true;
  bool _isFetchingMore = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;
  final Map<String, bool> _expandedPosts = {};
  final ScrollController _scrollController = ScrollController();
  final int _postsLimit = 10;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Timer? _debounce;
  bool _isSearching = false;
  bool _isAppBarVisible = true;
  List<Map<String, dynamic>> _allPosts = [];

  @override
  void initState() {
    super.initState();
    isar = Isar.getInstance()!;
    _scrollController.addListener(_onScroll);
    _loadCachedFeed(); // ISAR in a laak hmasa lai
    _fetchInitialData(); // Firebase in a thar a laak tthan lai
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isSearching) return; // 🚨 STOP pagination during search

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMorePosts) {
        _fetchMorePosts();
      }
    }
  }

  // ================= 1. ISAR IN LAAKNAK (CACHE) =================
  Future<void> _loadCachedFeed() async {
    final cachedPosts =
        await isar.postModels.where().sortByCreatedAtDesc().findAll();

    if (cachedPosts.isNotEmpty && mounted) {
      List<Map<String, dynamic>> parsedCache = [];
      for (var post in cachedPosts) {
        parsedCache.add({
          'id': post.firestoreId,
          'uploaderId': post.uploaderId,
          'userName': post.userName,
          'userImage': post.userImage,
          'content': post.content,
          'imageUrls': post.imageUrls,
          'likes': post.likes,
          'comments': post.comments,
          'likedBy': post.likedBy,
          'createdAt':
              Timestamp.fromMillisecondsSinceEpoch(post.createdAt ?? 0),
        });
      }

      setState(() {
        _posts = _sortPosts(parsedCache);
        _allPosts = List.from(_posts);

        _isLoadingInitial = false;
      });
    }
  }

  // ================= 2. FIREBASE IN A THAR LAAKNAK =================
  Future<void> _fetchInitialData() async {
    setState(() => _isLoadingInitial = _posts.isEmpty);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        _myFollowingList =
            List<String>.from(userDoc.data()!['following'] ?? []);
      }
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(_postsLimit)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;

      List<Map<String, dynamic>> newPosts = [];
      List<PostModel> isarPosts = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        newPosts.add(data);

        // Isar caah Model ah thlen hmasa
        final isarPost = PostModel()
          ..firestoreId = doc.id
          ..uploaderId = data['uploaderId']
          ..userName = data['userName']
          ..userImage = data['userImage']
          ..content = data['content']
          ..imageUrls = data['imageUrls'] != null
              ? List<String>.from(doc['imageUrls'])
              : []
          ..likes = data['likes']
          ..comments = data['comments']
          ..likedBy = List<String>.from(data['likedBy'] ?? [])
          ..createdAt =
              (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

        isarPosts.add(isarPost);
      }

      // Isar chungah a hlunmi phiat in a tharmi thun tthannak
      await isar.writeTxn(() async {
        await isar.postModels.clear();
        await isar.postModels.putAll(isarPosts);
      });

      if (mounted) {
        setState(() {
          _posts = _sortPosts(newPosts);
          _allPosts = List.from(_posts);
          _hasMorePosts = snapshot.docs.length == _postsLimit;
          _isLoadingInitial = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  // ================= 3. SCROLL TUAH TIKAH CHAP (PAGINATION) =================
  Future<void> _fetchMorePosts() async {
    if (_lastDocument == null) return;
    setState(() => _isFetchingMore = true);

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_postsLimit)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;

      List<Map<String, dynamic>> morePosts = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        morePosts.add(data);
      }

      if (mounted) {
        setState(() {
          _posts.addAll(morePosts);
          _posts = _sortPosts(_posts);

          _allPosts = List.from(_posts); // ✅ FIX

          _hasMorePosts = snapshot.docs.length == _postsLimit;
          _isFetchingMore = false;
        });
      }
    } else {
      if (mounted) setState(() => _hasMorePosts = false);
    }
  }

// ================= POST DELETE TUAHNAK =================
  Future<void> _deletePost(String docId, int index) async {
    // 1. Hmanthlak zapi laak cia nak (A hlun 'imageUrl' asiloah a thar 'imageUrls' pahnih in a theithiam)
    List<dynamic> imgs = _posts[index]['imageUrls'] ?? [];
    if (imgs.isEmpty && (_posts[index]['imageUrl'] ?? '').isNotEmpty) {
      imgs = [_posts[index]['imageUrl']];
    }

    // 2. UI in lak tthannak (Optimistic update)
    setState(() {
      _posts.removeAt(index);
    });

    try {
      // ================= 3. CLOUDFLARE R2 IN ZAPI PHIAHNAK (LOOP) =================
      if (imgs.isNotEmpty) {
        String secretKey = 'my-secret-key-123'; // Na password taktak in thleng

        for (String url in imgs) {
          if (url.contains('r2.dev')) {
            // Link chung in File min thengte laaknak
            String fileName = url.split('/').last;

            // Na Worker Link thengte
            String workerUrl =
                'https://laihla-upload-api.itrungrul.workers.dev/$fileName';

            // HTTP DELETE hmang in Worker sinah pakhat hnu pakhat phiah ding in fialnak
            await http.delete(
              Uri.parse(workerUrl),
              headers: {'Authorization': 'Bearer $secretKey'},
            );
          }
        }
      }
      // ==========================================================================

      // 4. Firebase in phiahnak
      await FirebaseFirestore.instance.collection('posts').doc(docId).delete();

      // 5. Isar Local in phiahnak
      await isar.writeTxn(() async {
        final post = await isar.postModels
            .filter()
            .firestoreIdEqualTo(docId)
            .findFirst();
        if (post != null) {
          await isar.postModels.delete(post.isarId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Post le Hmanthlak zapi na phiat cang.")));
      }
    } catch (e) {
      _fetchInitialData(); // Palhnak a um ahcun a thar in laak tthan
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Phiahnak ah palhnak a um.")));
      }
    }
  }

  // ================= FEED SORTING & HELPERS =================
  List<Map<String, dynamic>> _sortPosts(List<Map<String, dynamic>> postList) {
    postList.sort((a, b) {
      String uploaderA = a['uploaderId'] ?? '';
      String uploaderB = b['uploaderId'] ?? '';

      bool isAFollowed = _myFollowingList.contains(uploaderA);
      bool isBFollowed = _myFollowingList.contains(uploaderB);

      if (isAFollowed && !isBFollowed) return -1;
      if (!isAFollowed && isBFollowed) return 1;

      Timestamp timeA = a['createdAt'] ?? Timestamp.now();
      Timestamp timeB = b['createdAt'] ?? Timestamp.now();
      return timeB.compareTo(timeA);
    });
    return postList;
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} yrs ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mos ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hrs ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }

  // A thar chap dingmi: Post zeidah Heart animation a piah lio ti theihnak

  // Like function a thar (Double-tap in a rami a si ahcun Like a si cia cun unlike a tuah lai lo)
  Future<void> _toggleLike(int index, {bool isDoubleTap = false}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;
    var post = _posts[index];
    final docId = post['id'];
    List<dynamic> likedBy = post['likedBy'] ?? [];

    // Double-tap a si i a rak like ciami a si ahcun zeihmanh tuah a hau lo
    if (isDoubleTap && likedBy.contains(uid)) return;

    setState(() {
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
        post['likes'] = (post['likes'] ?? 1) - 1;
      } else {
        likedBy.add(uid);
        post['likes'] = (post['likes'] ?? 0) + 1;
      }
      post['likedBy'] = likedBy;
    });

    final postRef = FirebaseFirestore.instance.collection('posts').doc(docId);
    if (!likedBy.contains(uid)) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likes': FieldValue.increment(-1)
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likes': FieldValue.increment(1)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Notch le Status bar tang ah a um nakhnga SafeArea
      body: SafeArea(
        // ================= SCROLL THEIHNAK (Top AppBar caah) =================
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isAppBarVisible) setState(() => _isAppBarVisible = false);
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isAppBarVisible) setState(() => _isAppBarVisible = true);
            }

            // HIKA HI A BIAPI TUK: false a si a hau, cuticun BottomNav zongah a tlun/phan kho ve lai
            return false;
          },
          child: Column(
            children: [
              // ================= 1. ANIMATED APP BAR (Facebook Style) =================
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _isAppBarVisible ? 56.0 : 0.0,
                // AppBar sanning cu 56 a si
                child: Container(
                  height: 56.0,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      !searchBar
                          ? Expanded(
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.white12)),
                                  child: TextField(
                                    onChanged: (v) {
                                      if (_debounce?.isActive ?? false) _debounce!.cancel();

                                      _debounce = Timer(const Duration(milliseconds: 300), () async {
                                        final query = v.trim();

                                        // ✅ 1. Empty → restore feed
                                        if (query.isEmpty) {
                                          setState(() {
                                            _isSearching = false;
                                            _posts = List.from(_allPosts);
                                          });
                                          return;
                                        }

                                        setState(() => _isSearching = true);

                                        // ✅ 2. Local search first
                                        final localResults = searchPosts(query);

                                        if (localResults.isNotEmpty) {
                                          setState(() => _posts = localResults);
                                          return;
                                        }

                                        // ✅ 3. Fallback → Isar search
                                        final isarResults = await isar.postModels
                                            .filter()
                                            .contentContains(query, caseSensitive: false)
                                            .or()
                                            .userNameContains(query, caseSensitive: false)
                                            .findAll();

                                        setState(() {
                                          _posts = isarResults.map((post) => {
                                            'id': post.firestoreId,
                                            'uploaderId': post.uploaderId,
                                            'userName': post.userName,
                                            'userImage': post.userImage,
                                            'content': post.content,
                                            'imageUrls': post.imageUrls,
                                            'likes': post.likes,
                                            'comments': post.comments,
                                            'likedBy': post.likedBy,
                                            'createdAt': Timestamp.fromMillisecondsSinceEpoch(
                                                post.createdAt ?? 0),
                                          }).toList();
                                        });
                                      });
                                    },decoration: InputDecoration(
                                      hintText: "Search...",
                                      hintStyle: TextStyle(),
                                      border: InputBorder.none,
                                    ),
                                  )),
                            )
                          : Expanded(
                              child: const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Feed",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                              ),
                            ),
                      Row(
                        children: [
                          IconButton(
                              icon:
                                  const Icon(Icons.search, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  searchBar = !searchBar;
                                });
                              }),
                          IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CreatePostPage()));
                              }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ================= 2. FEED CONTENT (Post langhternak) =================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchInitialData,
                  color: Colors.blueAccent,
                  backgroundColor: Colors.grey[900],
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // NOTE: SliverAppBar hlun kha cu kan phiat cang mu

                      searchBar
                          ? SliverToBoxAdapter(child: _buildCreatePostHeader())
                          : const SliverToBoxAdapter(),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      // A tang lei cu a hlan i na code a simi SliverList pawl an si ko lai
                      if (_isLoadingInitial)
                        const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white54))),
                        )
                      else if (_posts.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(
                                child: Text("Feed ah post a um rih lo.",
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 16))),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildPostCard(index);
                            },
                            childCount: _posts.length,
                          ),
                        ),

                      if (_isFetchingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white54)),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.grey[900],
          border: const Border(
              bottom: BorderSide(color: Colors.white10, width: 1))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[800],
            backgroundImage: currentUser!.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            child: currentUser!.photoURL == null
                ? const Icon(Icons.person, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                bool? posted = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreatePostPage()));
                if (posted == true) _fetchInitialData();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white12)),
                child: const Text("Na ruahmi asiloah hmuhtonmi tial...",
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(int index) {
    Map<String, dynamic> post = _posts[index];

    String docId = post['id'];
    String uName = post['userName'] ?? 'Unknown';
    String uImage = post['userImage'] ?? '';
    String uploaderId = post['uploaderId'] ?? '';
    int likes = post['likes'] ?? 0;
    int comments = post['comments'] ?? 0;
    String timeString = _getTimeAgo(post['createdAt'] as Timestamp?);

    List<dynamic> likedBy = post['likedBy'] ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isLikedByMe = currentUser != null && likedBy.contains(currentUser.uid);
    bool isMyPost = currentUser != null && currentUser.uid == uploaderId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border.symmetric(
            horizontal: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GestureDetector(
              onTap: () {
                // 1. Await kan hman lai
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userId: uploaderId,
                        userName: uName,
                        userImage: uImage,
                      ),
                    )).then(((_) async {
                  await _fetchMyFollowingList();
                }));
                ;

                // 3. UI a thar in mawi tein thleh tthan (Refresh hau lo in)
                if (mounted) {
                  setState(() {
                    _posts = _sortPosts(_posts);
                  });
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: uImage.isNotEmpty
                        ? CachedNetworkImageProvider(uImage)
                        : null,
                    child: uImage.isEmpty
                        ? Text(uName.isNotEmpty ? uName[0] : '?',
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(uName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(timeString,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),

                  if (!isMyPost)
                    FollowButton(
                        targetUserId: uploaderId, width: 90, height: 30),

                  const SizedBox(width: 5),

                  // ================= OPTIONS MENU (DELETE) =================
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.white54),
                    color: Colors.grey[800],
                    onSelected: (value) {
                      if (value == 'delete') {
                        // Delete confirmation
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Post phiat',
                                style: TextStyle(color: Colors.white)),
                            content: const Text(
                                'Hi post hi na phiat taktak lai maw?',
                                style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deletePost(
                                      docId, index); // Phiahnak function auh
                                },
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      if (isMyPost) // A tialtu a si lawng ah Delete menu a lang lai
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Post',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Text('Report',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= POST CONTENT (READ MORE HE) =================
          if (post['content'] != null && post['content'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Builder(builder: (context) {
                String contentText = post['content'];
                bool isExpanded = _expandedPosts[docId] ?? false; // A kau maw kau lo

                return GestureDetector(
                  onTap: () => contentText.length > 150
                      ? setState(() => _expandedPosts[docId] = !isExpanded)
                      : setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattedText(contentText,
                          maxLines: isExpanded ? null : 4),
                      contentText.length > 150
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                  isExpanded
                                      ? "Tawi in zoh tthan"
                                      : "... A zapi in rel",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold)),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                );
              }),
            ),

          const SizedBox(height: 10),

          // ================= MULTI-IMAGE GALLERY =================
          Builder(builder: (context) {
            // Backward compatibility (A hlun i 'imageUrl' asiloah a thar i 'imageUrls')
            List<dynamic> imgs = post['imageUrls'] ?? [];
            if (imgs.isEmpty && (post['imageUrl'] ?? '').isNotEmpty) {
              imgs = [post['imageUrl']];
            }

            if (imgs.isEmpty) return const SizedBox.shrink();

            // Hmanthlak a um ahcun
            return SizedBox(
              height: 350, // Feed hmanthlak san ning ding
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: imgs.length,
                itemBuilder: (context, imgIndex) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imgs[imgIndex],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                            color: Colors.grey[850],
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white54))),
                      ),

                      // Hmanthlak nambat langhternak (Tahchunhnak: 1/3)
                      if (imgs.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(15)),
                            child: Text("${imgIndex + 1}/${imgs.length}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          }),

          const SizedBox(height: 15),
          const Divider(color: Colors.white10, height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: isLikedByMe ? Colors.redAccent : Colors.white54,
                  label: '$likes',
                  onTap: () => _toggleLike(index),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.white54,
                  label: '$comments',
                  onTap: () async {
                    // 1. Comment Sheet a on lio ah kan hngah lai (await)
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          CommentSheetUI(postId: docId, uploaderId: uploaderId),
                    );

                    // 2. A phih tikah, hi post thengte i a thar bikmi Comment le Like nambat kha kan va laak tthan lai
                    var updatedDoc = await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(docId)
                        .get();
                    if (updatedDoc.exists && mounted) {
                      setState(() {
                        _posts[index]['comments'] =
                            updatedDoc.data()?['comments'] ?? 0;
                        _posts[index]['likes'] =
                            updatedDoc.data()?['likes'] ?? 0;
                        _posts[index]['likedBy'] =
                            updatedDoc.data()?['likedBy'] ?? [];
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ================= LINK LE HASHTAG FORMAT TUAHNAK =================
  Widget _buildFormattedText(String text, {int? maxLines}) {
    final RegExp linkOrHashtagRegExp =
        RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+|#\w+)', caseSensitive: false);
    List<TextSpan> spans = [];

    text.splitMapJoin(
      linkOrHashtagRegExp,
      onMatch: (Match match) {
        String matchText = match.group(0)!;

        if (matchText.startsWith('#')) {
          // Hashtag caah
          spans.add(TextSpan(
              text: matchText,
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)));
        } else {
          // Link caah
          spans.add(TextSpan(
            text: matchText,
            style: const TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                fontSize: 15),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                String urlString = matchText.startsWith('www.')
                    ? 'https://$matchText'
                    : matchText;
                final Uri url = Uri.parse(urlString);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
          ));
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        // Ca sasawh caah (Font size 15)
        spans.add(TextSpan(
            text: nonMatch,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.4)));
        return '';
      },
    );

    return RichText(
      maxLines: maxLines,
      // A thar
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      // A thar
      text: TextSpan(children: spans),
    );
  }

  // ================= FOLLOWING LIST LAAK TTHANNAK =================
  Future<void> _fetchMyFollowingList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        if (mounted) {
          setState(() {
            _myFollowingList =
                List<String>.from(userDoc.data()!['following'] ?? []);
          });
        }
      }
    }
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> searchPosts(String query) {
    final q = query.toLowerCase();

    return _allPosts.where((post) {
      final content = (post['content'] ?? '').toString().toLowerCase();
      final user = (post['userName'] ?? '').toString().toLowerCase();

      return content.contains(q) || user.contains(q);
    }).toList();
  }
}
