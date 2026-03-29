import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user/edit_profile.dart';
import '../user/login.dart';
// import 'login_page.dart'; // Logout tuah tikah kalnak ding page

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ================= STATE VARIABLES & HIVE BOX =================
  final Box _settingsBox = Hive.box('settingsBox');

  bool _notificationsEnabled = true;
  bool _offlineModeEnabled = true;
  double _lyricsFontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Page on in Hive in Setting a laak colh lai
  }

  // ================= 1. SETTINGS LAAKNAK (LOAD) =================
  void _loadSettings() {
    setState(() {
      // Box ah a um lo ahcun a thawkka data (Default) a hmang lai
      _notificationsEnabled = _settingsBox.get('notifications', defaultValue: true);
      _offlineModeEnabled = _settingsBox.get('offlineMode', defaultValue: true);
      _lyricsFontSize = _settingsBox.get('fontSize', defaultValue: 18.0);
    });
  }

  // ================= 2. SETTINGS SAVE TUAHNAK =================
  void _saveSetting(String key, dynamic value) {
    _settingsBox.put(key, value);
  }

  // ================= 3. CACHE THIANHNAK =================
  void _clearCache(BuildContext context) async {
    // Phone chung i save mi hla pawl le recent history thianhnak
    await Hive.box('downloads').clear();
    await Hive.box('settingsBox').clear();
    await Hive.box('userBox').clear();
    await Hive.box('chord').clear();
    await Hive.box('songsBox').clear();
    await Hive.box('likedBox').clear();
    await Hive.box('recentBox').clear();
    await Hive.box('settingsBox').clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cache thianh a si cang! (Phone a thiang)"), backgroundColor: Colors.green),
      );
    }
  }

  // ================= 4. LOGOUT TUAHNAK =================
  Future<void> _handleLogout(BuildContext context) async {
    try {

      await FirebaseAuth.instance.signOut();

      //Hive
      await Hive.box('downloads').clear();
      await Hive.box('settingsBox').clear();
      await Hive.box('userBox').clear();
      await Hive.box('chord').clear();
      await Hive.box('songsBox').clear();
      await Hive.box('likedBox').clear();
      await Hive.box('recentBox').clear();
      await Hive.box('settingsBox').clear();
      if (context.mounted) {

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Log Out tuah a si cang."), backgroundColor: Colors.blueAccent),
        );
      }
    } catch (e) {
      print("Logout ah palhnak: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [
          // ================= 1. ACCOUNT SECTION =================
          _buildSectionHeader("ACCOUNT"),
          _buildListTile(
            icon: Icons.person_outline,
            title: "Edit Profile",
            onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
            },
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              // Password thlennak ah kalnak
            },
          ),

          const SizedBox(height: 25),

          // ================= 2. DISPLAY & AUDIO =================
          _buildSectionHeader("DISPLAY"),

          // Font Size Slider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.text_fields, color: Colors.white54, size: 22),
                        SizedBox(width: 15),
                        Text("Lyrics Font Size", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    Text("${_lyricsFontSize.toInt()} px", style: const TextStyle(color: Colors.blueAccent)),
                  ],
                ),
                Slider(
                  value: _lyricsFontSize,
                  min: 14.0, max: 30.0,
                  activeColor: Colors.blueAccent, inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() => _lyricsFontSize = value);
                  },
                  onChangeEnd: (value) {
                    // Slider an hmeh a dih bak in Hive ah a save lai
                    _saveSetting('fontSize', value);
                  },
                ),
              ],
            ),
          ),

          _buildSwitchTile(
            icon: Icons.notifications_none,
            title: "Push Notifications",
            subtitle: "Hla thar a um ah theihternak",
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              _saveSetting('notifications', val);
            },
          ),

          const SizedBox(height: 25),

          // ================= 3. STORAGE & DATA =================
          _buildSectionHeader("STORAGE"),
          _buildSwitchTile(
            icon: Icons.download_done,
            title: "Offline Mode (Hive)",
            subtitle: "Hla zoh ciami kha internet lo in zoh tthan",
            value: _offlineModeEnabled,
            onChanged: (val) {
              setState(() => _offlineModeEnabled = val);
              _saveSetting('offlineMode', val);
            },
          ),
          _buildListTile(
            icon: Icons.delete_outline,
            title: "Clear Cache",
            subtitle: "Phone memory thianhnak",
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: () => _clearCache(context), // Function kawhnak
          ),

          const SizedBox(height: 25),

          // ================= 4. ABOUT & SUPPORT =================
          _buildSectionHeader("ABOUT"),
          _buildListTile(icon: Icons.info_outline, title: "Terms of Service", onTap: () {}),
          _buildListTile(icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {}),
          _buildListTile(icon: Icons.star_border, title: "Rate on App Store", onTap: () {}),

          const SizedBox(height: 30),

          // ================= 5. LOGOUT BUTTON =================
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton(
              onPressed: () => _handleLogout(context), // Firebase Logout function kawhnak
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 20),
          const Center(child: Text("Laihla Lyrics v1.0.0", style: TextStyle(color: Colors.white38, fontSize: 12))),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, Color textColor = Colors.white, Color iconColor = Colors.white54, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blueAccent,
      secondary: Icon(icon, color: Colors.white54, size: 24),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }
}