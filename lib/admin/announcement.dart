import 'package:flutter/material.dart';

import '../notifications/notificationHelper.dart';
// NotificationHelper na chiahnak file import rak tuah te
// import 'package:chinlyrics/utils/notification_helper.dart';

class AnnouncementPusherPage extends StatefulWidget {
  const AnnouncementPusherPage({super.key});

  @override
  State<AnnouncementPusherPage> createState() => _AnnouncementPusherPageState();
}

class _AnnouncementPusherPageState extends State<AnnouncementPusherPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await NotificationHelper.sendNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: "announcement",
        topic: "all_users", // Zapi sinah a kal lai
      );

      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Send Announcement', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black12,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "App a hmangmi vialte sinah notification thlahnak.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Title Input
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notification Title',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 16),

            // Body Input
            TextField(
              controller: _bodyController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notification Message (Body)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.message, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 30),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSending ? null : _sendAnnouncement,
                icon: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                    _isSending ? "Thlah lio..." : "SEND ANNOUNCEMENT",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
