import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  // User info laak cia nak
  String _userName = 'Laihla lyrics user';
  String _userImage = '';

  // ================= A THAR: HMANTHLAK CAAH =================
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = []; // List in kan laak cang lai

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final Box userCacheBox = Hive.box('userCacheBox');
      final cachedUser = userCacheBox.get(currentUser.uid);

      if (cachedUser != null) {
        setState(() {
          _userName = cachedUser['name'] ?? 'Laihla lyrics user';
          _userImage = cachedUser['photoUrl'] ?? '';
        });
      }
    }
  }

// ================= HMANTHLAK THIMNAK LE COMPRESS TUAHNAK =================
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 35,    // 50 in 35 ah kan tthumh cang
        maxWidth: 800,       // 1080 in 800 ah kan tthumh cang (Size a zang tuk cang lai)
        maxHeight: 800,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_selectedImages.length < 5) {
              _selectedImages.add(File(file.path));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hmanthlak thim lio ah palhnak a um.")));
    }
  }

  // ================= FIREBASE AH THUNNAK =================
  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    // Ca asiloah hmanthlak pakhat tal a um a hau
    if (content.isEmpty && _selectedImage == null) return;

    setState(() => _isLoading = true);
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
// ================= 1. CLOUDFLARE R2 AH HMANTHLAK THUNNAK =================
      List<String> uploadedImageUrls = []; // Link zapi khonnak

      if (_selectedImages.isNotEmpty) {
        String secretKey = 'my-secret-key-123'; // Na password taktak in thleng

        for (int i = 0; i < _selectedImages.length; i++) {
          // File min ah index [i] kan chap chih lai (An i khat sual lo nakhnga)
          String fileName = 'forum_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          String workerUrl = 'https://laihla-upload-api.itrungrul.workers.dev/$fileName';
          String r2PublicUrl = 'https://pub-3b204fc7a09240b5b88712d2dba59d46.r2.dev/$fileName';

          final imageBytes = await _selectedImages[i].readAsBytes();

          var response = await http.put(
            Uri.parse(workerUrl),
            headers: {'Content-Type': 'image/jpeg', 'Authorization': 'Bearer $secretKey'},
            body: imageBytes,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            uploadedImageUrls.add(r2PublicUrl); // A tlamtling mi kha list ah kan thun
          } else {
            throw Exception("Hmanthlak kuatnak ah palhnak a um.");
          }
        }
      }
      // ========================================================================

      // 2. 'posts' timi collection ah Data thunnak
      await FirebaseFirestore.instance.collection('posts').add({
        'uploaderId': currentUser?.uid ?? 'unknown',
        'userName': _userName,
        'userImage': _userImage,
        'content': content,
        'imageUrls': uploadedImageUrls ?? '', // A thar: Hmanthlak URL (A um lo ahcun text lawng)
        'likes': 0,
        'comments': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Thun lio ah palhnak a um: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isButtonEnabled = (_contentController.text.trim().isNotEmpty || _selectedImage != null) && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Post Thar Tialnak", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ElevatedButton(
              onPressed: isButtonEnabled ? _submitPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                disabledBackgroundColor: Colors.blueAccent.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _userImage.isNotEmpty ? CachedNetworkImageProvider(_userImage) : null,
                        child: _userImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(height: 0.3, color: Colors.white12,),
                  const SizedBox(height: 15),

                  // Text Input Area
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
                    onChanged: (text) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: "Zeidah tial na duh? Na ruahmi asiloah hmuhtonmi tial...",
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
                      border: InputBorder.none,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= HMANTHLAK PREVIEW =================
                  // ================= HMANTHLAK PREVIEW (MULTI-IMAGE) =================
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 120, // Hmanthlak hmete in a lang lai
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Cancel Button (Phiahnak)
                              Positioned(
                                top: 5, right: 15,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(

            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.greenAccent, size: 28),
                    onPressed: _pickImages,
                    tooltip: "Hmanthlak thunnak",
                  ),
                ],
              ),
            ),
          ),
          // ================= BOTTOM BAR (Hmanthlak add nak) =================

        ],
      ),
    );
  }
}