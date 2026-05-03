import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result class for social login operations
class SocialLoginResult {
  final bool success;
  final ApiCallResponse? response;
  final String? errorMessage;
  final bool needsEmail;
  final Map<String, dynamic>? userData;

  SocialLoginResult({
    required this.success,
    this.response,
    this.errorMessage,
    this.needsEmail = false,
    this.userData,
  });

  factory SocialLoginResult.successResult(ApiCallResponse response) {
    return SocialLoginResult(
      success: true,
      response: response,
    );
  }

  factory SocialLoginResult.errorResult(String message) {
    return SocialLoginResult(
      success: false,
      errorMessage: message,
    );
  }

  factory SocialLoginResult.needsEmailResult(Map<String, dynamic> userData) {
    return SocialLoginResult(
      success: false,
      needsEmail: true,
      userData: userData,
    );
  }
}

class SocialLoginRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  SocialLoginRepository() {
    _googleSignIn.initialize(
      serverClientId:
          '961638140230-6pp8ubuhsisl4jje5l18cub3c2sakomd.apps.googleusercontent.com',
    );
  }

  Future<ApiCallResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();
      if (googleUser == null) {
        return null;
      }

      // 1. Get ID Token for Identity (used by Supabase Auth)
      final googleAuth = await googleUser.authentication;
      final idToken = (googleAuth.idToken ?? '').trim();

      // 2. Get Access Token for Authorization (optional if backend only needs idToken, but we send both)
      final authClient = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      final accessToken = (authClient.accessToken ?? '').trim();
      
      if (idToken.isEmpty && accessToken.isEmpty) {
        debugPrint('Google sign in error: missing both idToken and accessToken');
        return null;
      }
      final String? deviceId = FFAppState().deviceId;
      final String? fcmToken = FFAppState().tokenFcm;

      return EbookGroup.socialLoginCall.call(
        email: googleUser.email,
        firstname: googleUser.displayName?.split(' ').first ?? '',
        lastname: googleUser.displayName?.split(' ').last ?? '',
        username: googleUser.displayName ?? '',
        provider: 'google',
        providerId: googleUser.id,
        accessToken: accessToken,
        idToken: idToken,
        registrationToken: fcmToken,
        deviceId: deviceId,
      );
    } catch (error) {
      debugPrint('Google sign in error: $error');
      return null;
    }
  }

  Future<SocialLoginResult> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final fbAccessToken = result.accessToken?.tokenString ?? '';
        if (fbAccessToken.trim().isEmpty) {
          return SocialLoginResult.errorResult('Facebook access token missing');
        }
        final userData = await FacebookAuth.instance.getUserData();
        final String? userId = userData['id'] as String?;

        if (userId == null) {
          debugPrint('Facebook login failed: Could not retrieve user ID');
          return SocialLoginResult.errorResult(
              'Could not retrieve user information from Facebook');
        }

        String? email = userData['email'] as String?;

        // Check if email is missing or empty
        if (email == null || email.isEmpty) {
          debugPrint('Facebook login: Email not provided by Facebook');

          // Try to get cached email for this Facebook user ID
          final cachedEmail = await _getCachedEmail(userId);
          if (cachedEmail != null && cachedEmail.isNotEmpty) {
            debugPrint('Facebook login: Using cached email');
            email = cachedEmail;
          } else {
            // No cached email, need to ask user
            debugPrint('Facebook login: No cached email, requesting from user');
            return SocialLoginResult.needsEmailResult({
              ...userData,
              '__accessToken': fbAccessToken,
            });
          }
        }

        // Email is available (either from Facebook or cache), proceed with login
        return await _completeFacebookLogin(
          userData,
          email,
          fbAccessToken,
        );
      } else {
        debugPrint('Facebook sign in failed: ${result.message}');
        return SocialLoginResult.errorResult(
            result.message ?? 'Facebook login failed');
      }
    } catch (error) {
      debugPrint('Facebook sign in error: $error');
      return SocialLoginResult.errorResult(
          'An error occurred during Facebook login');
    }
  }

  /// Complete Facebook login with provided email
  Future<SocialLoginResult> completeFacebookLoginWithEmail(
    Map<String, dynamic> userData,
    String email,
    String accessToken,
  ) async {
    return await _completeFacebookLogin(userData, email, accessToken);
  }

  Future<SocialLoginResult> _completeFacebookLogin(
    Map<String, dynamic> userData,
    String email,
    String accessToken,
  ) async {
    try {
      final String? deviceId = FFAppState().deviceId;
      final String? fcmToken = FFAppState().tokenFcm;
      final String? userId = userData['id'] as String?;
      final String? name = userData['name'] as String?;
      final String? firstName = userData['first_name'] as String? ??
          (name != null ? name.split(' ').first : '');
      final String? lastName = userData['last_name'] as String? ??
          (name != null && name.split(' ').length > 1
              ? name.split(' ').sublist(1).join(' ')
              : '');

      final response = await EbookGroup.socialLoginCall.call(
        email: email,
        firstname: firstName ?? '',
        lastname: lastName ?? '',
        username: name ?? '',
        provider: 'facebook',
        providerId: userId,
        accessToken: accessToken,
        registrationToken: fcmToken,
        deviceId: deviceId,
      );

      // Cache the email for future logins if userId is available
      if (userId != null) {
        await _cacheEmail(userId, email);
      }

      return SocialLoginResult.successResult(response);
    } catch (error) {
      debugPrint('Facebook login completion error: $error');
      return SocialLoginResult.errorResult('Failed to complete login');
    }
  }

  /// Get cached email for a Facebook user ID
  Future<String?> _getCachedEmail(String facebookUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fb_email_$facebookUserId');
    } catch (error) {
      debugPrint('Error getting cached email: $error');
      return null;
    }
  }

  /// Cache email for a Facebook user ID
  Future<void> _cacheEmail(String facebookUserId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fb_email_$facebookUserId', email);
      debugPrint('Cached email for Facebook user: $facebookUserId');
    } catch (error) {
      debugPrint('Error caching email: $error');
    }
  }
}
