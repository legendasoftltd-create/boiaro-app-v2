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

  /// Load EPUB chapter
  static void loadEpubChapter(
    PdfViewerProvider provider,
    int index,
    ValueNotifier<String> currentEpubContentNotifier,
    ScrollController epubScrollController,
  ) {
    final chapters = provider.epubChapters;
    if (index >= 0 && index < chapters.length) {
      provider.setCurrentEpubChapterIndex(index);

      final chapter = chapters[index];
      var content = parseHtmlContent(chapter.HtmlContent);

      // Apply highlights
      for (final highlight in provider.highlights) {
        content = content.replaceAll(
          highlight,
          '<mark style="background-color: yellow;">$highlight</mark>',
        );
      }
      provider.setCurrentEpubContent(content);
      currentEpubContentNotifier.value = content;

      // Update total pages for EPUB (based on chapters)
      FFAppState().totalPages = chapters.length;
      FFAppState().update(() {
        FFAppState().homePageTotalPdfPageIndex = chapters.length;
        FFAppState().homePageCurrentPdfIndex = provider.currentPage;
      });

      // Scroll to top when changing chapters
      if (epubScrollController.hasClients) {
        epubScrollController.jumpTo(0);
      }
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

        switch (themeMode) {
          case AppThemeMode.light:
            backgroundColor = Colors.white;
            break;
          case AppThemeMode.dark:
            backgroundColor = Colors.black;
            break;
          case AppThemeMode.sepia:
            backgroundColor = const Color(0xFFF5DEB3); // Sepia color
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

                // Get viewport size for dynamic thresholds
                final viewportHeight = metrics.viewportDimension;
                final edgeThreshold = viewportHeight * 0.1; // 10% of viewport height
                final scrollDirectionThreshold = viewportHeight * 0.05; // 5% for direction detection
                final edgeScrollThreshold = 1.0; // Smaller threshold when at edges

                final currentPos = metrics.pixels;
                final previousPos = p.lastScrollPosition;
                final scrollDelta = currentPos - previousPos;

                // Check if at edges first (before updating position)
                final isAtBottom = currentPos >= metrics.maxScrollExtent - edgeThreshold;
                final isAtTop = currentPos <= metrics.minScrollExtent + edgeThreshold;

                // Update last scroll position
                p.setLastScrollPosition(currentPos);

                // Determine scroll direction based on actual movement
                // Use smaller threshold when at edges to catch edge cases
                final effectiveThreshold = (isAtBottom || isAtTop) 
                    ? edgeScrollThreshold 
                    : scrollDirectionThreshold;
                
                final isScrollingDown = scrollDelta > effectiveThreshold;
                final isScrollingUp = scrollDelta < -effectiveThreshold;
                
                // Also check if user is attempting to scroll at edges (even if delta is small)
                // This handles cases where user is at edge and tries to scroll further
                final attemptingScrollDown = isAtBottom && scrollDelta >= 0 && !isScrollingUp;
                final attemptingScrollUp = isAtTop && scrollDelta <= 0 && !isScrollingDown;

                // Handle edge detection during active scrolling (ScrollUpdateNotification)
                if (notification is ScrollUpdateNotification) {
                  // User scrolled down and reached bottom - go to NEXT chapter
                  if ((isScrollingDown || attemptingScrollDown) && 
                      isAtBottom &&
                      p.currentEpubChapterIndex < p.epubChapters.length - 1) {
                    p.setChangingChapter(true);
                    loadEpubChapter(p.currentEpubChapterIndex + 1);

                    // After chapter loads, position at TOP
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (epubScrollController.hasClients) {
                          epubScrollController.jumpTo(1);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        } else {
                          // Fallback: reset flag if controller not ready
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        }
                      });
                    });
                    return true;
                  }

                  // User scrolled up and reached top - go to PREVIOUS chapter
                  if ((isScrollingUp || attemptingScrollUp) && 
                      isAtTop &&
                      p.currentEpubChapterIndex > 0) {
                    p.setChangingChapter(true);
                    loadEpubChapter(p.currentEpubChapterIndex - 1);

                    // After chapter loads, position at BOTTOM
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (epubScrollController.hasClients) {
                          final maxScroll = epubScrollController.position.maxScrollExtent;
                          if (maxScroll > 0) {
                            epubScrollController.jumpTo(maxScroll - 1);
                          }
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        } else {
                          // Fallback: reset flag if controller not ready
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        }
                      });
                    });
                    return true;
                  }
                }

                // Handle edge detection on scroll end (ScrollEndNotification) as fallback
                if (notification is ScrollEndNotification) {
                  // User scrolled down and reached bottom - go to NEXT chapter
                  if ((isScrollingDown || attemptingScrollDown) && 
                      isAtBottom &&
                      p.currentEpubChapterIndex < p.epubChapters.length - 1) {
                    p.setChangingChapter(true);
                    loadEpubChapter(p.currentEpubChapterIndex + 1);

                    // After chapter loads, position at TOP
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (epubScrollController.hasClients) {
                          epubScrollController.jumpTo(1);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        } else {
                          // Fallback: reset flag if controller not ready
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        }
                      });
                    });
                    return true;
                  }

                  // User scrolled up and reached top - go to PREVIOUS chapter
                  if ((isScrollingUp || attemptingScrollUp) && 
                      isAtTop &&
                      p.currentEpubChapterIndex > 0) {
                    p.setChangingChapter(true);
                    loadEpubChapter(p.currentEpubChapterIndex - 1);

                    // After chapter loads, position at BOTTOM
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (epubScrollController.hasClients) {
                          final maxScroll = epubScrollController.position.maxScrollExtent;
                          if (maxScroll > 0) {
                            epubScrollController.jumpTo(maxScroll - 1);
                          }
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        } else {
                          // Fallback: reset flag if controller not ready
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              p.setChangingChapter(false);
                            }
                          });
                        }
                      });
                    });
                    return true;
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: epubScrollController,
                padding: const EdgeInsets.all(20),
                child: ValueListenableBuilder<String>(
                  valueListenable: currentEpubContentNotifier,
                  builder: (context, content, child) {
                    return Selector<PdfViewerProvider, (double, double, AppThemeMode)>(
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
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

