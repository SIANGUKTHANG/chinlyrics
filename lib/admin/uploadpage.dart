import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads_manager.dart';

class UploadSongPage extends StatefulWidget {
  const UploadSongPage({super.key});

  @override
  State<UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends State<UploadSongPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _singerController = TextEditingController();
  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _verse1Controller = TextEditingController();
  final TextEditingController _verse2Controller = TextEditingController();
  final TextEditingController _verse3Controller = TextEditingController();
  final TextEditingController _verse4Controller = TextEditingController();
  final TextEditingController _verse5Controller = TextEditingController();
  final TextEditingController _chorusController = TextEditingController();
  final TextEditingController _endingChorusController = TextEditingController();

  bool _hasChord = false;
  String _selectedCategory = 'hladang';
  bool _isUploading = false;

  // A THAR: Interstitial Ad caah
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  final List<String> categories = [
    'pathian-hla',
    'christmas-hla',
    'kumthar-hla',
    'thitumnak-hla',
    'ram-hla',
    'zun-hla',
    'hladang'
  ];

  @override
  void initState() {
    super.initState();
   // _loadInterstitialAd();
  }

  // Interstitial Ad Load Tuahnak
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId, // ads_manager.dart ah hihi a um a hau
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _finishUploadAndPop(); // Ad an khar tikah Page a kir lai
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _finishUploadAndPop(); // Ad a fail zongah Page cu a kir thiamthiam lai
            },
          );

          setState(() {
            _interstitialAd = ad;
            _isAdReady = true;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd failed to load: $err');
          _isAdReady = false;
        },
      ),
    );
  }

  // Upload Dih In Page Kirnak Function
  void _finishUploadAndPop() {

    if (mounted) Navigator.pop(context, true);
  }

  // Firebase ah thunnak
  Future<void> _uploadSong() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      await FirebaseFirestore.instance.collection('songToEdit').add({
        'title': _titleController.text.trim(),
        'singer': _singerController.text.trim(),
        'composer': _composerController.text.trim(),
        'verse1': _verse1Controller.text.trim(),
        'verse2': _verse2Controller.text.trim(),
        'verse3': _verse3Controller.text.trim(),
        'verse4': _verse4Controller.text.trim(),
        'verse5': _verse5Controller.text.trim(),
        'chorus': _chorusController.text.trim(),
        'endingchorus': _endingChorusController.text.trim(),
        'chord': _hasChord,
        'category': _selectedCategory,
        'status': 'pending',
        'type': 'upload',
        'timestamp': FieldValue.serverTimestamp(),
        'uploaderUid': currentUser?.uid,
        'uploaderEmail': currentUser?.email ?? 'Unknown'
      });

      // Firebase thun a lim bakah Ad a lang lai
      if (_isAdReady && _interstitialAd != null) {
        _interstitialAd!.show().then((e)=>{
          _finishUploadAndPop()
        });
      } else {
        // Ad a rak um lo asiloah internet a chiat ahcun Ad lang lo in a kir colh lai
        _finishUploadAndPop();
      }

    } catch (e) {

    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose(); // Ad dispose tuah chih a herh
    _titleController.dispose();
    _singerController.dispose();
    _composerController.dispose();
    _verse1Controller.dispose();
    _verse2Controller.dispose();
    _verse3Controller.dispose();
    _verse4Controller.dispose();
    _verse5Controller.dispose();
    _chorusController.dispose();
    _endingChorusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black12,
        title: const Text('Upload New Song', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hla Konglam (Info)", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_titleController, 'Hla Min (Title) *', isRequired: true),
              _buildTextField(_singerController, 'Satu (Singer)'),
              _buildTextField(_composerController, 'Phantu (Composer)'),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    value: _selectedCategory,
                    style: const TextStyle(color: Colors.white),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text("Chord a tel maw?", style: TextStyle(color: Colors.white)),
                checkColor: Colors.white,
                activeColor: Colors.redAccent,
                tileColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                value: _hasChord,
                onChanged: (bool? value) {
                  setState(() {
                    _hasChord = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),

              const Text("Hla Bia (Lyrics)", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_verse1Controller, 'Verse 1', maxLines: 4),
              _buildTextField(_chorusController, 'Chorus (Thunnak)', maxLines: 4),
              _buildTextField(_verse2Controller, 'Verse 2', maxLines: 4),
              _buildTextField(_verse3Controller, 'Verse 3', maxLines: 4),
              _buildTextField(_verse4Controller, 'Verse 4', maxLines: 4),
              _buildTextField(_verse5Controller, 'Verse 5', maxLines: 4),
              _buildTextField(_endingChorusController, 'Ending Chorus (A donghnak)', maxLines: 3),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _uploadSong,
                  child: const Text('UPLOAD SONG', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '$label cu tial hrimhrim a hau';
          }
          return null;
        },
      ),
    );
  }
}