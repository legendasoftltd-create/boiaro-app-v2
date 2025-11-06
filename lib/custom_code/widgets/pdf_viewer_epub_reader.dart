import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/providers/pdf_viewer_provider.dart';
import 'package:a_i_ebook_app/custom_code/extensions/epub_image_extension.dart';
import 'package:a_i_ebook_app/custom_code/extensions/custom_text_selection_controls.dart';

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

                if (notification is ScrollUpdateNotification) {
                  p.setLastScrollPosition(notification.metrics.pixels);
                }

                if (notification is ScrollEndNotification) {
                  if (p.isChangingChapter) return true;

                  final metrics = notification.metrics;
                  final lastPos = p.lastScrollPosition;
                  final scrollingDown = lastPos > metrics.minScrollExtent + 50;
                  final scrollingUp = lastPos < metrics.maxScrollExtent - 50;

                  // User scrolled down and reached bottom - go to NEXT chapter
                  if (scrollingDown &&
                      metrics.pixels >= metrics.maxScrollExtent - 10 &&
                      p.currentEpubChapterIndex < p.epubChapters.length - 1) {
                    p.setChangingChapter(true);
                    loadEpubChapter(p.currentEpubChapterIndex + 1);

                    // After chapter loads, position at TOP
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (epubScrollController.hasClients) {
                          epubScrollController.jumpTo(1);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            p.setChangingChapter(false);
                          });
                        }
                      });
                    });
                    return true;
                  }

                  // User scrolled up and reached top - go to PREVIOUS chapter
                  if (scrollingUp &&
                      metrics.pixels <= metrics.minScrollExtent + 10 &&
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
                            p.setChangingChapter(false);
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

                        Color bgColor;
                        Color txtColor;
                        switch (themeMode) {
                          case AppThemeMode.light:
                            bgColor = Colors.white;
                            txtColor = Colors.black;
                            break;
                          case AppThemeMode.dark:
                            bgColor = Colors.black;
                            txtColor = Colors.white;
                            break;
                          case AppThemeMode.sepia:
                            bgColor = const Color(0xFFF5DEB3);
                            txtColor = Colors.black;
                            break;
                        }

                        return Html(
                          data: content,
                          style: {
                            "body": Style(
                              fontFamily: 'SF Pro Display',
                              fontSize: FontSize(fontSize),
                              letterSpacing: 0.3,
                              lineHeight: LineHeight.em(lineHeight),
                              textAlign: TextAlign.justify,
                              color: txtColor,
                              backgroundColor: bgColor,
                            ),
                            "p": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              color: txtColor,
                            ),
                            "h1": Style(
                              fontSize: FontSize(fontSize * 1.8),
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "h2": Style(
                              fontSize: FontSize(fontSize * 1.6),
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "h3": Style(
                              fontSize: FontSize(fontSize * 1.4),
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "h4": Style(
                              fontSize: FontSize(fontSize * 1.2),
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "h5": Style(
                              fontSize: FontSize(fontSize * 1.1),
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "h6": Style(
                              fontSize: FontSize(fontSize),
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "strong": Style(
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "em": Style(
                              fontStyle: FontStyle.italic,
                              color: txtColor,
                            ),
                            "ul": Style(
                              listStyleType: ListStyleType.disc,
                              margin: Margins.only(left: 20),
                              color: txtColor,
                            ),
                            "ol": Style(
                              listStyleType: ListStyleType.decimal,
                              margin: Margins.only(left: 20),
                              color: txtColor,
                            ),
                            "li": Style(
                              margin: Margins.only(bottom: 8),
                              color: txtColor,
                            ),
                            "table": Style(
                              backgroundColor: FlutterFlowTheme.of(context)
                                  .alternate
                                  .withOpacity(0.1),
                              border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate),
                              width: Width.auto(),
                              color: txtColor,
                            ),
                            "th": Style(
                              padding: HtmlPaddings.all(8),
                              backgroundColor: FlutterFlowTheme.of(context).alternate,
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                            "td": Style(
                              padding: HtmlPaddings.all(8),
                              border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate),
                              color: txtColor,
                            ),
                          },
                          extensions: [
                            EpubImageExtension(epubBook),
                            TableHtmlExtension(),
                            SvgHtmlExtension(),
                          ],
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

