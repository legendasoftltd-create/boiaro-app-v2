import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static Future<bool> canShowAd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      final lastAdDate = prefs.getString('ad_last_date') ?? "";
      int adsShownToday = prefs.getInt('ad_count_today') ?? 0;
      
      if (lastAdDate != todayStr) {
        adsShownToday = 0;
        await prefs.setString('ad_last_date', todayStr);
        await prefs.setInt('ad_count_today', 0);
      }
      
      if (adsShownToday >= 20) {
        print('Ad frequency check: Max 20 ads reached for today.');
        return false; // Max 20 ads per day
      }
      
      final lastAdTimeMs = prefs.getInt('ad_last_time_ms') ?? 0;
      if (lastAdTimeMs > 0) {
        final lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastAdTimeMs);
        final difference = now.difference(lastAdTime).inMinutes;
        if (difference < 3) {
          print('Ad frequency check: Under 3 minutes difference (was $difference min).');
          return false; // 3 min difference not met
        }
      }
      
      return true;
    } catch (e) {
      print('Error in canShowAd: $e');
      return true; // Fallback to allowing ad
    }
  }

  static Future<void> recordAdShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      
      final lastAdDate = prefs.getString('ad_last_date') ?? "";
      int adsShownToday = prefs.getInt('ad_count_today') ?? 0;
      
      if (lastAdDate != todayStr) {
        adsShownToday = 0;
        await prefs.setString('ad_last_date', todayStr);
      }
      
      await prefs.setInt('ad_count_today', adsShownToday + 1);
      await prefs.setInt('ad_last_time_ms', now.millisecondsSinceEpoch);
      print('Ad recorded: count today = ${adsShownToday + 1}');
    } catch (e) {
      print('Error in recordAdShown: $e');
    }
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
          recordAdShown();
        },
      );
    } else {
      if (onAdFailed != null) onAdFailed();
      loadRewardedAd();
    }
  }
}
