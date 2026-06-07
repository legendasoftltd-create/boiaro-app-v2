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
  static int _retryCount = 0;
  static const int _maxRetries = 3;

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
    loadRewardedAd(caller: 'AdManager.initialize [app_start]');
  }

  static Future<bool> ensureAdLoaded({
    Duration timeout = const Duration(seconds: 8),
    String caller = 'ensureAdLoaded',
  }) async {
    if (_isAdLoaded) {
      print('[AD] ℹ️  ensureAdLoaded called by [$caller] — already loaded, skipping request.');
      return true;
    }
    print('[AD] ⏳ ensureAdLoaded called by [$caller] — ad not ready, requesting...');
    loadRewardedAd(caller: 'ensureAdLoaded[$caller]');
    try {
      await waitForAd().timeout(timeout);
    } catch (_) {}
    return _isAdLoaded;
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

  /// Internal counter — tracks total ad requests in this session for logging.
  static int _totalRequestCount = 0;

  static void loadRewardedAd({bool resetRetry = false, String caller = 'unknown'}) {
    if (_isAdLoaded || _isAdLoading) return;
    if (resetRetry) _retryCount = 0;

    _totalRequestCount++;
    _isAdLoading = true;

    // ── AD REQUEST LOG ──────────────────────────────────────────────────────
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2,'0')}:'
        '${now.minute.toString().padLeft(2,'0')}:'
        '${now.second.toString().padLeft(2,'0')}';
    print('┌─────────────────────────────────────────────────');
    print('│ [AD REQUEST #$_totalRequestCount] @ $timestamp');
    print('│ Caller  : $caller');
    print('│ Retry   : $_retryCount / $_maxRetries');
    print('│ AdUnitId: $rewardedAdUnitId');
    // Stack trace — shows which function triggered the load
    final stack = StackTrace.current.toString().split('\n');
    final relevantFrames = stack
        .where((line) => line.contains('boiaro') || line.contains('ad_manager'))
        .take(4)
        .join('\n│   ');
    print('│ Stack:\n│   $relevantFrames');
    print('└─────────────────────────────────────────────────');
    // ────────────────────────────────────────────────────────────────────────

    RewardedInterstitialAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback:
          RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
          print('[AD] ✅ Request #$_totalRequestCount LOADED successfully @ $timestamp');
          if (_adCompleter != null && !_adCompleter!.isCompleted) {
            _adCompleter!.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isAdLoaded = false;
          _isAdLoading = false;
          print('[AD] ❌ Request #$_totalRequestCount FAILED: $error');
          if (_adCompleter != null && !_adCompleter!.isCompleted) {
            _adCompleter!.completeError(error);
          }
          // FIX: limit retries to avoid infinite request loop
          if (_retryCount < _maxRetries) {
            _retryCount++;
            print('[AD] 🔄 Retry $_retryCount/$_maxRetries scheduled in 30s (caller: $caller)');
            Future.delayed(const Duration(seconds: 30), () {
              loadRewardedAd(caller: 'retry_from_[$caller]');
            });
          } else {
            print('[AD] 🚫 Max retries reached. No more auto-retries until next user action.');
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
          print('[AD] 👁️  Ad dismissed. Reward earned: $isRewardEarned. Preloading next ad...');
          if (isRewardEarned) {
            onRewardEarned();
          }
          // Preload next ad after user watches one — reset retry counter
          loadRewardedAd(resetRetry: true, caller: 'showRewardedAd.onDismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          _isAdLoaded = false;
          print('[AD] ❌ Ad failed to show: $error. Preloading next ad...');
          loadRewardedAd(resetRetry: true, caller: 'showRewardedAd.onFailedToShow');
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
      // FIX: Don't request a new ad here — ad was never shown to user,
      // so this would generate requests with zero impressions.
      // Ad will be loaded on next natural opportunity.
    }
  }
}
