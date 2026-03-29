import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // A THAR: Share tuah khawhnak caah

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "About LaihLa Lyrics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // A THAR: Background ah dawh tukmi dark gradient kan hman
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🌟 Header Card (Logo & App Name)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "LaihLa Lyrics",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Version 1.0.0", // Version na thlen khawh
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Hakha Chin Lyrics & Chords",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✨ About Content Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      // ABOUT SECTION
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text("About", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "LaihLa Lyrics is your go-to app for Hakha Chin song lyrics and chords. We created this app to help singers and guitar players easily access their favorite songs in one place.",
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                      ),
                      SizedBox(height: 20),
                      Divider(color: Colors.white10),
                      SizedBox(height: 10),

                      // FEATURES SECTION
                      Row(
                        children: [
                          Icon(Icons.star_outline, color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 8),
                          Text("Features", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 12),
                      FeatureItem(text: "Browse Hakha Chin lyrics & chords"),
                      FeatureItem(text: "Transpose chords fawi tein tuah khawh"),
                      FeatureItem(text: "Auto-scroll speed thlen khawh"),
                      FeatureItem(text: "Audio track download tuah khawh"),
                      FeatureItem(text: "Dark mode UI dawh te"),

                      SizedBox(height: 20),
                      Divider(color: Colors.white10),
                      SizedBox(height: 10),

                      // HISTORY SECTION
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.greenAccent, size: 20),
                          SizedBox(width: 8),
                          Text("History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "LaihLa Lyrics was launched Sep 25, 2022 on Play Store and App Store. We continue improving the app and adding more songs every month.",
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                      ),

                      SizedBox(height: 20),
                      Divider(color: Colors.white10),
                      SizedBox(height: 10),

                      // NOTE SECTION
                      Row(
                        children: [
                          Icon(Icons.speaker_notes_outlined, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text("Note", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "All lyrics and chords are collected from online sources and shared for personal use. If you want to request songs or report copyright issues, please contact us.",
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🌈 Share App Button
            SizedBox(
              width: double.infinity, // Button kauh (full width) nakhnga
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.share, color: Colors.blueAccent),
                label: const Text(
                  "Share App",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // A BIAPI BIK: Share tuah tikah a lang dingmi bia (Link dik he)
                  final String shareText = "Hakha Chin hla bia le chord (LaihLa Lyrics) app hi rak hmang ve! App Store le Play Store ah download khawh a si.\n\nAndroid: https://play.google.com/store/apps/details?id=chinplus.info.laihlalyrics.laihla_lyrics\niOS: https://apps.apple.com/kr/app/laihla-lyrics/id6479561333";

                  Share.share(shareText);
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// Check icon te he List mawi tein suainak Widget
class FeatureItem extends StatelessWidget {
  final String text;
  const FeatureItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}