import 'dart:async';

import 'package:flutter/material.dart';

class DebounceAction {
  Timer? _timer;
  final Duration delay;
  final VoidCallback onDebounce;

  DebounceAction({
    this.delay = const Duration(milliseconds: 500),
    required this.onDebounce,
  });

  void run() {
    _timer?.cancel();
    _timer = Timer(delay, onDebounce);
  }

  void dispose() {
    _timer?.cancel();
  }
}
