import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ad unit ID per Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ad unit ID per iOS
    } else {
      throw UnsupportedError('Piattaforma non supportata');
    }
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Ad caricato.'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad fallito nel caricamento: $error');
        },
      ),
    );
  }
}