import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:http/http.dart' as http;
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/providers/pdf_viewer_provider.dart';
import '/models/highlight_model.dart';
import 'package:a_i_ebook_app/custom_code/extensions/custom_text_selection_controls.dart';
import 'package:a_i_ebook_app/custom_code/widgets/html_parser_widget.dart';

/// EPUB Reader Widget and related methods
class EpubReaderWidget {
  /// Load EPUB book from file path
  static Future<void> loadEpubBook(
    String? filePath,
    PdfViewerProvider provider,
    BuildContext context,
    Function loadEpubChapter,
  ) async {
    if (filePath == null || filePath.isEmpty) {
      log('Invalid EPUB path');
      return;
    }

    provider.setLoadingEpub(true);
    try {
      List<int> bytes;

      if (filePath.startsWith('http')) {
        final response = await http.get(Uri.parse(filePath));
        bytes = response.bodyBytes;
      } else if (filePath.startsWith('assets/')) {
        final data = await rootBundle.load(filePath);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(filePath);
        bytes = await file.readAsBytes();
      }

      final epubBook = await epubx.EpubReader.readBook(bytes);
      provider.setEpubBook(epubBook);
      final chapters = getAllChapters(epubBook.Chapters ?? []);
      provider.setEpubChapters(chapters);

      if (chapters.isNotEmpty) {
        loadEpubChapter(0);
      }
    } catch (e, stacktrace) {
      log('Error loading EPUB: $e stacktrace $stacktrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading EPUB file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) provider.setLoadingEpub(false);
    }
  }

  /// Get all chapters recursively
  static List<epubx.EpubChapter> getAllChapters(List<epubx.EpubChapter> chapters) {
    List<epubx.EpubChapter> allChapters = [];
    for (var chapter in chapters) {
      allChapters.add(chapter);
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        allChapters.addAll(getAllChapters(chapter.SubChapters!));
      }
    }
    return allChapters;
  }

  /// Parse HTML content
  static String parseHtmlContent(String? htmlContent) {
    if (htmlContent == null || htmlContent.isEmpty) return "";
    return htmlContent;
  }

  /// Load EPUB chapter with smooth animation
  /// Returns the original HTML content (before highlights) via callback
  static void loadEpubChapter(
    PdfViewerProvider provider,
    int index,
    ValueNotifier<String> currentEpubContentNotifier,
    ScrollController epubScrollController, {
    Function(String)? onOriginalContentReady, // Callback to get original HTML
  }) {
    final chapters = provider.epubChapters;
    if (index >= 0 && index < chapters.length) {
      // Set loading state
      provider.setChangingChapter(true);

      // Add a small delay to show loading indicator
      Future.delayed(const Duration(milliseconds: 100), () {
        provider.setCurrentEpubChapterIndex(index);

        final chapter = chapters[index];
        var originalContent = parseHtmlContent(chapter.HtmlContent);
        final chapterId = index.toString();

        // Notify about original content (before highlights)
        if (onOriginalContentReady != null) {
          onOriginalContentReady(originalContent);
        }

        // Apply highlights for this chapter only (from saved highlights)
        var content = originalContent;
        final chapterHighlights = provider.getHighlightsForChapter(chapterId);
        
        // Sort highlights by end position (descending) so we apply from end to start
        // This ensures that applying earlier highlights doesn't affect positions of later ones
        final sortedHighlights = List<HighlightModel>.from(chapterHighlights)
          ..sort((a, b) => b.endPosition.compareTo(a.endPosition));
        
        for (final highlight in sortedHighlights) {
          // Apply highlight at specific position
          content = _applyHighlightAtPosition(content, highlight);
        }
        
        provider.setCurrentEpubContent(content);
        
        // Update total pages for EPUB (based on chapters)
        FFAppState().totalPages = chapters.length;
        FFAppState().update(() {
          FFAppState().homePageTotalPdfPageIndex = chapters.length;
          FFAppState().homePageCurrentPdfIndex = provider.currentPage;
        });

        // Animate content change with fade transition
        // First fade out, then update content, then fade in
        currentEpubContentNotifier.value = '';
        
        Future.delayed(const Duration(milliseconds: 150), () {
          currentEpubContentNotifier.value = content;
          
          // Scroll to top when changing chapters with animation
          if (epubScrollController.hasClients) {
            epubScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          
          // Reset loading state after animation
          Future.delayed(const Duration(milliseconds: 300), () {
            provider.setChangingChapter(false);
          });
        });
      });
    }
  }

  /// Build EPUB reader widget
  static Widget buildEpubReader({
    required ValueNotifier<String> currentEpubContentNotifier,
    required ValueNotifier<String> localSelectedTextNotifier,
    required ScrollController epubScrollController,
    required Function addHighlight,
    required Function speakSelected,
    required Function stopSpeaking,
    required Function loadEpubChapter,
  }) {
    // Don't include EpubBook in selector - it has problematic equality comparison
    // Access it via context.read inside the builder instead
    return Selector<PdfViewerProvider, (bool, String, AppThemeMode)>(
      selector: (_, p) => (p.isLoadingEpub, p.currentEpubContent, p.currentThemeMode),
      builder: (context, data, child) {
        final isLoadingEpub = data.$1;
        final currentEpubContent = data.$2;
        final themeMode = data.$3;

        // Get epubBook from provider inside builder to avoid comparison issues
        final provider = context.read<PdfViewerProvider>();
        final epubBook = provider.epubBook;

        if (isLoadingEpub) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading...",
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ],
            ),
          );
        }

