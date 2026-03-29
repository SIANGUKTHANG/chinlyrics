// dart
import 'dart:async';
import 'dart:convert';
import 'package:chinlyrics/pages/home.dart';
import 'package:chinlyrics/user/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constant.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'laihlalyrics/model/post_model.dart';
import 'laihlalyrics/model/song_model.dart';
import 'migrantdata.dart';
import 'notifications/detail.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    print("Background ah notification a phan: ${message.messageId}");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Mah hi true in chiah a hau
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Cache tlum lo ti a um lo nakhnga
  );

  await FirebaseMessaging.instance.getInitialMessage();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
  await Hive.initFlutter();
  await Hive.openBox('downloads');
  downloads = Hive.box('downloads');
  await Hive.openBox('userBox');
  await Hive.openBox('chord');
  await Hive.openBox('songsBox');
  await Hive.openBox('likedBox');
  await Hive.openBox('recentBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('userCacheBox');
  await Hive.openBox('marksBox'); // Bible mark tuahmi khonnak

// Directory lak lio ah await telh deuh hmanh
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      SongModelSchema,
      PostModelSchema,
    ],
    directory: dir.path,
  );

  await importJsonToIsar(isar);
  await OrientationHelper()
      .setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _handleNotificationClick(RemoteMessage message) {
    // 1. HLA A SI AHCUN
    if (message.data['type'] == 'song' || message.data['type'] == 'personal') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(

          builder: (context) => DetailsPage(
            title: message.data['title'] ?? 'No Title',
            chord: message.data['chord'] == 'true', // String in a rat caah boolean ah thlen
            singer: message.data['singer'] ?? '',
            composer: message.data['composer'] ?? '',
            verse1: message.data['verse1'] ?? '',
            verse2: message.data['verse2'] ?? '',
            verse3: message.data['verse3'] ?? '',
            verse4: message.data['verse4'] ?? '',
            verse5: message.data['verse5'] ?? '',
            songtrack: message.data['songtrack'] ?? '',
            chorus: message.data['chorus'] ?? '',
            endingChorus: message.data['endingchorus'] ?? '',
          ),
        ),
      );
    }
    // 2. ANNOUNCEMENT A SI AHCUN
    else if (message.data['type'] == 'announcement') {
      // Announcement Page ah na kalpi khawh hna asiloah Dialog na langhter kho
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(message.notification?.title ?? "Thawngthanh"),
              content: GptMarkdown(message.notification?.body ?? "", onLinkTap: (url, title) async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"))
              ],
            ));
      } else {
        print("Context a um lo caah Dialog langhter khawh a si lo");
      }
    }
  }

  Future<void> _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await messaging.subscribeToTopic('all_users');
    }

    // Case 1: App a thih (Terminated) lio i notification an hmeh tikah
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // App a on cawlh in click action a tuah lai
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(initialMessage);
      });
    }

    // Case 2: App hnu lei (Background) a um lio i notification an hmeh tikah
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      title: 'laihla lyrics',
      debugShowCheckedModeBanner: false,

      home:   AuthCheck(),
    );
  }
}

// Hmangtu a lut ciami a si le si lo a check tu ding Widget
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder hmang in Firebase Auth sining kan ngaihthlap (listen) lai
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // App a on lio te ah loading langhternak
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
                child: CircularProgressIndicator(color: Colors.redAccent)),
          );
        }

        // snapshot chungah data a um ahcun (Login a rak tuah ciami a si ahcun)
        if (snapshot.hasData) {
          return Home(); // Na Home Page ah thlah colh
        }

        // Data a um lo ahcun (Login a tuah rih lo asiloah Logout a tuah ahcun)
        return const LoginPage(); // Login Page ah luhter hmasa
      },
    );
  }
}



// ================= JSON IN ISAR AH DATA THUNNAK =================
Future<void> importJsonToIsar(Isar isar) async {
  try {
    final settingsBox = Hive.box('settingsBox');

    bool hasImported = settingsBox.get('hasImportedJson', defaultValue: false);
    if (hasImported) {
      if (kDebugMode) print("JSON in Isar ah thun cia a si cang. A tuah tthan ti lai lo.");
      return;
    }

    if (kDebugMode) print("JSON data rel thawk a si...");

    String jsonString = await rootBundle.loadString('assets/laihla_songs.json');
    List<dynamic> jsonList = json.decode(jsonString);

    if (jsonList.isEmpty) return;

    List<SongModel> songsToInsert = [];
    int maxTimestamp = 0;

    // ================= SAFE PARSING HELPERS =================
    // String a si zongah int ah a thleng khomi function
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    // String a si zongah bool ah a thleng khomi function
    bool safeBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      return value.toString().toLowerCase() == 'true';
    }

    // 3. JSON data kha SongModel (Isar) format ah thlennak
    for (var data in jsonList) {
      final song = SongModel()
        ..id = data['id']?.toString() ?? ''
        ..title = data['title']?.toString() ?? ''
        ..singer = data['singer']?.toString() ?? ''
        ..soundtrack = data['soundtrack']?.toString()
        ..category = data['category']?.toString() ?? ''
        ..isChord = safeBool(data['isChord'], false)
        ..lyrics = data['lyrics']?.toString() ?? ''
        ..uploaderId = data['uploaderId']?.toString() ?? ''
        ..type = data['type']?.toString() ?? 'hla'
        ..approved = safeBool(data['approved'], true)
        ..likes = safeInt(data['likes'])
        ..comments = safeInt(data['comments'])
        ..createdAt = safeInt(data['createdAt'])
        ..updatedAt = safeInt(data['updatedAt'])
        ..isLikedByMe = false;

      songsToInsert.add(song);

      if (song.updatedAt > maxTimestamp) {
        maxTimestamp = song.updatedAt;
      }
    }

    // 4. Isar ah thunnak
    await isar.writeTxn(() async {
      await isar.songModels.putAll(songsToInsert);
    });

    // 5. Hive ah save tuahnak
    await settingsBox.put('lastSyncTime', maxTimestamp);
    await settingsBox.put('hasImportedJson', true);

    if (kDebugMode) {
      print("Tlamtling tein Hla ${songsToInsert.length} thun a si cang.");
      print("Timestamp thar bik Hive ah save mi: $maxTimestamp");
    }

  } catch (e) {
    if (kDebugMode) print("JSON import palhnak: $e");
  }
}