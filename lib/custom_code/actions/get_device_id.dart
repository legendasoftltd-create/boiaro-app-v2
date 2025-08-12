// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future getDeviceId() async {
  // Add your function code here!
  String deviceId = "Unknown device ID";

  var deviceInfo = DeviceInfoPlugin();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  try {
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;

      // Check if identifierForVendor is not null
      if (iosDeviceInfo.identifierForVendor != null) {
        deviceId = iosDeviceInfo.identifierForVendor!;
      }
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;

      // Check if id is not null
      if (androidDeviceInfo.id != null) {
        deviceId = androidDeviceInfo.id!;
      }
    }

    // Check if we have a saved UUID as a fallback
    String? savedUUID = prefs.getString('device_uuid');
    if (savedUUID == null) {
      // Generate and save a new UUID if not already present
      var uuid = Uuid();
      String newUUID = uuid.v4();
      await prefs.setString('device_uuid', newUUID);
      savedUUID = newUUID;
    }
    FFAppState().deviceId = savedUUID;
    // Combine the platform device ID with the UUID
    return "$deviceId-$savedUUID";
  } catch (e) {
    // Handle any exceptions or platform-specific errors
    print('Error getting device ID: $e');
    return "Error getting device ID";
  }
}
