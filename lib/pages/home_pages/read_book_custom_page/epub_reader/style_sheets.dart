import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

enum ReaderThemeType { light, sepia, dark }

class EpubStyleHelper {
  static Color getBackgroundColor(ReaderThemeType themeType) {
    switch (themeType) {
      case ReaderThemeType.light:
        return Colors.white;
      case ReaderThemeType.sepia:
        return const Color(0xfff4ecd8);
      case ReaderThemeType.dark:
        return const Color(0xff121212);
    }
  }

  static Color getForegroundColor(ReaderThemeType themeType) {
    switch (themeType) {
      case ReaderThemeType.light:
        return Colors.black;
      case ReaderThemeType.sepia:
        return const Color(0xff5b4636);
      case ReaderThemeType.dark:
        return Colors.white;
    }
  }

  static String getFontFamilyName(String fontKey) {
    switch (fontKey.toLowerCase()) {
      case 'literata':
        return 'Literata';
      case 'sans serif':
        return 'Inter';
      case 'noto sans bengali':
        return 'Noto Sans Bengali';
      case 'noto serif bengali':
        return 'Noto Serif Bengali';
      case 'tiro bangla':
        return 'Tiro Bangla';
      default:
        return 'serif';
    }
  }

  static EpubTheme getEpubTheme({
    required ReaderThemeType themeType,
    required String fontFamilyKey,
    required double fontSize,
    double lineHeight = 1.6,
  }) {
    final bgColor = getBackgroundColor(themeType);
    final fgColor = getForegroundColor(themeType);
    final fontName = getFontFamilyName(fontFamilyKey);

    final bgHex = _toHex(bgColor);
    final fgHex = _toHex(fgColor);

    // Build the custom CSS styles for EpubJS
    final Map<String, dynamic> customCss = {
      'body': {
        'background-color': '$bgHex !important',
        'color': '$fgHex !important',
        'font-family': "'$fontName', serif !important",
        'font-size': '${fontSize}px !important',
        'line-height': '$lineHeight !important',
        'padding': '0 10px !important',
      },
      'p': {
        'font-family': "'$fontName', serif !important",
        'font-size': '${fontSize}px !important',
        'line-height': '$lineHeight !important',
        'margin-bottom': '1.2em !important',
      },
      'h1': {
        'font-family': "'$fontName', serif !important",
        'color': '$fgHex !important',
      },
      'h2': {
        'font-family': "'$fontName', serif !important",
        'color': '$fgHex !important',
      },
      'h3': {
        'font-family': "'$fontName', serif !important",
        'color': '$fgHex !important',
      },
      'a': {
        'color': fgHex == '#ffffff' ? '#90caf9 !important' : '#1976d2 !important',
      },
      // Styling for active reading highlights
      '.tts-active-highlight': {
        'background-color': 'rgba(255, 235, 59, 0.45) !important',
        'color': 'black !important',
        'border-radius': '2px !important',
        'padding': '1px 0 !important',
      }
    };

    return EpubTheme.custom(
      backgroundDecoration: BoxDecoration(color: bgColor),
      foregroundColor: fgColor,
      customCss: customCss,
    );
  }

  static String _toHex(Color color) {
    final r = (color.r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).toInt().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
}
