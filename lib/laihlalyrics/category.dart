import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Detail page luhnak caah na file min he aa tlak in remh
import '../pages/khrihfa_hlabu.dart';
import 'detail.dart';

class CategorySongsPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;

  const CategorySongsPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  State<CategorySongsPage> createState() => _CategorySongsPageState();
}

class _CategorySongsPageState extends State<CategorySongsPage> {
  final Box _songsBox = Hive.box('songsBox');
  List<Map<String, dynamic>> _categorySongs = [];

  @override
  void initState() {
    super.initState();
    _loadCategorySongs();
  }

  void _loadCategorySongs() {
    // Hive chung in hla dihlak laak hmasa
    List<Map<String, dynamic>> allSongs =
    _songsBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

    if (widget.title == 'Khrihfa Hlabu') {
 Navigator.push(context, MaterialPageRoute(builder: (context)=> KhrihfaHlaBu()));
    } else {
      // A dang Category a si ahcun a category min in thli (Filter) ding
      _categorySongs = allSongs.where((song) => song['category'] == widget.title).toList();
      // A thar bik a cunglei ah langhter
      _categorySongs.sort((a, b) => (b['createdAtInt'] ?? 0).compareTo(a['createdAtInt'] ?? 0));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 24),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: _categorySongs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 60, color: Colors.white24),
            const SizedBox(height: 15),
            Text(
              "${widget.title} ah hla a um rih lo.",
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: _categorySongs.length,
        itemBuilder: (context, index) {
          final song = _categorySongs[index];
          bool isChord = song['isChord'] ?? song['type'] == 'Chord';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.color.withOpacity(0.3)),
              ),
              child: Icon(
                isChord ? Icons.music_note : Icons.my_library_music,
                color: isChord ? Colors.blueAccent : Colors.white70,
              ),
            ),
            title: Text(
              song['title'] ?? 'No Title',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              song['singer'] ?? 'Unknown',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () {
       /*       // Detail Page ah kalnak
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongDetailPage(song: song),
                ),
              );*/
            },
          );
        },
      ),
    );
  }
}