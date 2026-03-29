import 'package:chinlyrics/laihlalyrics/services/user_services.dart';
import 'package:chinlyrics/laihlalyrics/user/user_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


void showCommentBottomSheet(BuildContext context, String postId, String postTitle, String uploaderId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      // uploaderId kan kuat chih cang lai
      return CommentSheetUI(postId: postId, postTitle: postTitle, uploaderId: uploaderId);
    },
  );
}

class CommentSheetUI extends StatefulWidget {
  final String postId;
  final String postTitle;
  final String uploaderId; // A THAR

  const CommentSheetUI({super.key, required this.postId, required this.postTitle, required this.uploaderId});

  @override
  State<CommentSheetUI> createState() => _CommentSheetUIState();
}

class _CommentSheetUIState extends State<CommentSheetUI> {

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final List<DocumentSnapshot> _comments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        _fetchMoreComments();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('songs').doc(widget.postId).collection('comments')
          .orderBy('createdAt', descending: true).limit(15).get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _comments.addAll(snapshot.docs);
      } else {
        _hasMore = false;
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching comments: $e");
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _fetchMoreComments() async {
    if (!_hasMore || _isLoadingMore || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('songs').doc(widget.postId).collection('comments')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!).limit(15).get();

      if (snapshot.docs.length < 15) _hasMore = false;

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _comments.addAll(snapshot.docs);
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching more comments: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }


  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (currentUser == null) return;

    setState(() => _isPosting = true);

    try {
      String commentText = _commentController.text.trim();

      // ================= A THAR: Min taktak a laak hmasa lai =================
      final userData = await UserService.getUserData(
        uid: currentUser!.uid,
        fallbackName: currentUser!.displayName ?? 'User',
        fallbackPhotoUrl: currentUser!.photoURL,
      );

      DocumentReference newDocRef = await FirebaseFirestore.instance
          .collection('songs').doc(widget.postId).collection('comments').add({
        'text': commentText,
        'uploaderId': currentUser!.uid,
        'uploaderName': userData['name'], // Firebase chung i min taktak a lut cang lai
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('songs').doc(widget.postId)
          .update({'comments': FieldValue.increment(1)});

      // ================= A THAR: COMMENT NOTIFICATION KUATNAK =================
      if (currentUser!.uid != widget.uploaderId && widget.uploaderId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uploaderId) // Hla ngeitu pa sinah a phan lai
            .collection('notifications')
            .add({
          'type': 'comment',
          'title': 'Comment Thar',
          'message': '${userData['name']} nih na hla "${widget.postTitle}" ah comment a tial.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'postId': widget.postId,
          'senderId': currentUser!.uid,
        });
      }

      DocumentSnapshot newlyAddedDoc = await newDocRef.get();
      if (mounted) {
        setState(() {
          _comments.insert(0, newlyAddedDoc);
          _commentController.clear();
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (kDebugMode) print("Comment tial lio ah palhnak: $e");
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Column(
                  children: [
                    const Text("Comments", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(widget.postTitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _comments.isEmpty
                ? const Center(child: Text("Comment a um rih lo. Na tial hmasa bik kho!", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  );
                }

                var data = _comments[index].data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserHeaderWidget(
                              key: ValueKey(_comments[index].id), // ================= HIKA AH KEY KAN CHAP =================
                              uid: data['uploaderId'] ?? 'unknown',
                              fallbackName: data['uploaderName'] ?? 'Unknown User',
                              fallbackPhotoUrl: null,
                              timeText: _formatTime(data['createdAt'] as Timestamp?),
                              isComment: true,
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 35.0),
                              child: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: Colors.black,
              border: const Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      radius: 18,
                      backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                      child: currentUser?.photoURL == null ? const Icon(Icons.person, color: Colors.blueAccent, size: 20) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Comment tial...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[850],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _isPosting
                        ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(icon: const Icon(Icons.send, color: Colors.blueAccent), onPressed: _postComment),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}