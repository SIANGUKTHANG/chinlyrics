import 'package:flutter/material.dart';

class PrivacyTermsPage extends StatelessWidget {
  const PrivacyTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Terms & Privacy",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TERMS AND CONDITIONS =================
            const Text(
              "Community Guidelines (Terms)",
              style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildSection(
              icon: Icons.shield_outlined,
              iconColor: Colors.greenAccent,
              title: "Respectful Conduct & Purpose",
              description: "We aim to build a positive and uplifting community dedicated to Christian fellowship, as well as the preservation and sharing of Chin literature and culture. Hate speech, harassment, bullying, or abusive language is strictly prohibited.",
            ),

            _buildSection(
              icon: Icons.description_outlined,
              iconColor: Colors.orangeAccent,
              title: "User-Generated Content (UGC)",
              description: "You are solely responsible for the content, lyrics, literature, and images you upload. Do not post copyrighted materials without permission.",
            ),

            _buildSection(
              icon: Icons.block,
              iconColor: Colors.redAccent,
              title: "Zero Tolerance & Moderation",
              description: "We have a zero-tolerance policy for objectionable content. We reserve the right to remove inappropriate content and permanently ban the offending user's account without prior notice.",
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 10),

            // ================= PRIVACY POLICY =================
            const Text(
              "Privacy Policy",
              style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildSection(
              icon: Icons.cloud_outlined,
              iconColor: Colors.lightBlueAccent,
              title: "Information & Google Sign-In",
              description: "We use Google Sign-In for secure authentication. We collect basic profile information (display name, email) and the content you share. You can manage access from your Google Account settings.",
            ),

            _buildSection(
              icon: Icons.ads_click,
              iconColor: Colors.yellowAccent,
              title: "Advertising (AdMob)",
              description: "To keep this app free, we use Google AdMob. AdMob may collect device identifiers and usage data to provide personalized ads in accordance with Google's privacy policy. We do not sell your personal data.",
            ),

            _buildSection(
              icon: Icons.delete_outline,
              iconColor: Colors.pinkAccent,
              title: "Data Retention & Deletion",
              description: "You maintain full control over your data. You can delete your posts at any time. You can also request full account deletion from the app settings to permanently remove your data from our servers.",
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPER WIDGET =================
  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}