import 'package:chinlyrics/laihlalyrics/services/user_services.dart';
import 'package:chinlyrics/laihlalyrics/user/user_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CommentSheetUI extends StatefulWidget {
  final String postId;
  final String uploaderId;

  const CommentSheetUI({super.key, required this.postId, required this.uploaderId});

  @override
  State<CommentSheetUI> createState() => _CommentSheetUIState();
}

class _CommentSheetUIState extends State<CommentSheetUI> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode(); // Keyboard auhnak caah
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final List<DocumentSnapshot> _comments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isPosting = false;

  // ================= REPLY CAAH VARIABLES =================
  String? _replyingToUid;
  String? _replyingToName;

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
    _focusNode.dispose();
    super.dispose();
  }

  // ================= 1. COMMENT LAAKNAK =================
  Future<void> _fetchComments() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId).collection('comments')
          .orderBy('createdAt', descending: true).limit(15).get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _comments.addAll(snapshot.docs);
        _hasMore = snapshot.docs.length == 15;
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
          .collection('posts').doc(widget.postId).collection('comments')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!).limit(15).get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _comments.addAll(snapshot.docs);
        _hasMore = snapshot.docs.length == 15;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching more comments: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ================= 2. COMMENT TIALNAK (Reply tel in) =================
  Future<void> _postComment() async {
    String commentText = _commentController.text.trim();
    if (commentText.isEmpty || currentUser == null) return;

    setState(() => _isPosting = true);
    FocusScope.of(context).unfocus();

    try {
      final userData = await UserService.getUserData(
        uid: currentUser!.uid,
        fallbackName: currentUser!.displayName ?? 'User',
        fallbackPhotoUrl: currentUser!.photoURL,
      );
      String uploaderName = userData['name'] ?? currentUser!.displayName ?? 'User';

      // Firebase ah save dingmi Data
      Map<String, dynamic> commentData = {
        'text': commentText,
        'uploaderId': currentUser!.uid,
        'uploaderName': uploaderName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Reply a si ahcun data kan chap lai
      if (_replyingToUid != null && _replyingToName != null) {
        commentData['replyToUid'] = _replyingToUid;
        commentData['replyToName'] = _replyingToName;
      }

      DocumentReference newDocRef = await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId).collection('comments').add(commentData);

      await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId)
          .update({'comments': FieldValue.increment(1)});

      // ================= NOTIFICATION KUATNAK =================
      // Reply a si ahcun a theitu pa/nu sinah a kal lai. Direct comment a si ahcun post ngeitu sinah a kal lai.
      String notifyUserId = _replyingToUid ?? widget.uploaderId;

      if (currentUser!.uid != notifyUserId && notifyUserId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users').doc(notifyUserId).collection('notifications')
            .add({
          'type': _replyingToUid != null ? 'reply' : 'comment',
          'title': _replyingToUid != null ? 'Reply Thar' : 'Comment Thar',
          'message': '$uploaderName nih na ${_replyingToUid != null ? "comment" : "post"} ah bia a in leh.',
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
          // Post dih in Reply state phiat tthannak
          _replyingToUid = null;
          _replyingToName = null;
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (kDebugMode) print("Comment tial palhnak: $e");
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // ================= 3. DELETE COMMENT =================
  Future<void> _deleteComment(String commentId, int index) async {
    // 1. UI in lak hmasa
    setState(() {
      _comments.removeAt(index);
    });

    try {
      // 2. Firebase in phiahnak
      await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId)
          .collection('comments').doc(commentId).delete();

      // 3. Post i comment count tthumnak
      await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId)
          .update({'comments': FieldValue.increment(-1)});

    } catch (e) {
      if (kDebugMode) print("Delete palhnak: $e");
    }
  }

  // ================= UI HELPERS =================
  void _startReplying(String uid, String name) {
    setState(() {
      _replyingToUid = uid;
      _replyingToName = name;
    });
    FocusScope.of(context).requestFocus(_focusNode); // Keyboard on colhnak
  }

  void _cancelReply() {
    setState(() {
      _replyingToUid = null;
      _replyingToName = null;
    });
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
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text("Comments", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // COMMENTS LIST
          Expanded(
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _comments.isEmpty
                ? const Center(child: Text("Comment a um rih lo.", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(15),
              itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
                }

                var doc = _comments[index];
                var data = doc.data() as Map<String, dynamic>;
                String cmtUid = data['uploaderId'] ?? 'unknown';
                String cmtName = data['uploaderName'] ?? 'Unknown User';
                bool isMyComment = currentUser != null && cmtUid == currentUser!.uid;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
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

                      Padding(
                        padding: const EdgeInsets.only(left: 36.0, top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ================= REPLY TAG LANGHTERNAK =================
                            if (data['replyToName'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                    "@${data['replyToName']}",
                                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                              ),

                            _buildFormattedText(data['text'] ?? ''),
                            const SizedBox(height: 6),

                            // ================= ACTION BUTTONS (Reply & Delete) =================
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _startReplying(cmtUid, cmtName),
                                  child: const Text("Reply", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 20),
                                if (isMyComment) // A tialtu a si lawng ah Delete menu a lang lai
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.grey[900],
                                          title: const Text('Comment phiat', style: TextStyle(color: Colors.white)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteComment(doc.id, index);
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ================= COMMENT INPUT BAR =================
          Container(
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: const BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Colors.white12))),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // REPLY BANNER
                  if (_replyingToName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      color: Colors.grey[850],
                      child: Row(
                        children: [
                          Expanded(child: Text("Replying to @$_replyingToName", style: const TextStyle(color: Colors.white70, fontSize: 12))),
                          GestureDetector(
                            onTap: _cancelReply,
                            child: const Icon(Icons.close, color: Colors.white54, size: 16),
                          )
                        ],
                      ),
                    ),

                  // INPUT ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          radius: 18,
                          backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                          child: currentUser?.photoURL == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _focusNode, // Hika ah FocusNode kan hman
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _postComment(),
                            decoration: InputDecoration(
                              hintText: _replyingToName != null ? 'Bia leh...' : 'Comment tial...',
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
                            ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)))
                            : IconButton(icon: const Icon(Icons.send, color: Colors.blueAccent), onPressed: _postComment),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ================= LINK LE HASHTAG FORMAT TUAHNAK =================
  Widget _buildFormattedText(String text) {
    // Regex: Link le Hashtag kawlnak
    final RegExp linkOrHashtagRegExp = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+|#\w+)', caseSensitive: false);

    List<TextSpan> spans = [];

    text.splitMapJoin(
      linkOrHashtagRegExp,
      onMatch: (Match match) {
        String matchText = match.group(0)!;

        // 1. Hashtag a si ahcun
        if (matchText.startsWith('#')) {
          spans.add(TextSpan(
              text: matchText,
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
          ));
        }
        // 2. Link a si ahcun
        else {
          spans.add(TextSpan(
            text: matchText,
            style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () async {
              // Link hmeh tikah Browser a on lai
              String urlString = matchText.startsWith('www.') ? 'https://$matchText' : matchText;
              final Uri url = Uri.parse(urlString);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (kDebugMode) print('Could not launch $url');
              }
            },
          ));
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        // A sasawh mi ca pawl
        spans.add(TextSpan(text: nonMatch, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)));
        return '';
      },
    );

    return RichText(text: TextSpan(children: spans));
  }
}