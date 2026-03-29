import 'package:chinlyrics/laihlalyrics/setting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import 'admin/admin_approval.dart';
import 'detail.dart';
import 'model/song_model.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late Isar isar;

  bool _isLoading = true;

  List<SongModel> _mySongs = [];
  List<SongModel> _likedSongs = [];

  int _totalLikesReceived = 0;

  // Tab thimnak (0 = Ka Thunmi, 1 = Ka Uarmi)
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    isar = Isar.getInstance()!;
    _fetchProfileData();
  }
  Future<void> _fetchProfileData() async {
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ================= 1. MY SONGS (FROM ISAR) =================
      final mySongs = await isar.songModels
          .filter()
          .uploaderIdEqualTo(currentUser!.uid)
          .sortByCreatedAtDesc()
          .findAll();

      // ================= 2. LIKED SONGS (FROM ISAR) =================
      final likedSongs = await isar.songModels
          .filter()
          .isLikedByMeEqualTo(true)
          .findAll();

      // ================= 3. TOTAL LIKES =================
      int likesCount = 0;
      for (var song in mySongs) {
        likesCount += song.likes;
      }

      setState(() {
        _mySongs = mySongs;
        _likedSongs = likedSongs;
        _totalLikesReceived = likesCount;
        _isLoading = false;
      });
    } catch (e) {
      print("Isar profile error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Logout hnu ah page thlengnak hika ah peh
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.white24),
              const SizedBox(height: 20),
              const Text("Profile zoh dingin Login tuah a hau", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {}, // Login page luhnak
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("Login Tuah", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    // A tu lio langhter dingmi List (Tab ning in)
    List<SongModel> currentList = _selectedTabIndex == 0 ? _mySongs : _likedSongs;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Ka Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=> SettingsPage()));
          }),
        ],
      ),
      floatingActionButton: currentUser?.email == "itrungrul@gmail.com"?FloatingActionButton(onPressed: (){
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApproval()));
      },child: Icon(Icons.admin_panel_settings),):null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
        children: [
          // ================= 1. PROFILE HEADER =================
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[800],
            backgroundImage: currentUser!.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
            child: currentUser!.photoURL == null
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 15),
          Text(
              currentUser!.displayName ?? 'Laihla User',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 5),
          Text(currentUser!.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14)),

          const SizedBox(height: 30),

          // ================= 2. STATS ROW =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn("Hla Thunmi", "${_mySongs.length}"),
              _buildStatColumn("Like Hmuhmi", "$_totalLikesReceived"),
              _buildStatColumn("Uarmi (Liked)", "${_likedSongs.length}"), // Liked nambat
            ],
          ),

          const SizedBox(height: 25),

          // ================= 3. CUSTOM TABS =================
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
            ),
            child: Row(
              children: [
                _buildTabItem(title: "Ka Thunmi", index: 0),
                _buildTabItem(title: "Ka Uarmi", index: 1),
              ],
            ),
          ),

          // ================= 4. SONG LIST =================
          Expanded(
            child: currentList.isEmpty
                ? Center(
              child: Text(
                  _selectedTabIndex == 0 ? "Hla na thun rih lo." : "Like na tuahmi hla a um rih lo.",
                  style: const TextStyle(color: Colors.white54)
              ),
            )
                : ListView.builder(
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                final song = currentList[index];
                bool isChord = song.isChord ;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                        isChord ? Icons.music_note : Icons.my_library_music,
                        color: isChord ? Colors.blueAccent : Colors.green
                    ),
                  ),
                  title: Text(song.title ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("${song.singer ?? 'Unknown'} • ${song.likes ?? 0} Likes", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailPage(song: song)));

                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Stats langhternak
  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  // Tab Menu hmehnak
  Widget _buildTabItem({required String title, required int index}) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 3
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}