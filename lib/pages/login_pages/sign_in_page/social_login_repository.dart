import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
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
        registrationToken: fcmToken,
        deviceId: deviceId,
      );
    } catch (error) {
      debugPrint('Google sign in error: $error');
      return null;
    }
  }

  Future<ApiCallResponse?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final String? deviceId = FFAppState().deviceId;
        final String? fcmToken = FFAppState().tokenFcm;

        final userData = await FacebookAuth.instance.getUserData();
        final String? userId = userData['id'] as String?;

        if (userId == null) {
          debugPrint('Facebook login failed: Could not retrieve user ID');
          return null;
        }

        final String? email = userData['email'] as String?;
        final String? name = userData['name'] as String?;
        final String? firstName = userData['first_name'] as String? ?? 
                                  (name != null ? name.split(' ').first : '');
        final String? lastName = userData['last_name'] as String? ?? 
                                 (name != null && name.split(' ').length > 1 
                                  ? name.split(' ').sublist(1).join(' ') 
                                  : '');

        return EbookGroup.socialLoginCall.call(
          email: email ?? '',
          firstname: firstName ?? '',
          lastname: lastName ?? '',
          username: name ?? '',
          provider: 'facebook',
          providerId: userId,
          registrationToken: fcmToken,
          deviceId: deviceId,
        );
      } else {
        debugPrint('Facebook sign in failed: ${result.message}');
        return null;
      }
    } catch (error) {
      debugPrint('Facebook sign in error: $error');
      return null;
    }
  }
}
