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

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

StreamSubscription<List<ConnectivityResult>>? subscription;
Timer? _offlineTimer;
LifecycleConnectivityObserver? _lifecycleObserver;

class LifecycleConnectivityObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await updateConnectionState();
    }
  }
}

Future<void> updateConnectionState() async {
  bool hasConnection = await checkConnection();
  FFAppState().update(() {
    FFAppState().connected = hasConnection;
  });
  FFAppState().notifyListeners();

  if (!hasConnection) {
    _startOfflineTimer();
  } else {
    _stopOfflineTimer();
  }
}

void _startOfflineTimer() {
  _offlineTimer?.cancel();
  _offlineTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    bool hasConnection = await checkConnection();
    if (hasConnection) {
      timer.cancel();
      _offlineTimer = null;
      FFAppState().update(() {
        FFAppState().connected = true;
      });
      FFAppState().notifyListeners();
    }
  });
}

void _stopOfflineTimer() {
  _offlineTimer?.cancel();
  _offlineTimer = null;
}

Future connected() async {
  // Check initial connection
  await updateConnectionState();

  // Register connectivity listener
  subscription?.cancel();
  subscription = Connectivity()
      .onConnectivityChanged
      .listen((List<ConnectivityResult> results) async {
    await updateConnectionState();
  });

  // Register lifecycle observer
  if (_lifecycleObserver == null) {
    _lifecycleObserver = LifecycleConnectivityObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
  }
}

Future<bool> checkConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