        if (epubBook == null || currentEpubContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
                const SizedBox(height: 16),
                Text(
                  "Failed to load EPUB file",
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ],
            ),
          );
        }

        Color backgroundColor;
        Color scrollbarColor;

        switch (themeMode) {
          case AppThemeMode.light:
            backgroundColor = Colors.white;
            scrollbarColor = Colors.black.withOpacity(0.3);
            break;
          case AppThemeMode.dark:
            backgroundColor = Colors.black;
            scrollbarColor = Colors.white.withOpacity(0.5);
            break;
          case AppThemeMode.sepia:
            backgroundColor = const Color(0xFFF5DEB3); // Sepia color
            scrollbarColor = Colors.black.withOpacity(0.3);
            break;
        }

        return Container(
          color: backgroundColor,
          child: SelectionArea(
            selectionControls: CustomTextSelectionControls(
              onHighlight: () => addHighlight(),
              onListen: () {
                final p = context.read<PdfViewerProvider>();
                p.isSpeaking ? stopSpeaking() : speakSelected();
              },
            ),
            onSelectionChanged: (SelectedContent? selection) {
              // Update local ValueNotifier - this does NOT trigger provider rebuilds
              final newSelectedText = selection?.plainText ?? '';
              localSelectedTextNotifier.value = newSelectedText;

              // Only sync to provider when selection is cleared (for UI state)
              // For Listen button, we'll sync when Listen is clicked
              if (newSelectedText.isEmpty) {
                final p = context.read<PdfViewerProvider>();
                p.clearSelectedText();
              }
              // Don't update provider during active selection to prevent rebuilds
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                final p = context.read<PdfViewerProvider>();

                // Skip if already changing chapter
                if (p.isChangingChapter) return true;

                final metrics = notification.metrics;
                
                // Validate scroll metrics
                if (!metrics.hasContentDimensions || 
                    metrics.maxScrollExtent <= 0 ||
                    !epubScrollController.hasClients) {
                  return false;
                }

                // Update last scroll position for tracking
                final currentPos = metrics.pixels;
                p.setLastScrollPosition(currentPos);

                // Automatic chapter loading on scroll disabled
                // Users can manually navigate chapters using navigation controls
                return false;
              },
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(scrollbarColor),
                  thickness: WidgetStateProperty.all(8.0),
                  radius: const Radius.circular(4),
                  minThumbLength: 50,
                  crossAxisMargin: 2.0,
                  mainAxisMargin: 8.0,
                ),
                child: Scrollbar(
                  controller: epubScrollController,
                  // thumbVisibility: true,
                  // trackVisibility: false,
                  radius: const Radius.circular(4),
                  // thickness: 8.0,
                  interactive: true,
                  child: SingleChildScrollView(
                  controller: epubScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  child: ValueListenableBuilder<String>(
                    valueListenable: currentEpubContentNotifier,
                    builder: (context, content, child) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Selector<PdfViewerProvider, (double, double, AppThemeMode)>(
                          key: ValueKey<String>(content),
                          selector: (_, p) => (p.epubFontSize, p.epubLineHeight, p.currentThemeMode),
                          builder: (context, settings, child) {
                            final fontSize = settings.$1;
                            final lineHeight = settings.$2;
                            final themeMode = settings.$3;

                            return HtmlParserWidget(
                              htmlContent: content,
                              fontSize: fontSize,
                              lineHeight: lineHeight,
                              themeMode: themeMode,
                              epubBook: epubBook,
                            );
                          },
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  /// Apply highlight at specific position in HTML content
  static String _applyHighlightAtPosition(String htmlContent, HighlightModel highlight) {
    // Check if already highlighted
    if (htmlContent.contains('data-highlight-id="${highlight.id}"')) {
      return htmlContent; // Already highlighted
    }

    // Use the saved position to apply highlight accurately
    final startPos = highlight.startPosition;
    final endPos = highlight.endPosition;
    
    // Validate positions
    if (startPos < 0 || endPos <= startPos || endPos > htmlContent.length) {
      // Fallback to text search if positions are invalid
      final text = highlight.text;
      final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      if (htmlContent.contains(normalizedText)) {
        final index = htmlContent.indexOf(normalizedText);
        if (index != -1 && !_isInsideMark(index, htmlContent)) {
          return htmlContent.replaceFirst(
            normalizedText,
            '<mark data-highlight-id="${highlight.id}" style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$normalizedText</mark>',
          );
        }
      }
      return htmlContent;
    }

    // Check if position is already inside a mark tag
    if (_isInsideMark(startPos, htmlContent)) {
      return htmlContent; // Already highlighted
    }

    // Extract the text at the position
    final highlightedText = htmlContent.substring(startPos, endPos);
    
    // Check if this text is already wrapped in a mark tag
    if (highlightedText.contains('<mark') || highlightedText.contains('</mark>')) {
      return htmlContent; // Already highlighted
    }

    // Apply highlight at the exact position
    final beforeText = htmlContent.substring(0, startPos);
    final afterText = htmlContent.substring(endPos);
    
    return beforeText +
        '<mark data-highlight-id="${highlight.id}" style="background-color: yellow; padding: 0; margin: 0; display: inline; vertical-align: baseline;">$highlightedText</mark>' +
        afterText;
  }

  /// Check if position is inside a mark tag
  static bool _isInsideMark(int position, String content) {
    int start = position;
    while (start > 0 && start > position - 100) {
      if (start + 5 <= content.length && content.substring(start, start + 5) == '<mark') {
        return true;
      }
      if (start + 6 <= content.length && content.substring(start, start + 6) == '</mark') {
        return false;
      }
      start--;
    }
    return false;
  }
}

