import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/providers/pdf_viewer_provider.dart';
import '/services/highlight_storage_service.dart';
import 'pdf_viewer_pdf_operations.dart';

/// Settings dialogs for PDF Viewer
class PdfViewerSettingsDialogs {
  /// Open TTS (Text-to-Speech) settings dialog
  static void openTtsSettings(
    BuildContext context,
    PdfViewerProvider provider,
    FlutterTts flutterTts,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "🔊 Voice Settings",
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),

                      /// Speech Speed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Speed",
                              style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                          Text("${provider.speechRate.toStringAsFixed(2)}x",
                              style: FlutterFlowTheme.of(context).bodyMedium),
                        ],
                      ),
                      Slider(
                        value: provider.speechRate,
                        min: 0.3,
                        max: 1.5,
                        divisions: 12,
                        activeColor: FlutterFlowTheme.of(context).primary,
                        label: provider.speechRate.toStringAsFixed(2),
                        onChanged: (val) {
                          provider.setSpeechRate(val);
                        },
                      ),
                      const SizedBox(height: 10),

                      /// Pitch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Pitch",
                              style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                          Text("${provider.pitch.toStringAsFixed(2)}",
                              style: FlutterFlowTheme.of(context).bodyMedium),
                        ],
                      ),
                      Slider(
                        value: provider.pitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        activeColor: FlutterFlowTheme.of(context).primary,
                        label: provider.pitch.toStringAsFixed(2),
                        onChanged: (val) {
                          provider.setPitch(val);
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Test Voice Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          bool isBnAvailable = false;
                          await flutterTts.getLanguages.then((languages) {
                            isBnAvailable = languages.contains("bn-BD");
                          });
                          log("isBnAvailable $isBnAvailable");
                          await flutterTts.setSpeechRate(provider.speechRate);
                          await flutterTts.setPitch(provider.pitch);
                          if (isBnAvailable) {
                            await flutterTts.setLanguage("bn-BD");
                            await flutterTts.speak("এই সেটিংস প্রিভিউ করার জন্য ধন্যবাদ।");
                          } else {
                            await flutterTts.setLanguage("en-US");
                            await flutterTts.speak(
                                "Bangla voice not available in this device, playing English sample.");
                          }
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text("Preview Voice",
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 10),

                      /// Done button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done",
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Open brightness settings dialog
  static void openBrightnessSettings(
    BuildContext context,
    PdfViewerProvider provider,
    Function setBrightness,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "☀️ Brightness Settings",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Brightness Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.brightness_low,
                          color: FlutterFlowTheme.of(context).secondaryText),
                      Expanded(
                        child: Slider(
                          value: provider.currentBrightness,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          activeColor: FlutterFlowTheme.of(context).primary,
                          label: "${(provider.currentBrightness * 100).toInt()}%",
                          onChanged: (val) {
                            setBrightness(val);
                          },
                        ),
                      ),
                      Icon(Icons.brightness_high,
                          color: FlutterFlowTheme.of(context).secondaryText),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(provider.currentBrightness * 100).toInt()}%",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Quick Brightness Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBrightnessPreset(context, provider, "25%", 0.25, setBrightness),
                      _buildBrightnessPreset(context, provider, "50%", 0.50, setBrightness),
                      _buildBrightnessPreset(context, provider, "75%", 0.75, setBrightness),
                      _buildBrightnessPreset(context, provider, "100%", 1.0, setBrightness),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Theme Mode
                  Text(
                    "Theme Mode",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeModePreset(context, provider, "Light", AppThemeMode.light),
                      _buildThemeModePreset(context, provider, "Dark", AppThemeMode.dark),
                      _buildThemeModePreset(context, provider, "Sepia", AppThemeMode.sepia),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Done button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build brightness preset button
  static Widget _buildBrightnessPreset(
    BuildContext context,
    PdfViewerProvider provider,
    String label,
    double value,
    Function setBrightness,
  ) {
    final isSelected = (provider.currentBrightness - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        setBrightness(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Build theme mode preset button
  static Widget _buildThemeModePreset(
    BuildContext context,
    PdfViewerProvider provider,
    String label,
    AppThemeMode mode,
  ) {
    final isSelected = provider.currentThemeMode == mode;
    return InkWell(
      onTap: () {
        provider.setThemeMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Open font settings dialog
  static void openFontSettings(
    BuildContext context,
    PdfViewerProvider provider,
  ) {
    if (provider.readerType != ReaderType.epub) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔤 Font Settings",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  /// Font Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Font Size",
                          style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text("${provider.epubFontSize.toInt()}",
                          style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                  Slider(
                    value: provider.epubFontSize,
                    min: 12.0,
                    max: 32.0,
                    divisions: 20,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    label: provider.epubFontSize.toInt().toString(),
                    onChanged: (val) {
                      provider.setEpubFontSize(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Font Size Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFontPreset(context, provider, "Small", 14.0),
                      _buildFontPreset(context, provider, "Medium", 18.0),
                      _buildFontPreset(context, provider, "Large", 24.0),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Line Spacing Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Line Spacing",
                          style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text("${provider.epubLineHeight.toStringAsFixed(1)}x",
                          style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                  Slider(
                    value: provider.epubLineHeight,
                    min: 1.0,
                    max: 2.5,
                    divisions: 15,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    label: provider.epubLineHeight.toStringAsFixed(1),
                    onChanged: (val) {
                      provider.setEpubLineHeight(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Line Spacing Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLineHeightPreset(context, provider, "Compact", 1.2),
                      _buildLineHeightPreset(context, provider, "Normal", 1.6),
                      _buildLineHeightPreset(context, provider, "Relaxed", 2.0),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// Preview Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Sample Text Preview\nনমুনা পাঠ্য প্রিভিউ",
                      style: TextStyle(fontSize: provider.epubFontSize, height: provider.epubLineHeight),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Done button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build font preset button
  static Widget _buildFontPreset(
    BuildContext context,
    PdfViewerProvider provider,
    String label,
    double value,
  ) {
    final isSelected = (provider.epubFontSize - value).abs() < 1.0;
    return InkWell(
      onTap: () {
        provider.setEpubFontSize(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Build line height preset button
  static Widget _buildLineHeightPreset(
    BuildContext context,
    PdfViewerProvider provider,
    String label,
    double value,
  ) {
    final isSelected = (provider.epubLineHeight - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        provider.setEpubLineHeight(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Open search overlay
  static void openSearchOverlay(
    BuildContext context,
    PdfViewerProvider provider,
    TextEditingController searchController,
    PdfViewerController pdfController, {
    VoidCallback? onSearchEpub,
    VoidCallback? onNextResult,
    VoidCallback? onPreviousResult,
    VoidCallback? onClearSearch,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground.withValues(alpha:0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔍 Search in ${provider.readerType == ReaderType.pdf ? 'PDF' : 'EPUB'}",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search text",
                      hintText: "Enter text to search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          // Clear search for both PDF and EPUB
                          if (provider.readerType == ReaderType.pdf) {
                            PdfViewerPdfOperations.clearSearch(provider, searchController);
                          } else {
                            onClearSearch?.call();
                          }
                        },
                      ),
                    ),
                    onChanged: (value) {
                      provider.setSearchText(value);
                    },
                    onSubmitted: (value) {
                      if (provider.readerType == ReaderType.pdf) {
                        PdfViewerPdfOperations.searchPdf(provider, pdfController);
                      } else {
                        onSearchEpub?.call();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Search results info and navigation
                  if (provider.readerType == ReaderType.pdf)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.searchResult.hasResult
                              ? "${provider.searchResult.currentInstanceIndex + 1} of ${provider.searchResult.totalInstanceCount}"
                              : "No results",
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: provider.searchResult.hasResult &&
                                      provider.searchResult.currentInstanceIndex > 0
                                  ? () {
                                      onPreviousResult?.call();
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: provider.searchResult.hasResult &&
                                      provider.searchResult.currentInstanceIndex <
                                          provider.searchResult.totalInstanceCount - 1
                                  ? () {
                                      onNextResult?.call();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    )
                  else if (provider.readerType == ReaderType.epub)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.hasEpubSearchResults
                              ? "${provider.epubCurrentSearchIndex + 1} of ${provider.epubSearchResultCount}"
                              : "No results",
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: provider.hasEpubSearchResults &&
                                      provider.epubCurrentSearchIndex > 0
                                  ? () {
                                      onPreviousResult?.call();
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: provider.hasEpubSearchResults &&
                                      provider.epubCurrentSearchIndex <
                                          provider.epubSearchResultCount - 1
                                  ? () {
                                      onNextResult?.call();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (provider.readerType == ReaderType.pdf) {
                        PdfViewerPdfOperations.searchPdf(provider, pdfController);
                      } else {
                        //hide keyboard
                        FocusScope.of(context).unfocus();
                        onSearchEpub?.call();
                      }
                    },
                    child: const Text("Search",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // Clear search for both PDF and EPUB
                      if (provider.readerType == ReaderType.pdf) {
                        PdfViewerPdfOperations.clearSearch(provider, searchController);
                      } else {
                        onClearSearch?.call();
                      }
                      Navigator.pop(context);
                    },
                    child: const Text("Done",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Open bookmark collection dialog
  static void openBookmarkCollection(
    BuildContext context,
    PdfViewerProvider provider,
    PdfViewerController pdfController,
    Function loadEpubChapter,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "🔖 Bookmarked ${provider.readerType == ReaderType.epub ? 'Chapters' : 'Pages'}",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  provider.bookmarks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No bookmarked ${provider.readerType == ReaderType.epub ? 'chapters' : 'pages'} yet.",
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: provider.bookmarks.length,
                            itemBuilder: (context, index) {
                              final bookmark = provider.bookmarks[index];
                              final pageNumber = bookmark.pageNumber;

                              return ListTile(
                                leading: Icon(
                                  Icons.bookmark,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                                title: Text(
                                  bookmark.chapterName,
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await provider.removeBookmark(pageNumber, bookId: provider.currentBookId);
                                  },
                                ),
                                onTap: () {
                                  if (provider.readerType == ReaderType.pdf) {
                                    pdfController.jumpToPage(pageNumber);
                                    provider.setCurrentPage(pageNumber);
                                  } else {
                                    loadEpubChapter(pageNumber - 1);
                                  }
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Open chapter list dialog
  static void openChapterList(
    BuildContext context,
    PdfViewerProvider provider,
    Function loadEpubChapter,
  ) {
    if (provider.readerType != ReaderType.epub || provider.epubChapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "📖 Table of Contents",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.epubChapters.length,
                      itemBuilder: (context, index) {
                        final chapter = provider.epubChapters[index];
                        final isCurrentChapter = index == provider.currentEpubChapterIndex;
                        return ListTile(
                          leading: Icon(
                            Icons.book_outlined,
                            color: isCurrentChapter
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context).secondaryText,
                          ),
                          title: Text(
                            chapter.Title ?? "Chapter ${index + 1}",
                            style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                  fontWeight: isCurrentChapter
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrentChapter
                                      ? FlutterFlowTheme.of(context).primary
                                      : null,
                                ),
                          ),
                          trailing: isCurrentChapter
                              ? Icon(
                                  Icons.play_arrow,
                                  color: FlutterFlowTheme.of(context).primary,
                                )
                              : null,
                          onTap: () {
                            loadEpubChapter(index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Open highlights collection dialog
  static void openHighlightsCollection(
    BuildContext context,
    PdfViewerProvider provider,
    PdfViewerController pdfController,
    Function(int) loadEpubChapter,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Consumer<PdfViewerProvider>(
          builder: (context, provider, child) {
            final highlights = provider.highlights;
            
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "✨ Highlights",
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  highlights.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No highlights yet. Select text and tap 'Highlight' to create one.",
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: highlights.length,
                            itemBuilder: (context, index) {
                              final highlight = highlights[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 4,
                                    height: double.infinity,
                                    color: Colors.yellow.withOpacity(0.5),
                                  ),
                                  title: Text(
                                    highlight.chapterName,
                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 12,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                        ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      highlight.text,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 14,
                                          ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () async {
                                      // Delete from storage
                                      await HighlightStorageService.deleteHighlight(highlight);
                                      // Remove from provider
                                      provider.removeHighlight(highlight);
                                      
                                      // If this highlight was in the current chapter, reload the chapter
                                      if (provider.readerType == ReaderType.epub) {
                                        final currentChapterId = provider.currentEpubChapterIndex.toString();
                                        if (highlight.chapterId == currentChapterId) {
                                          // Reload current chapter to reflect the deletion
                                          final chapterIndex = provider.currentEpubChapterIndex;
                                          loadEpubChapter(chapterIndex);
                                        }
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    // Navigate to chapter
                                    if (provider.readerType == ReaderType.epub) {
                                      final chapterIndex = int.tryParse(highlight.chapterId);
                                      if (chapterIndex != null) {
                                        loadEpubChapter(chapterIndex);
                                      }
                                    } else {
                                      // For PDF, jump to page if we have position info
                                      pdfController.jumpToPage(provider.currentPage);
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

