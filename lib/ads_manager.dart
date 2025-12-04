import 'dart:io';

class AdHelper {

  static String get homeBannerAdUnitId {
   if (Platform.isIOS) {

      return    //real id
               'ca-app-pub-6997241259854420/5018237086';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }


  static String get detailBannerAdUnitId {
   if (Platform.isIOS) {

                //real id
     return 'ca-app-pub-6997241259854420/9686503852';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }



  static String get interstitialAdUnitId {
  if (Platform.isIOS) {
      return "ca-app-pub-6997241259854420/5747258844";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
  if (Platform.isIOS) {
      return "ca-app-pub-6997241259854420/7889318403";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}


