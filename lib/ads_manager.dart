import 'dart:io';

class AdHelper {
  // RALRIN DING: App Store / Play Store ah na thlah (publish) tikah
  // hi 'true' timi hi 'false' ah thleng hrimhrim te aw!
  static const bool isTestMode = true;

  // 1. Home Banner Ad
  static String get homeBannerAdUnitId {
    if (isTestMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111'; // Android Test ID
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';     // iOS Test ID
    } else {
      // Real IDs (Publish tuah tikah a nung lai)
      if (Platform.isAndroid) return ''; // Android real ID na ngeih ahcun hika ah ra thun te
      if (Platform.isIOS) return 'ca-app-pub-6997241259854420/5018237086';
    }
    throw UnsupportedError('Unsupported platform');
  }

  // 2. Detail Banner Ad
  static String get detailBannerAdUnitId {
    if (isTestMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111'; // Android Test ID
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';     // iOS Test ID
    } else {
      // Real IDs
      if (Platform.isAndroid) return ''; // Android real ID na ngeih ahcun hika ah ra thun te
      if (Platform.isIOS) return 'ca-app-pub-6997241259854420/9686503852';
    }
    throw UnsupportedError('Unsupported platform');
  }

  // 3. Interstitial Ad (Screen khat in a langmi)
  static String get interstitialAdUnitId {
    if (isTestMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712'; // Android Test ID
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';     // iOS Test ID
    } else {
      // Real IDs
      if (Platform.isAndroid) return ''; // Android real ID
      if (Platform.isIOS) return 'ca-app-pub-6997241259854420/5747258844';
    }
    throw UnsupportedError("Unsupported platform");
  }

  // 4. Rewarded Ad (Video zohmi)
  static String get rewardedAdUnitId {
    if (isTestMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917'; // Android Test ID
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';     // iOS Test ID
    } else {
      // Real IDs
      if (Platform.isAndroid) return ''; // Android real ID
      if (Platform.isIOS) return 'ca-app-pub-6997241259854420/7889318403';
    }
    throw UnsupportedError("Unsupported platform");
  }
}