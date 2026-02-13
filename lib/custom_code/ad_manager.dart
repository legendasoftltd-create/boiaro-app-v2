import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  static bool _isAdLoading = false;
  static Completer<void>? _adCompleter;

  static bool get isAdLoaded => _isAdLoaded;

  static Future<void> waitForAd() async {
    if (_isAdLoaded) return;
    if (_adCompleter == null || _adCompleter!.isCompleted) {
      _adCompleter = Completer<void>();
    }
    return _adCompleter!.future;
  }

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
    // Don't load ad immediately to save requests
  }

  static void loadRewardedAd() {
    if (_isAdLoaded || _isAdLoading) return;

    _isAdLoading = true;
    print('Ad loading started...');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
          print('Rewarded Ad Loaded');
          if (_adCompleter != null && !_adCompleter!.isCompleted) {
            _adCompleter!.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoaded = false;
          _isAdLoading = false;
          print('Rewarded Ad Failed to Load: $error');
          if (_adCompleter != null && !_adCompleter!.isCompleted) {
            _adCompleter!.completeError(error);
          }
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function onRewardEarned,
    required BuildContext context,
    Function? onAdFailed,
  }) {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isAdLoaded = false;
          // Don't auto-reload here, wait for next request
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          if (onAdFailed != null) onAdFailed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned();
        },
      );
    } else {
      if (onAdFailed != null) onAdFailed();
      loadRewardedAd();
    }
  }
}
