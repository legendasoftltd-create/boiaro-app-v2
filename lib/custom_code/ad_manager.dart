import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static RewardedInterstitialAd? _rewardedInterstitialAd;
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

  // Rewarded Interstitial Ad Unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1401510952827121/6858828755';
    } else if (Platform.isIOS) {
      // Replace with your iOS rewarded interstitial unit id when available.
      return 'ca-app-pub-3940256099942544/6978759866';
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
    print('Rewarded interstitial loading started...');
    RewardedInterstitialAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback:
          RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
          print('Rewarded interstitial loaded');
          if (_adCompleter != null && !_adCompleter!.isCompleted) {
            _adCompleter!.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isAdLoaded = false;
          _isAdLoading = false;
          print('Rewarded interstitial failed to load: $error');
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
    if (_isAdLoaded && _rewardedInterstitialAd != null) {
      bool isRewardEarned = false;
      _rewardedInterstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _isAdLoaded = false;
          if (isRewardEarned) {
            onRewardEarned();
          }
          // Don't auto-reload here, wait for next request
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _isAdLoaded = false;
          if (onAdFailed != null) onAdFailed();
        },
      );

      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          isRewardEarned = true;
        },
      );
    } else {
      if (onAdFailed != null) onAdFailed();
      loadRewardedAd();
    }
  }
}
