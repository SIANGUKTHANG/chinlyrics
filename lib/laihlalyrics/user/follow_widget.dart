import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId; // Na follow dingmi pa/nu i a UID
  final double width;
  final double height;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.width = 64,
    this.height = 28,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  // ================= 1. FOLLOW A RAK TUAH CIA MAW CHECK NAK =================
  Future<void> _checkFollowStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    _currentUserId = currentUser.uid;

    // Keimah (Current User) i Firebase Document ah kan va zoh lai
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> followingList = data['following'] ?? [];

      if (mounted) {
        setState(() {
          // Amah hi ka Follow ciami a si maw? (True/False)
          _isFollowing = followingList.contains(widget.targetUserId);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 2. FOLLOW / UNFOLLOW TUAHNAK LOGIC =================
  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _currentUserId == widget.targetUserId) return; // Mah le mah i follow a ngah lo

    // UI ah a ran nakhnga (Optimistic Update)
    setState(() {
      _isFollowing = !_isFollowing;
    });

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);
    final targetUserRef = FirebaseFirestore.instance.collection('users').doc(widget.targetUserId);

    try {
      if (_isFollowing) {
        // ================= FOLLOW TUAHNAK =================
        // 1. Keimah i Following ah chap
        await currentUserRef.set({
          'following': FieldValue.arrayUnion([widget.targetUserId])
        }, SetOptions(merge: true));

        // 2. Midang pa/nu i Followers ah keimah uid va chap
        await targetUserRef.set({
          'followers': FieldValue.arrayUnion([_currentUserId])
        }, SetOptions(merge: true));

      } else {
        // ================= UNFOLLOW TUAHNAK =================
        // 1. Keimah i Following in phiat tthan
        await currentUserRef.set({
          'following': FieldValue.arrayRemove([widget.targetUserId])
        }, SetOptions(merge: true));

        // 2. Midang pa/nu i Followers in keimah uid va phiat tthan
        await targetUserRef.set({
          'followers': FieldValue.arrayRemove([_currentUserId])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Error a chuah sual ahcun a hlan sining ah kir tthan
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Palhnak a um. Internet check tthan hmanh.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // Mah le mah i post ahcun Follow button a lang lai lo
    if (_currentUserId == widget.targetUserId) {
      return const SizedBox.shrink();
    }

    // ================= 3. BUTTON UI =================
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ElevatedButton(
        onPressed: _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.transparent : Colors.blueAccent, // Follow cang ahcun a rong a tlau lai
          foregroundColor: _isFollowing ? Colors.white : Colors.white,
          elevation: _isFollowing ? 0 : 2,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          side: _isFollowing ? const BorderSide(color: Colors.white54, width: 1) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          _isFollowing ? "Following" : "Follow", // Text aa thleng lai
          style: TextStyle(
            color: Colors.white,
            fontSize:   _isFollowing ?10 :13,
            fontWeight: _isFollowing ? FontWeight.w700 : FontWeight.bold,
          ),
        ),
      ),
    );
  }
}