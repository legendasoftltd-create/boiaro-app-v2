import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/providers/pdf_viewer_provider.dart';

/// Helper methods for PDF Viewer widget
class PdfViewerHelpers {
  /// Determine reader type based on file extension
  static void determineReaderType(String? filePath, PdfViewerProvider provider) {
    if (filePath != null) {
      final String path = filePath.toLowerCase();
      // Try parsing as URI to extract path without query params
      String uriPath = path;
      try {
        final uri = Uri.parse(filePath);
        uriPath = uri.path.toLowerCase();
      } catch (_) {}

      if (uriPath.endsWith('.epub') || path.contains('.epub')) {
        provider.setReaderType(ReaderType.epub);
      } else if (uriPath.endsWith('.pdf') || path.contains('.pdf')) {
        provider.setReaderType(ReaderType.pdf);
      } else {
        // Default to PDF if extension is not recognized
        provider.setReaderType(ReaderType.pdf);
      }
    }
  }

  /// Get initial brightness from device
  static Future<void> getInitialBrightness(PdfViewerProvider provider) async {
    try {
      final brightness = await ScreenBrightness().current;
      provider.setOriginalBrightness(brightness);
      provider.setCurrentBrightness(brightness);
    } catch (e) {
      log('Error getting initial brightness: $e');
    }
  }

  /// Restore original brightness
  static Future<void> restoreOriginalBrightness(PdfViewerProvider provider) async {
    try {
      await ScreenBrightness().setScreenBrightness(provider.originalBrightness);
    } catch (e) {
      log('Error restoring brightness: $e');
    }
  }

  /// Set brightness
  static Future<void> setBrightness(PdfViewerProvider provider, double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
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
  static void setCurrentPage(PdfViewerProvider provider, PdfViewerController controller, Function loadEpubChapter) {
    if (provider.readerType == ReaderType.epub) {
      if (provider.currentEpubChapterIndex < provider.epubChapters.length - 1) {
        loadEpubChapter(provider.currentEpubChapterIndex + 1);
      }
    } else {
      if (provider.currentPage != provider.currentPage) {
        provider.incrementPage();
        controller.jumpToPage(provider.currentPage);
      }
    }
  }

  /// Set current page (previous)
  static void setCurrentMinusPage(PdfViewerProvider provider, PdfViewerController controller, Function loadEpubChapter) {
    if (provider.readerType == ReaderType.epub) {
      if (provider.currentEpubChapterIndex > 0) {
        loadEpubChapter(provider.currentEpubChapterIndex - 1);
      }
    } else {
      if (provider.currentPage > 1) {
        provider.decrementPage();
        controller.jumpToPage(provider.currentPage);
      }
    }
  }
}

