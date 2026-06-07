import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // Replace this with your actual iOS public API key from the RevenueCat Dashboard.
  static const String _iosApiKey = 'appl_YOUR_REVENUECAT_IOS_API_KEY_HERE';

  // Entitlement ID defined in the RevenueCat dashboard.
  static const String premiumEntitlementId = 'premium';

  static bool _initialized = false;

  /// Initialize the RevenueCat SDK for iOS
  static Future<void> initialize({String? appUserId}) async {
    if (_initialized) return;

    // RevenueCat IAP is only supported on iOS in this implementation
    if (!kIsWeb && Platform.isIOS) {
      try {
        await Purchases.setLogLevel(LogLevel.debug);
        
        final configuration = PurchasesConfiguration(_iosApiKey);
        if (appUserId != null && appUserId.trim().isNotEmpty) {
          configuration.appUserID = appUserId.trim();
        }
        
        await Purchases.configure(configuration);
        _initialized = true;
        debugPrint('RevenueCat initialized successfully for iOS');
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
    if (!kIsWeb && Platform.isIOS) {
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
    if (_initialized && !kIsWeb && Platform.isIOS) {
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
    if (!kIsWeb && Platform.isIOS) {
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
    if (!kIsWeb && Platform.isIOS) {
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
    if (kIsWeb || !Platform.isIOS) {
      return {
        'success': false,
        'transactionId': null,
        'errorMessage': 'In-App Purchase is only supported on iOS devices.'
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
    if (!kIsWeb && Platform.isIOS) {
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
}
