import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'pdf_viewer_provider.dart';

/// Helper methods for PDF Viewer widget
class PdfViewerHelpers {
  /// Determine reader type based on file extension
  static void determineReaderType(String? filePath, PdfViewerProvider provider) {
    provider.setReaderType(ReaderType.pdf);
  }

  /// Get initial brightness from device
  static Future<void> getInitialBrightness(PdfViewerProvider provider) async {
    try {
      final brightness = await ScreenBrightness().application;
      provider.setOriginalBrightness(brightness);
      provider.setCurrentBrightness(brightness);
    } catch (e) {
      log('Error getting initial brightness: $e');
    }
  }

  /// Restore original brightness
  static Future<void> restoreOriginalBrightness(PdfViewerProvider provider) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(provider.originalBrightness);
    } catch (e) {
      log('Error restoring brightness: $e');
    }
  }

  /// Set brightness
  static Future<void> setBrightness(PdfViewerProvider provider, double brightness) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(brightness);
      provider.setCurrentBrightness(brightness);
    } catch (e) {
      log('Error setting brightness: $e');
    }
  }

  /// Toggle full screen mode
  static void toggleFullScreen(PdfViewerProvider provider, BuildContext context) {
    provider.toggleFullScreen();
    if (provider.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  /// Toggle auto rotate
  static void toggleAutoRotate(PdfViewerProvider provider) {
    provider.toggleAutoRotate();
    if (provider.isAutoRotateEnabled) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  /// Toggle bookmark
  static void toggleBookmark(PdfViewerProvider provider) {
    provider.toggleBookmark(provider.currentPage);
  }

  /// Build bottom icon widget
  static Widget buildBottomIcon(IconData icon, String tooltip, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 24,
          color: iconColor,
        ),
      ),
    );
  }

  /// Set current page (next)
  static void setCurrentPage(PdfViewerProvider provider, PdfViewerController controller) {
    if (provider.currentPage != provider.currentPage) {
      provider.incrementPage();
      controller.jumpToPage(provider.currentPage);
    }
  }

  /// Set current page (previous)
  static void setCurrentMinusPage(PdfViewerProvider provider, PdfViewerController controller) {
    if (provider.currentPage > 1) {
      provider.decrementPage();
      controller.jumpToPage(provider.currentPage);
    }
  }
}
