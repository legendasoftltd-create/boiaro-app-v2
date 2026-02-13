import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;

  // Replace these with your actual Ad Unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1401510952827121/1716336801'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          print('Rewarded Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoaded = false;
          print('Rewarded Ad Failed to Load: $error');
          // Retry loading after 10 seconds
          Future.delayed(Duration(seconds: 10), () => loadRewardedAd());
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function onRewardEarned,
    required BuildContext context,
  }) {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isAdLoaded = false;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned();
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad is loading, please try again in a moment.')),
      );
      loadRewardedAd();
    }
  }
}
