import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart'; // A THAR: Delete signature tuahnak caah

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  TextEditingController nameController = TextEditingController();

  File? _imageFile;
  bool isSaving = false;
  String existingPhotoUrl = '';

  // --- CLOUDINARY INFO ---
  // Hika ah hin na Cloudinary info taktak va thun mu!
  final String cloudName = 'dlvczq7dp';
  final String uploadPreset = 'profile';

  // A THAR: Delete tuahnak caah a herhmi API Key le Secret
  final String apiKey = '237753499252855'; // Root i na API Key
  final String apiSecret = 'sllgNCfNYnbzKqQnKXXhXf9_LhM';

  @override
  void initState() {
    super.initState();
    nameController.text = currentUser?.displayName ?? '';
    existingPhotoUrl = currentUser?.photoURL ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- 1. Cloudinary ah Upload Tuahnak ---
  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        if (kDebugMode) {
          print("Cloudinary Upload Error: ${response.statusCode}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Upload failed: $e");
      }
      return null;
    }
  }

  // --- 2. Cloudinary in A Hlun Hlohnak (Delete) ---
  Future<void> _deleteOldImageFromCloudinary(String oldUrl) async {
    if (oldUrl.isEmpty || !oldUrl.contains('cloudinary.com')) return;

    try {
      // Step A: Link chung in Public ID laak hmasat a hau
      Uri uri = Uri.parse(oldUrl);
      List<String> segments = uri.pathSegments;
      int uploadIndex = segments.indexOf('upload');

      if (uploadIndex == -1 || uploadIndex + 2 >= segments.length) return;

      // Version number (v1234567) hnu i a ummi kha Public ID a si
      String publicIdWithExtension = segments.sublist(uploadIndex + 2).join('/');
      String publicId = publicIdWithExtension.substring(0, publicIdWithExtension.lastIndexOf('.'));

      // Step B: Signature ser (API Secret hmang in)
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      String stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';

      var bytes = utf8.encode(stringToSign);
      var digest = sha1.convert(bytes);
      String signature = digest.toString();

      // Step C: Delete API call tuah
      final deleteUri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
      final response = await http.post(
        deleteUri,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("A hlun hmanthlak Cloudinary in hloh a si cang.");
        }
      } else {
        if (kDebugMode) {
          print("Delete Error: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Delete failed: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      String photoUrlToSave = existingPhotoUrl;
      bool imageChanged = false;

      // Hmanthlak thar a thim ahcun Cloudinary ah upload hmasa
      if (_imageFile != null) {
        String? cloudinaryUrl = await _uploadToCloudinary(_imageFile!);
        if (cloudinaryUrl != null) {
          photoUrlToSave = cloudinaryUrl;
          imageChanged = true; // Hmanthlak aa thleng ti kan theih nakhnga
        } else {
          setState(() => isSaving = false);
          return;
        }
      }

      // Firebase Authentication update
      await currentUser!.updateProfile(
        displayName: nameController.text.trim(),
        photoURL: photoUrlToSave,
      );

      // Firestore ah User info save chih
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'uid': currentUser!.uid,
        'email': currentUser!.email,
        'displayName': nameController.text.trim(),
        'photoUrl': photoUrlToSave,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await currentUser!.reload();

      // A BIAPI BIK: Profile thar kan save dih in a hlun kha kan delete cang lai
      if (imageChanged && existingPhotoUrl.isNotEmpty) {
        await _deleteOldImageFromCloudinary(existingPhotoUrl);
      }


      if (mounted) Navigator.pop(context);

    } catch (e) {
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSaving) {
          // Kir a zuam nain loading lio a si caah Toast in kan theihter
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white10,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (existingPhotoUrl.isNotEmpty
                            ? NetworkImage(existingPhotoUrl)
                            : null),
                        child: (_imageFile == null && existingPhotoUrl.isEmpty)
                            ? const Icon(Icons.person, size: 60, color: Colors.white54)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSaving ? null : _saveProfile,
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Save Profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}