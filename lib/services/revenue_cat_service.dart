import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // Replace this with your actual iOS public API key from the RevenueCat Dashboard.
  static const String _iosApiKey = 'appl_MCimSCMpnugptRSjinNTsOvcdWc';

  // Replace this with your actual Android public API key from the RevenueCat Dashboard.
  // TODO: Replace with your actual Android API Key from RevenueCat
  static const String _androidApiKey = 'goog_YOUR_ANDROID_API_KEY_HERE';

  // Entitlement ID defined in the RevenueCat dashboard.
  static const String premiumEntitlementId = 'premium';

  static bool _initialized = false;

  static const List<double> _iosPriceTiers = [
    0.29, 0.59, 0.99, 1.29, 1.69, 1.99, 2.29, 2.69, 2.99, 3.29, 3.69, 3.99,
    4.29, 4.69, 4.99, 5.29, 5.69, 5.99, 6.99, 7.99, 8.99, 9.99, 12.99, 14.99,
    17.99, 19.99, 24.99, 29.99, 34.99, 39.99
  ];

  static const double _usdToBdtRate = 120.0;

  /// Maps a coin/BDT cost to the closest Apple App Store package ID
  static String getProductIdForCoinCost(int coinCost) {
    double estimatedUsd = coinCost / _usdToBdtRate;
    double closestTier = _iosPriceTiers.first;
    double minDiff = (estimatedUsd - closestTier).abs();

    for (var tier in _iosPriceTiers) {
      double diff = (estimatedUsd - tier).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestTier = tier;
      }
    }

    String tierString = closestTier.toStringAsFixed(2).replaceAll('.', '_');
    return 'com.boiaro.app.tier_$tierString';
  }

  /// Maps a BDT cash price to the closest Apple App Store package ID
  static String getProductIdForBdtPrice(double bdtPrice) {
    double estimatedUsd = bdtPrice / _usdToBdtRate;
    double closestTier = _iosPriceTiers.first;
    double minDiff = (estimatedUsd - closestTier).abs();

    for (var tier in _iosPriceTiers) {
      double diff = (estimatedUsd - tier).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestTier = tier;
      }
    }

    String tierString = closestTier.toStringAsFixed(2).replaceAll('.', '_');
    return 'com.boiaro.app.tier_$tierString';
  }

  /// Initialize the RevenueCat SDK for iOS and Android
  static Future<void> initialize({String? appUserId}) async {
    if (_initialized) return;

    // RevenueCat IAP is supported on iOS and Android
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        await Purchases.setLogLevel(LogLevel.debug);
        
        String apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
        final configuration = PurchasesConfiguration(apiKey);
        if (appUserId != null && appUserId.trim().isNotEmpty) {
          configuration.appUserID = appUserId.trim();
        }
        
        await Purchases.configure(configuration);
        _initialized = true;
        debugPrint('RevenueCat initialized successfully');
      } catch (e, stack) {
        debugPrint('Failed to initialize RevenueCat: $e');
        debugPrint('$stack');
      }
    }
  }

  /// Sync the App User ID when a user logs in
  static Future<void> logIn(String userId) async {
    if (!_initialized) {
      await initialize(appUserId: userId);
      return;
    }
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        await Purchases.logIn(userId);
        debugPrint('RevenueCat: Logged in user: $userId');
      } catch (e) {
        debugPrint('RevenueCat login error: $e');
      }
    }
  }

  /// Log out the user from RevenueCat
  static Future<void> logOut() async {
    if (_initialized && !kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        await Purchases.logOut();
        debugPrint('RevenueCat: Logged out user');
      } catch (e) {
        debugPrint('RevenueCat logout error: $e');
      }
    }
  }

  /// Check if the user currently has active entitlements
  static Future<bool> isUserPremium() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        if (!_initialized) await initialize();
        final customerInfo = await Purchases.getCustomerInfo();
        final isPremium = customerInfo.entitlements.all[premiumEntitlementId]?.isActive ?? false;
        return isPremium;
      } catch (e) {
        debugPrint('Error checking active entitlement: $e');
        return false;
      }
    }
    return false;
  }

  /// Fetch all available offerings/packages configured in RevenueCat
  static Future<Offerings?> getOfferings() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        if (!_initialized) await initialize();
        return await Purchases.getOfferings();
      } catch (e) {
        debugPrint('Error fetching offerings: $e');
        return null;
      }
    }
    return null;
  }

  /// Purchase a subscription plan by finding the package that matches the product ID
  /// Returns a map with {'success': bool, 'transactionId': String?, 'errorMessage': String?}
  static Future<Map<String, dynamic>> purchasePlan(String productIdentifier) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return {
        'success': false,
        'transactionId': null,
        'errorMessage': 'In-App Purchase is only supported on mobile devices.'
      };
    }

    try {
      if (!_initialized) await initialize();

      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        return {
          'success': false,
          'transactionId': null,
          'errorMessage': 'No active offerings found in RevenueCat.'
        };
      }

      // Find the package that matches the product ID
      Package? packageToPurchase;
      for (var package in offerings.current!.availablePackages) {
        if (package.storeProduct.identifier == productIdentifier) {
          packageToPurchase = package;
          break;
        }
      }

      // Fallback: search across all offerings if not found in current
      if (packageToPurchase == null) {
        for (var offering in offerings.all.values) {
          for (var package in offering.availablePackages) {
            if (package.storeProduct.identifier == productIdentifier) {
              packageToPurchase = package;
              break;
            }
          }
          if (packageToPurchase != null) break;
        }
      }

      if (packageToPurchase == null) {
        return {
          'success': false,
          'transactionId': null,
          'errorMessage': 'Product "$productIdentifier" not found in RevenueCat offerings.'
        };
      }

      debugPrint('Initiating RevenueCat purchase for: ${packageToPurchase.storeProduct.identifier}');
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(packageToPurchase));
      final customerInfo = purchaseResult.customerInfo;
      
      final isPremium = customerInfo.entitlements.all[premiumEntitlementId]?.isActive ?? false;
      if (isPremium) {
        // Find transaction ID for the purchase
        final txnId = purchaseResult.storeTransaction.transactionIdentifier;

        return {
          'success': true,
          'transactionId': txnId,
          'errorMessage': null
        };
      } else {
        return {
          'success': false,
          'transactionId': null,
          'errorMessage': 'Purchase succeeded but entitlement remained inactive.'
        };
      }
    } catch (e) {
      final isCancelled = e is PlatformException && 
          PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError;
      
      return {
        'success': false,
        'transactionId': null,
        'errorMessage': isCancelled
            ? 'Purchase cancelled by user.'
            : 'Payment failed: ${e.toString()}'
      };
    }
  }

  /// Restore purchases for the current user
  static Future<bool> restorePurchases() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        if (!_initialized) await initialize();
        final customerInfo = await Purchases.restorePurchases();
        return customerInfo.entitlements.all[premiumEntitlementId]?.isActive ?? false;
      } catch (e) {
        debugPrint('Error restoring purchases: $e');
        return false;
      }
    }
    return false;
  }

  /// Purchase a consumable chapter
  /// Returns a map with {'success': bool, 'transactionId': String?, 'errorMessage': String?}
  static Future<Map<String, dynamic>> purchaseChapter(String productIdentifier) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return {
        'success': false,
        'transactionId': null,
        'errorMessage': 'In-App Purchase is only supported on mobile devices.'
      };
    }

    try {
      if (!_initialized) await initialize();

      debugPrint('Initiating RevenueCat purchase for: $productIdentifier');
      // For consumable products, we can use purchaseProduct directly.
      final purchaseResult = await Purchases.purchaseProduct(
        productIdentifier,
        type: PurchaseType.inapp,
      );
      
      final txnId = purchaseResult.storeTransaction?.transactionIdentifier;

      if (txnId != null) {
        return {
          'success': true,
          'transactionId': txnId,
          'errorMessage': null
        };
      } else {
        return {
          'success': false,
          'transactionId': null,
          'errorMessage': 'Purchase succeeded but transaction ID is missing.'
        };
      }
    } catch (e) {
      final isCancelled = e is PlatformException && 
          PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError;
      
      return {
        'success': false,
        'transactionId': null,
        'errorMessage': isCancelled
            ? 'Purchase cancelled by user.'
            : 'Payment failed: ${e.toString()}'
      };
    }
  }
}
