import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';

// Note: Na Isar Model min he va siksawi te mu (Tahchunhnak ah UserModel kan hman)
// import 'isar/user_model.dart';

class EditProfilePage extends StatefulWidget {
  final Isar isar; // Isar instance kan pass a hau lai

  const EditProfilePage({super.key, required this.isar});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  String _currentImageUrl = '';

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  // ================= 1. CURRENT DATA LAAKNAK =================
  Future<void> _loadCurrentUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Firebase in laak hmasa
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['userName'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _currentImageUrl = data['userImage'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Data laak lio ah palhnak: $e");
    }
  }

  // ================= 2. HMANTHLAK THIMNAK (Compress tuah chih) =================
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 500, // Profile pic caah cun 500px hi a fiah tuk cang, a zang tuk lai
        maxHeight: 500,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hmanthlak thim lio ah palhnak a um.")));
    }
  }

  // ================= 3. SAVE TUAHNAK (R2 + Firebase + Isar) =================
  Future<void> _saveProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Na min tial hrimhrim a hau.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _currentImageUrl;

      // --- A. HMANTHLAK THAR A UM AHCUN R2 AH UPLOAD TUAHNAK ---
      if (_selectedImage != null) {
        String secretKey = 'my-secret-key-123'; // Na Worker Password

        // Hmanthlak thar thunnak
        String fileName = 'avatar_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String workerUrl = 'https://laihla-upload-api.itrungrul.workers.dev/$fileName';
        String r2PublicUrl = 'https://pub-3b204fc7a09240b5b88712d2dba59d46.r2.dev/$fileName';

        final imageBytes = await _selectedImage!.readAsBytes();
        var uploadResponse = await http.put(
          Uri.parse(workerUrl),
          headers: {'Content-Type': 'image/jpeg', 'Authorization': 'Bearer $secretKey'},
          body: imageBytes,
        );

        if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
          finalImageUrl = r2PublicUrl;

          // Hmanthlak hlun a rak ngei cia mi a si ahcun, R2 in phiahnak (Delete)
          if (_currentImageUrl.isNotEmpty && _currentImageUrl.contains('r2.dev')) {
            String oldFileName = _currentImageUrl.split('/').last;
            String deleteUrl = 'https://laihla-upload-api.itrungrul.workers.dev/$oldFileName';
            await http.delete(Uri.parse(deleteUrl), headers: {'Authorization': 'Bearer $secretKey'});
          }
        } else {
          throw Exception("Hmanthlak upload a ngah lo");
        }
      }

      // --- B. FIREBASE AH UPDATE TUAHNAK ---
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'userName': newName,
        'bio': newBio,
        'userImage': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge kan hman caah data dang a rawk lai lo

      // --- C. ISAR LOCAL DB AH UPDATE TUAHNAK ---
      // NOTE: Hika ahhin na Isar Model sining in thlen a hau lai mu. (Tahchunhnak ah UserModel kan hmang)
      /*
      await widget.isar.writeTxn(() async {
        final localUser = await widget.isar.userModels.filter().firestoreIdEqualTo(currentUser.uid).findFirst();
        if (localUser != null) {
          localUser.userName = newName;
          localUser.bio = newBio;
          localUser.userImage = finalImageUrl;
          await widget.isar.userModels.put(localUser);
        }
      });
      */

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Na Profile na remh cang!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Settings page ah a kir tthan lai
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Palhnak a um: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Keyboard thuhnak
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ================= AVATAR (Hmanthlak) =================
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (_currentImageUrl.isNotEmpty ? CachedNetworkImageProvider(_currentImageUrl) : null),
                    child: (_selectedImage == null && _currentImageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.white54)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ================= NAME (Min) =================
            const Text("Display Name", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Na min thengte...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 20),

            // ================= BIO (A tawi in i theihternak) =================
            const Text("Bio (Na Konglam)", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              maxLength: 150, // Ca tial khawh zat ri khiahnak
              decoration: InputDecoration(
                hintText: "Na sining tawi tein tial hmanh...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}