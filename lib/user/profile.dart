import 'package:chinlyrics/about.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../firebase/auth.dart';
import '../pages/setting.dart';
import 'edit_profile.dart';
import 'login.dart';
import 'my_upload_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 1. "final" timi kha kan hloh lai, cun setState ah kan thleng kho cang lai
  User? user;
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // 2. Page on thawk ah User data kan lak hmasa
    user = FirebaseAuth.instance.currentUser;
  }

  // 3. User Data a thar in laak tthannak Function
  void _refreshUser() {
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  void _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _authService.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const LoginPage()));

    } catch (e) {

    } finally {
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              // 4. A BIAPI BIK: Edit Page in a rak kir tikah _refreshUser() kan auh lai
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              ).then((_) {
                _refreshUser(); // Hmanthlak le Min a thar in a lang colh cang lai
              });
            },
            icon: const Icon(Icons.edit, color: Colors.white),
          )
        ],
      ),
      body: user == null
          ? const Center(
          child: Text("Data hmuh a si lo. Login na tuah lo sual maw?",
              style: TextStyle(color: Colors.white)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Profile Picture
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: user!.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user!.photoURL == null
                      ? const Icon(Icons.person, size: 55, color: Colors.white54)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              user!.displayName ?? "Chin Lyrics User",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Email
            Text(
              user!.email ?? "No Email Provided",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Menu Items
            _buildProfileOption(
              icon: Icons.cloud_upload,
              title: "My Uploaded Songs",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyUploadedSongsPage()));
              },
            ),
            _buildProfileOption(
              icon: Icons.settings,
              title: "App Settings",
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Setting()));
              },
            ),
            _buildProfileOption(
              icon: Icons.info_outline,
              title: "About App",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
              },
            ),

            const SizedBox(height: 30),

            // Logout Button
            _isLoggingOut
                ? const CircularProgressIndicator(color: Colors.redAccent)
                : SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _showLogoutConfirmDialog,
                icon: const Icon(Icons.logout),
                label: const Text("LOG OUT",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Log Out?", style: TextStyle(color: Colors.white)),
        content: const Text("Taktak in chuah na duh maw?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("Yes, Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}