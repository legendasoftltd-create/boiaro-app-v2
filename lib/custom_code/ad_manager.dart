import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class AdManager {
  // Rewarded Ad state
  static RewardedAd? _rewardedAd;
  static bool _isRewardedLoaded = false;
  static bool _isRewardedLoading = false;
  static Completer<void>? _rewardedCompleter;

  // Interstitial Ad state
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoaded = false;
  static bool _isInterstitialLoading = false;
  static Completer<void>? _interstitialCompleter;

  // Backwards compatibility getters
  static bool get isAdLoaded => _isRewardedLoaded;
  static bool get isRewardedLoaded => _isRewardedLoaded;
  static bool get isInterstitialLoaded => _isInterstitialLoaded;

  // Wait functions
  static Future<void> waitForAd() async {
    if (_isRewardedLoaded) return;
    if (_rewardedCompleter == null || _rewardedCompleter!.isCompleted) {
      _rewardedCompleter = Completer<void>();
    }
    return _rewardedCompleter!.future;
  }

  static Future<void> waitForInterstitial() async {
    if (_isInterstitialLoaded) return;
    if (_interstitialCompleter == null || _interstitialCompleter!.isCompleted) {
      _interstitialCompleter = Completer<void>();
    }
    return _interstitialCompleter!.future;
  }

  // Rewarded Ad Unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1401510952827121/6858828755';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1401510952827121/2605414398'; // R001
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  // Interstitial Ad Unit IDs
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Test ad unit ID for Android Interstitial (since no production one is specified)
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1401510952827121/7435069248'; // I001
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static Future<void> initialize() async {
    if (Platform.isIOS) {
      try {
        final status = await Permission.appTrackingTransparency.request();
        print('AdManager: App Tracking Transparency request status: $status');
      } catch (e) {
        print('AdManager: Error requesting App Tracking Transparency: $e');
      }
    }
    await MobileAds.instance.initialize();
    loadRewardedAd();
    loadInterstitialAd();
  }

  static Future<bool> ensureAdLoaded({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    return ensureRewardedLoaded(timeout: timeout);
  }

  static Future<bool> ensureRewardedLoaded({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_isRewardedLoaded) return true;
    loadRewardedAd();
    try {
      await waitForAd().timeout(timeout);
    } catch (_) {}
    return _isRewardedLoaded;
  }

  static Future<bool> ensureInterstitialLoaded({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_isInterstitialLoaded) return true;
    loadInterstitialAd();
    try {
      await waitForInterstitial().timeout(timeout);
    } catch (_) {}
    return _isInterstitialLoaded;
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

  // --- Rewarded Ad Loading and Showing ---
  static void loadRewardedAd() {
    if (_isRewardedLoaded || _isRewardedLoading) return;

    _isRewardedLoading = true;
    print('Rewarded ad loading started...');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          _isRewardedLoading = false;
          print('Rewarded ad loaded successfully');
          if (_rewardedCompleter != null && !_rewardedCompleter!.isCompleted) {
            _rewardedCompleter!.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoaded = false;
          _isRewardedLoading = false;
          print('Rewarded ad failed to load: $error');
          if (_rewardedCompleter != null && !_rewardedCompleter!.isCompleted) {
            _rewardedCompleter!.completeError(error);
          }
          Future.delayed(const Duration(seconds: 15), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function onRewardEarned,
    required BuildContext context,
    Function? onAdFailed,
  }) {
    if (_isRewardedLoaded && _rewardedAd != null) {
      bool isRewardEarned = false;
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedLoaded = false;
          if (isRewardEarned) {
            onRewardEarned();
          }
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedLoaded = false;
          loadRewardedAd();
          if (onAdFailed != null) onAdFailed();
        },
      );

      _rewardedAd!.show(
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

  // --- Interstitial Ad Loading and Showing ---
  static void loadInterstitialAd() {
    if (_isInterstitialLoaded || _isInterstitialLoading) return;

    _isInterstitialLoading = true;
    print('Interstitial ad loading started...');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _isInterstitialLoading = false;
          print('Interstitial ad loaded successfully');
          if (_interstitialCompleter != null && !_interstitialCompleter!.isCompleted) {
            _interstitialCompleter!.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          _isInterstitialLoading = false;
          print('Interstitial ad failed to load: $error');
          if (_interstitialCompleter != null && !_interstitialCompleter!.isCompleted) {
            _interstitialCompleter!.completeError(error);
          }
          Future.delayed(const Duration(seconds: 15), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  static void showInterstitialAd({
    required Function onAdClosed,
    required BuildContext context,
    Function? onAdFailed,
  }) {
    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          recordAdShown();
          onAdClosed();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          loadInterstitialAd();
          if (onAdFailed != null) onAdFailed();
        },
      );

      _interstitialAd!.show();
    } else {
      if (onAdFailed != null) onAdFailed();
      loadInterstitialAd();
    }
  }
}
