import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReadiumMethodChannelService {
  ReadiumMethodChannelService._();

  static const MethodChannel _channel =
      MethodChannel('com.boiaro.app/readium_reader');

  static bool isSupportedEpubOnNative(String? path) {
    if (path == null ||
        path.isEmpty ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final normalized = path.toLowerCase().trim();
    return normalized.contains('.epub');
  }

  static Future<bool> openEpubReader({
    required String epubPath,
    required String bookTitle,
    required String bookId,
  }) async {
    final result = await _channel.invokeMethod<bool>('openEpubReader', {
      'epubPath': epubPath,
      'bookTitle': bookTitle,
      'bookId': bookId,
    });
    return result ?? false;
  }
}
