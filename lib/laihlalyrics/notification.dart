import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Notification phun (type) zoh in Icon thimnak
  IconData _getIcon(String type) {
    switch (type) {
      case 'new_song': return Icons.music_note;
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'system': return Icons.info;
      default: return Icons.notifications;
    }
  }

  // Notification phun (type) zoh in Color thimnak
  Color _getIconColor(String type) {
    switch (type) {
      case 'new_song': return Colors.greenAccent;
      case 'like': return Colors.redAccent;
      case 'comment': return Colors.blueAccent;
      case 'system': return Colors.orangeAccent;
      default: return Colors.white54;
    }
  }

  // Firebase Timestamp kha caan mawi (Time Ago) in langhternak
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  // ================= A THAR: A Zapi in Rel Cia in Tuahnak =================
  Future<void> _markAllAsRead() async {
    if (currentUser == null) return;

    // Unread a simi vialte laaknak
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    // Firebase Batch Update hmang in voikhat ah update dih
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A dihlak rel cangmi ah thlen a si."), backgroundColor: Colors.blueAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
        body: const Center(child: Text("Login tuah hmasa a hau.", style: TextStyle(color: Colors.white54))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Theihternak", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blueAccent),
            tooltip: 'Zate Rel Cia In Tuah',
            onPressed: _markAllAsRead, // Function thar kan ko
          ),
          const SizedBox(width: 5),
        ],
      ),

      // ================= A THAR: FIREBASE STREAMBUILDER KAN HMANG =================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white24),
                  SizedBox(height: 15),
                  Text("Theihternak thar a um lo.", style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notifDoc = notifications[index];
              final notif = notifDoc.data() as Map<String, dynamic>;
              final bool isRead = notif['isRead'] ?? false;

              return InkWell(
                onTap: () {
                  // Hmeh tikah rel ciami (Read) ah aa thleng lai (Firebase ah update tuah colh)
                  if (!isRead) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid)
                        .collection('notifications')
                        .doc(notifDoc.id)
                        .update({'isRead': true});
                  }

                  // Hika ah Detail Page ah kal ding a si ahcun peh khawh a si
                },
                child: Container(
                  color: isRead ? Colors.transparent : Colors.blueAccent.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconColor(notif['type'] ?? 'system').withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(notif['type'] ?? 'system'), color: _getIconColor(notif['type'] ?? 'system'), size: 22),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'] ?? 'Notification',
                              style: TextStyle(
                                color: isRead ? Colors.white70 : Colors.white,
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              notif['message'] ?? '',
                              style: TextStyle(color: isRead ? Colors.white54 : Colors.white70, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(notif['createdAt'] as Timestamp?),
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}