import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Hika hi Firebase laaknak caah kan chap
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UserHeaderWidget extends StatefulWidget {
  final String uid;
  final String fallbackName;
  final String? fallbackPhotoUrl;
  final String timeText;
  final bool isComment;

  const UserHeaderWidget({
    super.key,
    required this.uid,
    required this.fallbackName,
    this.fallbackPhotoUrl,
    required this.timeText,
    this.isComment = false,
  });

  @override
  State<UserHeaderWidget> createState() => _UserHeaderWidgetState();
}

class _UserHeaderWidgetState extends State<UserHeaderWidget> {
  String _displayName = '';
  String? _photoUrl;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _setupData();
  }

  // ================= A THAR: List aa thlen tikah a theih nakhnga =================
  @override
  void didUpdateWidget(UserHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uid != oldWidget.uid) {
      _setupData();
    }
  }

  void _setupData() {
    setState(() {
      _displayName = widget.fallbackName;
      _photoUrl = widget.fallbackPhotoUrl;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final Box userCacheBox = Hive.box('userCacheBox');
    final Map? cachedUser = userCacheBox.get(widget.uid);

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    bool alreadyVerifiedInHive = false;
    bool isCooldown = false;

    // 1. HIVE CHUNG DATA CHECK
    if (cachedUser != null) {
      int cachedSongCount = cachedUser['songCount'] ?? 0;
      alreadyVerifiedInHive = cachedSongCount >= 10;

      // Ni khat (86,400,000 ms) chung a si rih maw?
      int lastFetch = cachedUser['lastFetch'] ?? 0;
      if (currentTime - lastFetch < 86400000) {
        isCooldown = true;
      }

      if (mounted) {
        setState(() {
          _displayName = cachedUser['name'] ?? widget.fallbackName;
          _photoUrl = cachedUser['photoUrl'] ?? widget.fallbackPhotoUrl;
          _isVerified = alreadyVerifiedInHive;
        });
      }
    }

    if (!alreadyVerifiedInHive && !isCooldown) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> docData = userDoc.data() as Map<String, dynamic>;
          int firestoreSongCount = docData['songCount'] ?? 0;
          bool isNowVerified = firestoreSongCount >= 10;

          // Hive ah Save (LastFetch telh chih in)
          await userCacheBox.put(widget.uid, {
            'name': docData['displayName'] ??
                docData['name'] ??
                widget.fallbackName,
            'photoUrl': docData['photoUrl'] ?? widget.fallbackPhotoUrl,
            'songCount': firestoreSongCount,
            'lastFetch': currentTime, // Atu caan hi "Last Fetch" tiin chiah
          });

          if (mounted) {
            setState(() {
              _displayName = docData['displayName'] ??
                  docData['name'] ??
                  widget.fallbackName;
              _photoUrl = docData['photoUrl'] ?? widget.fallbackPhotoUrl;
              _isVerified = isNowVerified;
            });
          }
        } else {
          // Firebase ah User a um lo a si zongah Hive ah "LastFetch" chiah a herh
          // Khakha a hmai deuh ah Firebase ah va kal peng lo nakhnga a si.
          await userCacheBox.put(widget.uid, {
            'name': widget.fallbackName,
            'photoUrl': widget.fallbackPhotoUrl,
            'songCount': 0,
            'lastFetch': currentTime,
          });
        }
      } catch (e) {
        if (kDebugMode) print("Firebase Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double avatarSize = widget.isComment ? 15.0 : 20.0;
    double nameFontSize = widget.isComment ? 14.0 : 16.0;
    double timeFontSize = widget.isComment ? 11.0 : 12.0;

    Widget buildAvatar() {
      if (_photoUrl == null || _photoUrl!.isEmpty) {
        return CircleAvatar(
          radius: avatarSize,
          backgroundColor: Colors.grey[800],
          child: Icon(Icons.person, color: Colors.white, size: avatarSize),
        );
      }

      return CachedNetworkImage(
        imageUrl: _photoUrl!,
        cacheKey: _photoUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: avatarSize,
          backgroundImage: imageProvider,
          backgroundColor: Colors.transparent,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: avatarSize,
          backgroundColor: Colors.grey[800],
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: const CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white54),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: avatarSize,
          backgroundColor: Colors.grey[800],
          child: Icon(Icons.person, color: Colors.white, size: avatarSize),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // A sau tuk ahcun ... a lang lai
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: nameFontSize),
                    ),
                  ),
                  if (_isVerified) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: "Verified User",
                      triggerMode: TooltipTriggerMode.tap,
                      child: const Icon(Icons.verified,
                          color: Colors.blueAccent, size: 16),
                    ),
                  ],
                  const SizedBox(width: 4),
                ],
              ),
              const SizedBox(height: 2),
              Text(widget.timeText,
                  style:
                      TextStyle(color: Colors.white54, fontSize: timeFontSize)),
            ],
          ),
        ),
      ],
    );
  }
}
