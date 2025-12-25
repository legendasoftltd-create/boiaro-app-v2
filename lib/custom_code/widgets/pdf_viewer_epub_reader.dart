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
import 'package:a_i_ebook_app/custom_code/widgets/pdf_viewer_helpers.dart';
import 'package:a_i_ebook_app/custom_code/widgets/pdf_viewer_text_operations.dart';

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
  static List<epubx.EpubChapter> getAllChapters(
      List<epubx.EpubChapter> chapters) {
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

        // Apply search highlights if there's an active search
        // Note: Search highlights are applied in the widget after chapter loads
        // to avoid circular dependencies

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

          // Wait for layout to complete before scrolling
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (epubScrollController.hasClients) {
                double targetScroll = 0;

                // Check if chapter has an anchor/ID to scroll to
                final anchor = chapter.Anchor;

                // Determine if this is a root chapter (Top Level)
                // "Contents without subcontents" logic: Main chapters should start at top
                // Only scroll to anchor if it's a SubContent (child)
                bool isRoot = false;
                if (provider.epubBook != null &&
                    provider.epubBook!.Chapters != null) {
                  // Check if current chapter is in the top-level list
                  isRoot = provider.epubBook!.Chapters!.contains(chapter);
                }

                if (!isRoot && anchor != null && anchor.isNotEmpty) {
                  final maxScroll =
                      epubScrollController.position.maxScrollExtent;
                  final contentLen = content.length;

                  // Find anchor position in raw HTML
                  final anchorIndex = _findAnchorIndex(content, anchor);

                  log('EPUB Navigation: Chapter "${chapter.Title}", Anchor "$anchor"');
                  log('EPUB Navigation: Anchor index: $anchorIndex of $contentLen');

                  if (anchorIndex != -1 &&
                      content.isNotEmpty &&
                      maxScroll > 0) {
                    // Refined calculation: Use plain text ratio instead of raw HTML ratio
                    // This handles large metadata/head sections better

                    // 1. Find start of the tag containing this anchor (backtrack to '<')
                    int tagStart = content.lastIndexOf('<', anchorIndex);
                    if (tagStart == -1) tagStart = anchorIndex;

                    // 2. Extract plain text content up to that point
                    final contentBefore = content.substring(0, tagStart);
                    final plainTextBefore =
                        PdfViewerTextOperations.extractPlainTextFromHtml(
                            contentBefore);

                    // 3. Extract total plain text
                    final plainTextTotal =
                        PdfViewerTextOperations.extractPlainTextFromHtml(
                            content);

                    final lenBefore = plainTextBefore.length;
                    final lenTotal = plainTextTotal.length;

                    log('EPUB Navigation: Plain text before: $lenBefore, Total: $lenTotal');

                    if (lenTotal > 0) {
                      final ratio = lenBefore / lenTotal;
                      targetScroll = (ratio * maxScroll).clamp(0.0, maxScroll);
                      log('EPUB Navigation: Calculated scroll: $targetScroll (max: $maxScroll, ratio: $ratio)');
                    } else {
                      // Fallback to raw ratio if text extraction fails
                      final ratio = anchorIndex / contentLen;
                      targetScroll = (ratio * maxScroll).clamp(0.0, maxScroll);
                      log('EPUB Navigation: Fallback scroll: $targetScroll (raw ratio: $ratio)');
                    }
                  } else {
                    log('EPUB Navigation: Anchor not found or invalid dimensions');
                  }
                }

                epubScrollController.animateTo(
                  targetScroll,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }

              // Reset loading state after animation
              provider.setChangingChapter(false);
            });
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
    // Track scroll state to distinguish taps from scrolls
    final isScrollingNotifier = ValueNotifier<bool>(false);
    DateTime? lastScrollEndTime;

    // Don't include EpubBook in selector - it has problematic equality comparison
    // Access it via context.read inside the builder instead
    return Selector<PdfViewerProvider, (bool, String, AppThemeMode)>(
      selector: (_, p) =>
          (p.isLoadingEpub, p.currentEpubContent, p.currentThemeMode),
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
          padding: EdgeInsets.only(top: 50),
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

                // Track scroll state
                if (notification is ScrollStartNotification) {
                  isScrollingNotifier.value = true;
                } else if (notification is ScrollEndNotification) {
                  isScrollingNotifier.value = false;
                  lastScrollEndTime = DateTime.now();
                }

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
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Only toggle if not scrolling and no text selected
                  if (!isScrollingNotifier.value &&
                      localSelectedTextNotifier.value.isEmpty) {
                    // Also check if scroll just ended (wait a bit after scroll)
                    final now = DateTime.now();
                    if (lastScrollEndTime == null ||
                        now.difference(lastScrollEndTime!).inMilliseconds >
                            200) {
                      final p = context.read<PdfViewerProvider>();
                      PdfViewerHelpers.toggleFullScreen(p, context);
                    }
                  }
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      child: ValueListenableBuilder<String>(
                        valueListenable: currentEpubContentNotifier,
                        builder: (context, content, child) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Selector<PdfViewerProvider,
                                (double, double, AppThemeMode, String, bool)>(
                              key: ValueKey<String>(content),
                              selector: (_, p) => (
                                p.epubFontSize,
                                p.epubLineHeight,
                                p.currentThemeMode,
                                p.epubFontFamily,
                                p.isJustified
                              ),
                              builder: (context, settings, child) {
                                final fontSize = settings.$1;
                                final lineHeight = settings.$2;
                                final themeMode = settings.$3;
                                final fontFamily = settings.$4;
                                final isJustified = settings.$5;

                                return HtmlParserWidget(
                                  htmlContent: content,
                                  fontSize: fontSize,
                                  lineHeight: lineHeight,
                                  themeMode: themeMode,
                                  epubBook: epubBook,
                                  fontFamily: fontFamily,
                                  isJustified: isJustified,
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
          ),
        );
      },
    );
  }

  /// Apply highlight at specific position in HTML content
  static String _applyHighlightAtPosition(
      String htmlContent, HighlightModel highlight) {
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
    if (highlightedText.contains('<mark') ||
        highlightedText.contains('</mark>')) {
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
      if (start + 5 <= content.length &&
          content.substring(start, start + 5) == '<mark') {
        return true;
      }
      if (start + 6 <= content.length &&
          content.substring(start, start + 6) == '</mark') {
        return false;
      }
      start--;
    }
    return false;
  }

  /// Find the index of an anchor in the content
  static int _findAnchorIndex(String content, String anchor) {
    if (anchor.isEmpty) return -1;
    // Handle hash prefix if present
    final searchAnchor = anchor.startsWith('#') ? anchor.substring(1) : anchor;

    // Patterns to look for (id and name attributes)
    final patterns = [
      'id="$searchAnchor"',
      "id='$searchAnchor'",
      'name="$searchAnchor"',
      "name='$searchAnchor'",
    ];

    for (var pattern in patterns) {
      final index = content.indexOf(pattern);
      if (index != -1) return index;
    }

    return -1;
  }
}
