import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'follow_widget.dart';


class UserProfilePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String userImage;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ================= PROFILE HEADER =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: const Border(bottom: BorderSide(color: Colors.white12, width: 1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: userImage.isNotEmpty ? CachedNetworkImageProvider(userImage) : null,
                  child: userImage.isEmpty ? Text(userName.isNotEmpty ? userName[0] : '?', style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Hika ah Follow Button kan langhter chih
                      FollowButton(targetUserId: userId, width: 120, height: 35),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= USER'S POSTS LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Firebase in hi pa/nu i a post thengte lawng kha kan kawl (where) lai
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('uploaderId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white54));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Post a um rih lo.", style: TextStyle(color: Colors.white54)));
                }

                var posts = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(5),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Tlar khat ah hmanthlak pathum
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 1, // A kuak tein (Square)
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var data = posts[index].data() as Map<String, dynamic>;
                    String imageUrl = data['imageUrl'] ?? '';

                    // Hmanthlak a um ahcun hmanthlak a lang lai, ca lawng a si ahcun ca a lang lai
                    if (imageUrl.isNotEmpty) {
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[850]),
                      );
                    } else {
                      return Container(
                        color: Colors.grey[850],
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            data['content'] ?? '',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}