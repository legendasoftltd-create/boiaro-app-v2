// Automatic FlutterFlow imports
import 'dart:developer';

import 'package:a_i_ebook_app/custom_code/widgets/theme_selection_widget.dart';
import 'package:a_i_ebook_app/custom_code/widgets/font_selection_widget.dart';
import 'package:a_i_ebook_app/custom_code/widgets/bookmarks_highlights_drawer.dart';
import 'package:a_i_ebook_app/custom_code/widgets/table_of_contents_drawer.dart';
import 'package:a_i_ebook_app/custom_code/widgets/search_drawer.dart';

import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:screen_protector/screen_protector.dart';
import '/providers/pdf_viewer_provider.dart';
import 'pdf_viewer_helpers.dart';
import 'pdf_viewer_epub_reader.dart';
import 'pdf_viewer_text_operations.dart';
import 'pdf_viewer_pdf_operations.dart';
import 'pdf_viewer_epub_search.dart';
import 'pdf_viewer_settings_dialogs.dart';
import 'speech_player_bar.dart';

class FlutterPdfViewWidget extends StatefulWidget {
  const FlutterPdfViewWidget({
    super.key,
    this.width,
    this.height,
    this.filePath,
    this.namePage,
  });

  final double? width;
  final double? height;
  final String? filePath;
  final String? namePage;

  @override
  State<FlutterPdfViewWidget> createState() => _FlutterPdfViewWidgetState();
}

PdfViewerController pdfViewerController = PdfViewerController();

class _FlutterPdfViewWidgetState extends State<FlutterPdfViewWidget> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _epubScrollController = ScrollController();
  final ValueNotifier<String> _currentEpubContentNotifier =
      ValueNotifier<String>('');
  final ValueNotifier<String> _localSelectedTextNotifier =
      ValueNotifier<String>('');
  final ValueNotifier<bool> _isAtTopNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isAtBottomNotifier = ValueNotifier<bool>(false);
  String? _currentBookId;
  String? _originalChapterHtml; // Store original HTML before highlights

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    
    // Add scroll listener to detect top/bottom position
    _epubScrollController.addListener(_checkScrollPosition);
    
    // Listen to content changes to check scroll position after content loads
    _currentEpubContentNotifier.addListener(_onContentChanged);
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PdfViewerProvider>();
      // Generate book ID from file path
      _currentBookId = PdfViewerTextOperations.generateBookId(widget.filePath);
      // Load highlights and bookmarks for this book
      provider.loadHighlights(_currentBookId!);
      provider.loadBookmarks(_currentBookId!);
      
      PdfViewerHelpers.determineReaderType(widget.filePath, provider);
      provider.setCurrentPage(1);
      PdfViewerHelpers.getInitialBrightness(provider);
      if (provider.readerType == ReaderType.epub) {
        EpubReaderWidget.loadEpubBook(
          widget.filePath,
          provider,
          context,
          (index) => EpubReaderWidget.loadEpubChapter(
            provider,
            index,
            _currentEpubContentNotifier,
            _epubScrollController,
            onOriginalContentReady: (originalHtml) {
              // Store original HTML for position tracking
              _originalChapterHtml = originalHtml;
              // Apply search highlights if there's an active search
              if (provider.epubSearchText != null && provider.epubSearchText!.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  _applyEpubSearchHighlights(provider);
                });
              }
            },
          ),
        );
      }
      ScreenProtector.protectDataLeakageOn();
    });
  }

  void _onContentChanged() {
    // Check scroll position after content changes and layout completes
    // Use post frame callback to ensure layout is complete
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Additional delay to ensure scroll animation completes (if any)
      Future.delayed(const Duration(milliseconds: 400), () {
        _checkScrollPosition();
      });
    });
  }

  void _checkScrollPosition() {
    if (!mounted) return;
    
    if (!_epubScrollController.hasClients) {
      // If no clients, assume we're at top
      if (_isAtTopNotifier.value != true) {
        _isAtTopNotifier.value = true;
      }
      if (_isAtBottomNotifier.value != false) {
        _isAtBottomNotifier.value = false;
      }
      return;
    }
    
    try {
      final position = _epubScrollController.position;
      
      // Check if position is valid
      if (!position.hasContentDimensions) {
        // Wait a bit and try again if layout isn't ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _checkScrollPosition();
        });
        return;
      }
      
      if (!position.hasPixels) {
        return;
      }
      
      // Check if content is scrollable
      final maxScroll = position.maxScrollExtent;
      final currentPixels = position.pixels.clamp(0.0, maxScroll);
      
      if (maxScroll <= 0) {
        // Content is not scrollable (too short), show both buttons
        _isAtTopNotifier.value = true;
        _isAtBottomNotifier.value = true;
        return;
      }
      
      // 20px threshold for detecting top/bottom (reduced for more sensitive detection)
      final threshold = 100.0;
      
      final isAtTop = currentPixels <= threshold;
      final isAtBottom = currentPixels >= (maxScroll - threshold);
      
      // Always update to ensure state is correct (even if same value to trigger rebuild)
      if (_isAtTopNotifier.value != isAtTop) {
        _isAtTopNotifier.value = isAtTop;
      }
      if (_isAtBottomNotifier.value != isAtBottom) {
        _isAtBottomNotifier.value = isAtBottom;
      }
    } catch (e) {
      // If there's an error, default to top
      _isAtTopNotifier.value = true;
      _isAtBottomNotifier.value = false;
    }
  }


  @override
  void dispose() {
    final provider = context.read<PdfViewerProvider>();
    PdfViewerHelpers.restoreOriginalBrightness(provider);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _searchController.dispose();
    _epubScrollController.removeListener(_checkScrollPosition);
    _epubScrollController.dispose();
    _currentEpubContentNotifier.removeListener(_onContentChanged);
    _currentEpubContentNotifier.dispose();
    _localSelectedTextNotifier.dispose();
    _isAtTopNotifier.dispose();
    _isAtBottomNotifier.dispose();
    flutterTts.stop();
    ScreenProtector.protectDataLeakageOff();
    super.dispose();
  }

  void setCurrentPage(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.epub) {
      if (provider.currentEpubChapterIndex < provider.epubChapters.length - 1) {
        EpubReaderWidget.loadEpubChapter(
          provider,
          provider.currentEpubChapterIndex + 1,
          _currentEpubContentNotifier,
          _epubScrollController,
          onOriginalContentReady: (originalHtml) {
            _originalChapterHtml = originalHtml;
          },
        );
      }
    } else {
      if (provider.currentPage != FFAppState().totalPages) {
        provider.incrementPage();
        pdfViewerController.jumpToPage(provider.currentPage);
      }
    }
  }

  void setCurrentMinusPage(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.epub) {
      if (provider.currentEpubChapterIndex > 0) {
        EpubReaderWidget.loadEpubChapter(
          provider,
          provider.currentEpubChapterIndex - 1,
          _currentEpubContentNotifier,
          _epubScrollController,
          onOriginalContentReady: (originalHtml) {
            _originalChapterHtml = originalHtml;
          },
        );
      }
    } else {
      if (provider.currentPage > 1) {
        provider.decrementPage();
        pdfViewerController.jumpToPage(provider.currentPage);
      }
    }
  }

  void _addHighlight(PdfViewerProvider provider) async {
    if (_currentBookId == null) {
      log('Cannot highlight: bookId is null');
      return;
    }
    
    // If original HTML is not stored, use current content (before any highlights)
    // This handles the case where chapter was loaded before we started tracking original content
    String originalHtml = _originalChapterHtml ?? _currentEpubContentNotifier.value;
    
    // Remove any existing mark tags from original HTML to get clean content
    if (originalHtml.contains('<mark')) {
      originalHtml = originalHtml.replaceAll(RegExp(r'<mark[^>]*>'), '').replaceAll('</mark>', '');
    }
    
    final chapterId = provider.currentEpubChapterIndex.toString();
    final chapterName = provider.epubChapters.isNotEmpty && 
        provider.currentEpubChapterIndex < provider.epubChapters.length
        ? provider.epubChapters[provider.currentEpubChapterIndex].Title ?? 'Chapter ${provider.currentEpubChapterIndex + 1}'
        : 'Chapter ${provider.currentEpubChapterIndex + 1}';
    
    await PdfViewerTextOperations.addHighlight(
      provider,
      _localSelectedTextNotifier,
      _currentEpubContentNotifier,
      _currentBookId,
      chapterId,
      chapterName,
      originalHtml,
    );
  }

  // Old _addHighlightOld function removed - using new HighlightModel system in _addHighlight
  
  // Helper method to check if a position is inside an existing mark tag
  bool _isInsideMark(int position, String content) {
    // Look backwards for opening mark tag
    int start = position;
    while (start > 0 && start > position - 100) {
      if (content.substring(start, start + 5) == '<mark') {
        return true;
      }
      if (content.substring(start, start + 6) == '</mark') {
        return false;
      }
      start--;
    }
    return false;
  }
  
  // Helper method to extract text at a position, skipping HTML tags
  String? _extractTextAtPosition(String content, int start, int length) {
    StringBuffer buffer = StringBuffer();
    int pos = start;
    int found = 0;
    
    while (pos < content.length && found < length && pos < start + length * 3) {
      if (content[pos] == '<') {
        // Skip HTML tags
        while (pos < content.length && content[pos] != '>') {
          pos++;
        }
        if (pos < content.length) pos++;
      } else if (content[pos] == '&') {
        // Handle HTML entities
        int entityEnd = content.indexOf(';', pos);
        if (entityEnd != -1) {
          buffer.write(content.substring(pos, entityEnd + 1));
          pos = entityEnd + 1;
          found++;
        } else {
          buffer.write(content[pos]);
          pos++;
          found++;
        }
      } else {
        buffer.write(content[pos]);
        pos++;
        found++;
      }
    }
    
    final result = buffer.toString();
    return result.length >= length ? result : null;
  }

  void _toggleBookmark(PdfViewerProvider provider) async {
    if (_currentBookId == null) {
      log('Cannot toggle bookmark: bookId is null');
      return;
    }

    final currentPage = provider.currentPage;
    String? chapterId;
    String? chapterName;

    // For EPUB, get chapter info
    if (provider.readerType == ReaderType.epub) {
      chapterId = provider.currentEpubChapterIndex.toString();
      if (provider.epubChapters.isNotEmpty && 
          provider.currentEpubChapterIndex < provider.epubChapters.length) {
        chapterName = provider.epubChapters[provider.currentEpubChapterIndex].Title ?? 
            'Chapter ${provider.currentEpubChapterIndex + 1}';
      } else {
        chapterName = 'Chapter ${provider.currentEpubChapterIndex + 1}';
      }
    } else {
      // For PDF, use page number
      chapterId = currentPage.toString();
      chapterName = 'Page $currentPage';
    }

    await provider.toggleBookmark(
      currentPage,
      bookId: _currentBookId,
      chapterId: chapterId,
      chapterName: chapterName,
    );
  }

  Future<void> _speakSelected(PdfViewerProvider provider) async {
    await PdfViewerTextOperations.speakSelected(
      provider,
      flutterTts,
      _localSelectedTextNotifier,
    );
  }

  Future<void> _stopSpeaking(PdfViewerProvider provider) async {
    await PdfViewerTextOperations.stopSpeaking(provider, flutterTts);
  }

  Future<void> _startReadingChapter(PdfViewerProvider provider) async {
    final htmlContent = _currentEpubContentNotifier.value;
    if (htmlContent.isEmpty) return;

    await PdfViewerTextOperations.startReadingChapter(
      provider,
      flutterTts,
      htmlContent,
      (sentence) {
        // Highlight sentence in HTML content
        _highlightSentenceInContent(sentence);
      },
      (position) {
        // Auto-scroll to position
        if (_epubScrollController.hasClients) {
          _epubScrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  Future<void> _pauseReadingChapter(PdfViewerProvider provider) async {
    await PdfViewerTextOperations.pauseReadingChapter(provider, flutterTts);
  }

  Future<void> _resumeReadingChapter(PdfViewerProvider provider) async {
    // Always restart the reading loop to ensure it's running
    // This handles cases where the loop might have exited while paused
    if (provider.chapterSentences.isNotEmpty) {
      // Restart reading from current sentence index
      // The startReadingChapter function will handle the pause state correctly
      await _startReadingChapter(provider);
    } else {
      // No sentences available, just unpause if reading
      if (provider.isReadingChapter) {
        provider.setPaused(false);
      }
    }
  }

  Future<void> _stopReadingChapter(PdfViewerProvider provider) async {
    await PdfViewerTextOperations.stopReadingChapter(provider, flutterTts);
  }

  void _highlightSentenceInContent(String sentence) {
    final currentContent = _currentEpubContentNotifier.value;
    final normalizedSentence = sentence.trim();
    final p = context.read<PdfViewerProvider>();
    
    // Try to find and highlight the sentence in HTML
    if (currentContent.contains(normalizedSentence)) {
      // Remove existing read-aloud highlights but preserve the text
      // Extract text from mark tags before removing them - handle both plain text and HTML entities
      String cleanedContent = currentContent;
      
      // Remove mark tags but keep the text inside
      // Use a more robust regex that handles nested content
      cleanedContent = cleanedContent.replaceAllMapped(
        RegExp(r'<mark class="reading-sentence"[^>]*>(.*?)</mark>', dotAll: true),
        (match) {
          final innerText = match.group(1) ?? '';
          // Return the inner text, preserving any HTML entities
          return innerText;
        },
      );
      
      // Add new highlight - find the sentence in cleaned content
      String highlightedContent = cleanedContent;
      
      // Try to find sentence in cleaned content (handle HTML entities)
      int sentenceStartIndex = cleanedContent.indexOf(normalizedSentence);
      
      // If not found, try with HTML entities escaped
      if (sentenceStartIndex == -1) {
        final escapedSentence = normalizedSentence
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
        sentenceStartIndex = cleanedContent.indexOf(escapedSentence);
        if (sentenceStartIndex != -1) {
          highlightedContent = cleanedContent.replaceFirst(
            escapedSentence,
            '<mark class="reading-sentence" id="reading-sentence-${p.currentReadingSentenceIndex}" style="background-color: rgba(33, 150, 243, 0.3);">$escapedSentence</mark>',
            sentenceStartIndex,
          );
        }
      } else {
        // Found with plain text
        highlightedContent = cleanedContent.replaceFirst(
          normalizedSentence,
          '<mark class="reading-sentence" id="reading-sentence-${p.currentReadingSentenceIndex}" style="background-color: rgba(33, 150, 243, 0.3);">$normalizedSentence</mark>',
          sentenceStartIndex,
        );
      }
      
      // Update content first
      _currentEpubContentNotifier.value = highlightedContent;
      p.setCurrentEpubContent(highlightedContent);
      
      // Calculate and scroll to position after content is updated
      // Wait for layout to complete before calculating scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlightedSentence(sentenceStartIndex, cleanedContent.length);
      });
    }
  }

  /// Extract visible text from HTML (excluding tags) for accurate position calculation
  String _extractVisibleText(String html) {
    // Remove HTML tags but keep text content
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void _scrollToHighlightedSentence(int sentenceCharIndex, int totalContentLength) {
    if (!_epubScrollController.hasClients || !mounted) return;
    
    // Wait for layout to complete after content update
    // Use multiple post-frame callbacks to ensure layout is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_epubScrollController.hasClients || !mounted) return;
        
        try {
          final scrollPosition = _epubScrollController.position;
          final maxScroll = scrollPosition.maxScrollExtent;
          final viewportHeight = scrollPosition.viewportDimension;
          
          if (maxScroll <= 0) return;
          
          final p = context.read<PdfViewerProvider>();
          final currentSentenceIndex = p.currentReadingSentenceIndex;
          final totalSentences = p.chapterSentences.length;
          
          // Get the current content to calculate visible text position
          final currentContent = _currentEpubContentNotifier.value;
          
          double contentRatio;
          
          // Primary method: Use sentence index for more accurate positioning
          // This is more reliable than character position since sentences are evenly distributed
          if (totalSentences > 0) {
            // Use sentence index with slight adjustment for better accuracy
            contentRatio = currentSentenceIndex / totalSentences;
            
            // Fine-tune using visible text position as a secondary check
            if (totalContentLength > 0 && currentContent.isNotEmpty) {
              final contentBeforeSentence = currentContent.substring(0, sentenceCharIndex.clamp(0, currentContent.length));
              final visibleTextBefore = _extractVisibleText(contentBeforeSentence);
              final totalVisibleText = _extractVisibleText(currentContent);
              
              if (totalVisibleText.isNotEmpty) {
                final visibleTextRatio = visibleTextBefore.length / totalVisibleText.length;
                // Blend both methods: 70% sentence index, 30% visible text position
                contentRatio = (contentRatio * 0.7) + (visibleTextRatio * 0.3);
              }
            }
          } else if (totalContentLength > 0) {
            // Fallback: Use visible text position if sentence index not available
            final contentBeforeSentence = currentContent.substring(0, sentenceCharIndex.clamp(0, currentContent.length));
            final visibleTextBefore = _extractVisibleText(contentBeforeSentence);
            final totalVisibleText = _extractVisibleText(currentContent);
            
            if (totalVisibleText.isNotEmpty) {
              contentRatio = visibleTextBefore.length / totalVisibleText.length;
            } else {
              // Last resort: use character position
              contentRatio = sentenceCharIndex / totalContentLength;
            }
          } else {
            return; // Cannot calculate position
          }
          
          // Calculate target scroll position
          // Position the sentence in the upper-middle of viewport (about 20% from top)
          // This ensures the sentence is visible and there's context above it
          double targetScrollPosition = contentRatio * maxScroll;
          
          // Adjust to account for viewport height - position text in upper-middle area
          // Subtract about 20% of viewport height to position text optimally
          // This ensures the highlighted sentence is visible in the viewport
          final viewportOffset = viewportHeight * 0.2;
          targetScrollPosition = (targetScrollPosition - viewportOffset).clamp(0.0, maxScroll);
          
          // Get current scroll position
          final currentScroll = scrollPosition.pixels;
          
          // Only scroll if the target position is significantly different from current
          // This prevents unnecessary scrolling when already close to target
          final scrollDifference = (targetScrollPosition - currentScroll).abs();
          if (scrollDifference > 80) {
            _epubScrollController.animateTo(
              targetScrollPosition,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else if (scrollDifference > 20) {
            // For smaller differences, use a faster animation
            _epubScrollController.animateTo(
              targetScrollPosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } catch (e) {
          // Fallback: use simpler proportional scrolling based on sentence index
          try {
            if (!_epubScrollController.hasClients || !mounted) return;
            final p = context.read<PdfViewerProvider>();
            final maxScroll = _epubScrollController.position.maxScrollExtent;
            final totalSentences = p.chapterSentences.length;
            
            if (maxScroll > 0 && totalSentences > 0) {
              final currentSentenceIndex = p.currentReadingSentenceIndex;
              final contentRatio = currentSentenceIndex / totalSentences;
              final targetScroll = (contentRatio * maxScroll).clamp(0.0, maxScroll);
              
              _epubScrollController.animateTo(
                targetScroll,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            } else if (maxScroll > 0 && totalContentLength > 0) {
              // Last fallback: character position
              final contentRatio = sentenceCharIndex / totalContentLength;
              final targetScroll = (contentRatio * maxScroll).clamp(0.0, maxScroll);
              
              _epubScrollController.animateTo(
                targetScroll,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          } catch (_) {
            // Ignore scroll errors
          }
        }
      });
    });
  }

  void _openTtsSettings(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openTtsSettings(context, provider, flutterTts);
  }

  void _openTtsSettingsOld(PdfViewerProvider provider) {
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

  void _openBrightnessSettings(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openBrightnessSettings(
      context,
      provider,
      (brightness) => PdfViewerHelpers.setBrightness(provider, brightness),
    );
  }

  void _openBrightnessSettingsOld(PdfViewerProvider provider) {
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
                            PdfViewerHelpers.setBrightness(provider, val);
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
                      _buildBrightnessPreset(context, provider, "25%", 0.25),
                      _buildBrightnessPreset(context, provider, "50%", 0.50),
                      _buildBrightnessPreset(context, provider, "75%", 0.75),
                      _buildBrightnessPreset(context, provider, "100%", 1.0),
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

  Widget _buildThemeModePreset(
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

  void _openFontSettings(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openFontSettings(context, provider);
  }

  void _openFontSettingsOld(PdfViewerProvider provider) {
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

                  /// Preview Text
                  /// Line Spacing Slider
                  const SizedBox(height: 24),
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

  void _openSearchOverlay(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openSearchOverlay(
      context,
      provider,
      _searchController,
      pdfViewerController,
      onSearchEpub: () => _searchEpub(provider),
      onNextResult: () => _goToNextSearchResult(provider),
      onPreviousResult: () => _goToPreviousSearchResult(provider),
      onClearSearch: () => _clearSearch(provider),
    );
  }

  void _openSearchOverlayOld(PdfViewerProvider provider) {
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
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Search text",
                      hintText: "Enter text to search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _clearSearch(provider);
                        },
                      ),
                    ),
                    onChanged: (value) {
                      provider.setSearchText(value);
                    },
                    onSubmitted: (value) {
                      if (provider.readerType == ReaderType.pdf) {
                        _searchPdf(provider);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
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
                                      _goToPreviousSearchResult(provider);
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: provider.searchResult.hasResult &&
                                      provider.searchResult.currentInstanceIndex <
                                          provider.searchResult.totalInstanceCount - 1
                                  ? () {
                                      _goToNextSearchResult(provider);
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
                        _searchPdf(provider);
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
                      _clearSearch(provider);
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

  void _openBookmarkCollection(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openBookmarkCollection(
      context,
      provider,
      pdfViewerController,
      (index) => EpubReaderWidget.loadEpubChapter(
        provider,
        index,
        _currentEpubContentNotifier,
        _epubScrollController,
        onOriginalContentReady: (originalHtml) {
          _originalChapterHtml = originalHtml;
        },
      ),
    );
  }

  void _openHighlightsCollection(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openHighlightsCollection(
      context,
      provider,
      pdfViewerController,
      (index) => EpubReaderWidget.loadEpubChapter(
        provider,
        index,
        _currentEpubContentNotifier,
        _epubScrollController,
        onOriginalContentReady: (originalHtml) {
          _originalChapterHtml = originalHtml;
        },
      ),
    );
  }

  void _openBookmarkCollectionOld(PdfViewerProvider provider) {
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
                                    await provider.removeBookmark(pageNumber, bookId: _currentBookId);
                                  },
                                ),
                                onTap: () {
                                  if (provider.readerType == ReaderType.pdf) {
                                    pdfViewerController.jumpToPage(pageNumber);
                                    provider.setCurrentPage(pageNumber);
                                  } else {
                                    EpubReaderWidget.loadEpubChapter(
                                      provider,
                                      pageNumber - 1,
                                      _currentEpubContentNotifier,
                                      _epubScrollController,
                                      onOriginalContentReady: (originalHtml) {
                                        _originalChapterHtml = originalHtml;
                                      },
                                    );
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

  void _openChapterList(PdfViewerProvider provider) {
    PdfViewerSettingsDialogs.openChapterList(
      context,
      provider,
      (index) => EpubReaderWidget.loadEpubChapter(
        provider,
        index,
        _currentEpubContentNotifier,
        _epubScrollController,
        onOriginalContentReady: (originalHtml) {
          _originalChapterHtml = originalHtml;
        },
      ),
    );
  }

  void _openChapterListOld(PdfViewerProvider provider) {
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
                            EpubReaderWidget.loadEpubChapter(
                              provider,
                              index,
                              _currentEpubContentNotifier,
                              _epubScrollController,
                              onOriginalContentReady: (originalHtml) {
                                _originalChapterHtml = originalHtml;
                              },
                            );
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

  void _searchPdf(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.pdf) {
      provider.setSearching(true);
      PdfViewerPdfOperations.searchPdf(provider, pdfViewerController);
      // Clear loading after search completes (PDF search is synchronous)
      Future.delayed(const Duration(milliseconds: 300), () {
        provider.setSearching(false);
      });
    } else {
      _searchEpub(provider);
    }
  }

  Future<void> _searchEpub(PdfViewerProvider provider) async {
    final searchText = provider.searchText.trim();
    if (searchText.isEmpty) {
      _clearEpubSearch(provider);
      return;
    }

    // Set loading state
    provider.setSearching(true);

    try {
      // Search across all chapters
      final results = await PdfViewerEpubSearch.searchInEpub(provider, searchText);
      
      if (results.isNotEmpty) {
        provider.setEpubSearchResults(
          results.length,
          PdfViewerEpubSearch.getCurrentResultIndex(),
          searchText,
        );
        
        // Navigate to first result
        final firstResult = results[0];
        _navigateToEpubSearchResult(provider, firstResult);
      } else {
        provider.setEpubSearchResults(0, -1, searchText);
      }
    } finally {
      // Loading state will be cleared in setEpubSearchResults
    }
  }

  void _navigateToEpubSearchResult(PdfViewerProvider provider, EpubSearchResult result) {
    // Set navigating state
    provider.setNavigatingSearchResult(true);

    // Load the chapter if not already loaded
    if (provider.currentEpubChapterIndex != result.chapterIndex) {
      EpubReaderWidget.loadEpubChapter(
        provider,
        result.chapterIndex,
        _currentEpubContentNotifier,
        _epubScrollController,
        onOriginalContentReady: (originalHtml) {
          _originalChapterHtml = originalHtml;
          // Apply search highlights after chapter loads
          _applyEpubSearchHighlights(provider);
          // Clear navigating state after a delay to allow UI to update
          Future.delayed(const Duration(milliseconds: 300), () {
            provider.setNavigatingSearchResult(false);
          });
        },
      );
    } else {
      // Chapter already loaded, just apply highlights
      _applyEpubSearchHighlights(provider);
      // Clear navigating state after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        provider.setNavigatingSearchResult(false);
      });
    }
  }

  void _applyEpubSearchHighlights(PdfViewerProvider provider) {
    if (provider.epubSearchText == null || provider.epubSearchText!.isEmpty) {
      return;
    }

    final currentContent = _currentEpubContentNotifier.value;
    // Clear previous search highlights
    final cleanContent = PdfViewerEpubSearch.clearSearchHighlights(currentContent);
    // Apply new search highlights
    final highlightedContent = PdfViewerEpubSearch.highlightSearchResults(
      cleanContent,
      provider.epubSearchText!,
    );
    
    provider.setCurrentEpubContent(highlightedContent);
    _currentEpubContentNotifier.value = highlightedContent;
  }

  void _clearEpubSearch(PdfViewerProvider provider) {
    PdfViewerEpubSearch.clearResults();
    provider.clearEpubSearch();
    
    // Remove search highlights from current content
    final currentContent = _currentEpubContentNotifier.value;
    final cleanContent = PdfViewerEpubSearch.clearSearchHighlights(currentContent);
    provider.setCurrentEpubContent(cleanContent);
    _currentEpubContentNotifier.value = cleanContent;
  }

  void _clearSearch(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.pdf) {
      PdfViewerPdfOperations.clearSearch(provider, _searchController);
    } else {
      _clearEpubSearch(provider);
      _searchController.clear();
    }
  }

  void _goToNextSearchResult(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.pdf) {
      provider.setNavigatingSearchResult(true);
      PdfViewerPdfOperations.goToNextSearchResult(provider);
      Future.delayed(const Duration(milliseconds: 300), () {
        provider.setNavigatingSearchResult(false);
      });
    } else {
      _goToNextEpubSearchResult(provider);
    }
  }

  void _goToPreviousSearchResult(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.pdf) {
      provider.setNavigatingSearchResult(true);
      PdfViewerPdfOperations.goToPreviousSearchResult(provider);
      Future.delayed(const Duration(milliseconds: 300), () {
        provider.setNavigatingSearchResult(false);
      });
    } else {
      _goToPreviousEpubSearchResult(provider);
    }
  }

  void _goToNextEpubSearchResult(PdfViewerProvider provider) {
    final nextResult = PdfViewerEpubSearch.getNextResult();
    if (nextResult != null) {
      provider.setEpubSearchResults(
        PdfViewerEpubSearch.getTotalResults(),
        PdfViewerEpubSearch.getCurrentResultIndex(),
        provider.epubSearchText ?? '',
      );
      _navigateToEpubSearchResult(provider, nextResult);
    }
  }

  void _goToPreviousEpubSearchResult(PdfViewerProvider provider) {
    final prevResult = PdfViewerEpubSearch.getPreviousResult();
    if (prevResult != null) {
      provider.setEpubSearchResults(
        PdfViewerEpubSearch.getTotalResults(),
        PdfViewerEpubSearch.getCurrentResultIndex(),
        provider.epubSearchText ?? '',
      );
      _navigateToEpubSearchResult(provider, prevResult);
    }
  }

  Widget _buildBrightnessPreset(
    BuildContext context,
    PdfViewerProvider provider,
    String label,
    double value,
  ) {
    final isSelected = (provider.currentBrightness - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        PdfViewerHelpers.setBrightness(provider, value);
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

  Widget _buildLineHeightPreset(
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

  Widget _buildFontPreset(
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


Widget _buildEpubReader() {
    return EpubReaderWidget.buildEpubReader(
      currentEpubContentNotifier: _currentEpubContentNotifier,
      localSelectedTextNotifier: _localSelectedTextNotifier,
      epubScrollController: _epubScrollController,
      addHighlight: () => _addHighlight(context.read<PdfViewerProvider>()),
      speakSelected: () => _speakSelected(context.read<PdfViewerProvider>()),
      stopSpeaking: () => _stopSpeaking(context.read<PdfViewerProvider>()),
      loadEpubChapter: (index) => EpubReaderWidget.loadEpubChapter(
        context.read<PdfViewerProvider>(),
        index,
        _currentEpubContentNotifier,
        _epubScrollController,
        onOriginalContentReady: (originalHtml) {
          _originalChapterHtml = originalHtml;
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    // Use Selector instead of Consumer to only listen to colors-related state
    // This prevents rebuilds when isSpeaking or other unrelated state changes
    return Selector<PdfViewerProvider, (ReaderType, AppThemeMode, bool)>(
      selector: (_, p) => (p.readerType, p.currentThemeMode, p.isFullScreen),
      builder: (context, data, child) {
        final readerType = data.$1;
        final themeMode = data.$2;
        final isFullScreen = data.$3;
        final provider = context.read<PdfViewerProvider>();
        
        log("_currentEpubContent: ${provider.currentEpubContent}");
        Color scaffoldBackgroundColor;
        Color appBarBackgroundColor;
        Color appBarTextColor;
        Color bottomNavIconColor;

        if (readerType == ReaderType.epub) {
          switch (themeMode) {
            case AppThemeMode.light:
              scaffoldBackgroundColor = Colors.white;
              appBarBackgroundColor = FlutterFlowTheme.of(context).secondaryBackground;
              appBarTextColor = Colors.black;
              bottomNavIconColor = FlutterFlowTheme.of(context).secondaryText;
              break;
            case AppThemeMode.dark:
              scaffoldBackgroundColor = Colors.black;
              appBarBackgroundColor = Colors.black; // Darker app bar for full screen
              appBarTextColor = Colors.white;
              bottomNavIconColor = Colors.white;
              break;
            case AppThemeMode.sepia:
              scaffoldBackgroundColor = const Color(0xFFF5DEB3); // Sepia color
              appBarBackgroundColor = FlutterFlowTheme.of(context).secondaryBackground;
              appBarTextColor = Colors.black;
              bottomNavIconColor = FlutterFlowTheme.of(context).secondaryText;
              break;
          }
        } else {
          scaffoldBackgroundColor = FlutterFlowTheme.of(context).primaryBackground;
          appBarBackgroundColor = FlutterFlowTheme.of(context).secondaryBackground;
          appBarTextColor = FlutterFlowTheme.of(context).primaryText;
          bottomNavIconColor = FlutterFlowTheme.of(context).secondaryText;
        }

        // Adjust colors for full screen mode if it's dark theme
        if (isFullScreen && themeMode == AppThemeMode.dark) {
          scaffoldBackgroundColor = Colors.black;
          appBarBackgroundColor = Colors.black;
          appBarTextColor = Colors.white;
          bottomNavIconColor = Colors.white;
        }

        return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBackgroundColor,
      onDrawerChanged: (isOpened) {
        if (!isOpened && (provider.openDrawer == 'bookmarks' || provider.openDrawer == 'toc')) {
          // Clear the drawer state when drawer is dismissed
          provider.setOpenDrawer(null);
        }
      },
      onEndDrawerChanged: (isOpened) {
        if (!isOpened && provider.openDrawer == 'search') {
          // Clear the drawer state when drawer is dismissed
          provider.setOpenDrawer(null);
        }
      },
      drawer: Selector<PdfViewerProvider, String?>(
        selector: (_, p) => p.openDrawer,
        builder: (context, openDrawer, child) {
          if (openDrawer == 'bookmarks') {
            return BookmarksHighlightsDrawer(
              pdfController: pdfViewerController,
              loadEpubChapter: (index) => EpubReaderWidget.loadEpubChapter(
                provider,
                index,
                _currentEpubContentNotifier,
                _epubScrollController,
                onOriginalContentReady: (originalHtml) {
                  _originalChapterHtml = originalHtml;
                },
              ),
            );
          } else if (openDrawer == 'toc') {
            return TableOfContentsDrawer(
              loadEpubChapter: (index) => EpubReaderWidget.loadEpubChapter(
                provider,
                index,
                _currentEpubContentNotifier,
                _epubScrollController,
                onOriginalContentReady: (originalHtml) {
                  _originalChapterHtml = originalHtml;
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      endDrawer: Selector<PdfViewerProvider, String?>(
        selector: (_, p) => p.openDrawer,
        builder: (context, openDrawer, child) {
          if (openDrawer == 'search') {
            return SearchDrawer(
              searchController: _searchController,
              pdfController: pdfViewerController,
              onSearchEpub: () => _searchEpub(provider),
              onNextResult: () => _goToNextSearchResult(provider),
              onPreviousResult: () => _goToPreviousSearchResult(provider),
              onClearSearch: () => _clearSearch(provider),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: Selector<PdfViewerProvider, String?>(
        selector: (_, p) => p.openDrawer,
        builder: (context, openDrawer, child) {
          // Open drawer when state changes
          if (openDrawer == 'search') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scaffoldKey.currentState != null) {
                _scaffoldKey.currentState!.openEndDrawer();
              }
            });
          } else if (openDrawer == 'bookmarks' || openDrawer == 'toc') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scaffoldKey.currentState != null) {
                _scaffoldKey.currentState!.openDrawer();
              }
            });
          }
          return Column(
            children: [
          /// ---------- AppBar ----------
          Visibility(
            visible: !isFullScreen,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: appBarBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () async => context.safePop(),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 22,
                      color: appBarTextColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.namePage ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            useGoogleFonts: false,
                            color: appBarTextColor,
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      // Search button - available for both PDF and EPUB
                      InkWell(
                        onTap: () {
                          provider.setOpenDrawer('search');
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        child: Icon(
                          Icons.search,
                          size: 24,
                          color: appBarTextColor,
                        ),
                      ),
                      if (readerType == ReaderType.epub) ...[
                        const SizedBox(width: 16),
                        Selector<PdfViewerProvider, bool>(
                          selector: (_, p) => p.isReadingChapter,
                          builder: (context, isReadingChapter, child) {
                            final p = context.read<PdfViewerProvider>();
                            return InkWell(
                              onTap: () {
                                if (isReadingChapter) {
                                  _stopReadingChapter(p);
                                } else {
                                  _startReadingChapter(p);
                                }
                              },
                              child: Icon(
                                isReadingChapter
                                    ? Icons.spatial_audio
                                    : Icons.spatial_audio_off_rounded,
                                size: 24,
                                color: isReadingChapter
                                    ? FlutterFlowTheme.of(context).primary
                                    : appBarTextColor,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (provider.readerType == ReaderType.pdf) const SizedBox(width: 16),
                      Selector<PdfViewerProvider, (List<int>, int)>(
                        selector: (_, p) => (p.bookmarkedPages, p.currentPage),
                        builder: (context, data, child) {
                          final bookmarkedPages = data.$1;
                          final currentPage = data.$2;
                          final p = context.read<PdfViewerProvider>();
                          return InkWell(
                            onTap: () => _toggleBookmark(p),
                            child: Icon(
                              bookmarkedPages.contains(currentPage)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 24,
                              color: appBarTextColor,
                            ),
                          );
                        },
                      ),
                      // InkWell(
                      //   onTap: _openTtsSettings,
                      //   child: Icon(
                      //     Icons.more_vert,
                      //     size: 24,
                      //     color: appBarTextColor,
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// ---------- Content Viewer ----------
          Expanded(
            child: Stack(
              children: [
                if (readerType == ReaderType.pdf)
                  SfPdfViewer.network(
                    widget.filePath!,
                    key: _pdfViewerKey,
                    controller: pdfViewerController,
                    scrollDirection: PdfScrollDirection.vertical,
                    canShowTextSelectionMenu: true,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      int totalPages = details.document.pages.count;
                      FFAppState().totalPages = totalPages;
                      FFAppState().update(() {
                        FFAppState().homePageTotalPdfPageIndex =
                            FFAppState().totalPages;
                      });
                      pdfViewerController.jumpToPage(provider.currentPage);
                    },
                    onPageChanged: (details) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        provider.setCurrentPage(details.newPageNumber);
                        FFAppState().update(() {
                          FFAppState().homePageCurrentPdfIndex = provider.currentPage;
                        });
                      });
                    },
                    onTextSelectionChanged:
                        (PdfTextSelectionChangedDetails details) {
                      if (details.selectedText != null &&
                          details.selectedText!.isNotEmpty) {
                        provider.setSelectedText(details.selectedText!);
                      } else {
                        provider.clearSelectedText();
                      }
                    },
                  )
                else
                  _buildEpubReader(),

                /// Full Screen Exit Button (only visible in full screen)
                if (isFullScreen)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: InkWell(
                      onTap: () {
                        final p = context.read<PdfViewerProvider>();
                        PdfViewerHelpers.toggleFullScreen(p, context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen_exit_outlined,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          /// ---------- Bottom Navigation ----------
          /// Listen and Highlight controls
          /// Only show when user is speaking (after clicking Listen from toolbar)
          Selector<PdfViewerProvider, (bool, bool)>(
            selector: (_, p) => (p.isFullScreen, p.isSpeaking),
            builder: (context, data, child) {
              final isFullScreen = data.$1;
              final isSpeaking = data.$2;
              final p = context.read<PdfViewerProvider>();
              
              // Use ValueListenableBuilder for selected text to avoid provider rebuilds
              return ValueListenableBuilder<String>(
                valueListenable: _localSelectedTextNotifier,
                builder: (context, selectedText, child) {
                  // Only show bottom bar when speaking is active, not in full screen, and text is selected
                  if (!isSpeaking || isFullScreen || selectedText.isEmpty) {
                    return const SizedBox.shrink();
                  }
              
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appBarBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color:
                          FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Close Button
                    InkWell(
                      onTap: () {
                        _localSelectedTextNotifier.value = '';
                        p.clearSelectedText();
                        p.setSpeaking(false);
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .alternate
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: appBarTextColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Listen Button
                    Expanded(
                      child: InkWell(
                        onTap: isSpeaking 
                            ? () => _stopSpeaking(p) 
                            : () => _speakSelected(p),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSpeaking
                                ? Colors.redAccent
                                : FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSpeaking ? Icons.stop : Icons.volume_up,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isSpeaking ? "Stop" : "Listen",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Voice Settings Button
                    InkWell(
                      onTap: () => _openTtsSettings(p),
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .alternate
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_voice,
                          color: appBarTextColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              );
                },
              );
            },
          ),

          /// Chapter Read-Aloud Player Bar
          Selector<PdfViewerProvider, (bool, bool, bool)>(
            selector: (_, p) => (p.isFullScreen, p.isReadingChapter, p.isPaused),
            builder: (context, data, child) {
              final isFullScreen = data.$1;
              final isReadingChapter = data.$2;
              final isPaused = data.$3;
              final provider = context.read<PdfViewerProvider>();
              
              if (isFullScreen || !isReadingChapter) {
                return const SizedBox.shrink();
              }
              
              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: appBarBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: SpeechPlayerBar(
                  isPlaying: isReadingChapter && !isPaused,
                  backgroundColor: appBarBackgroundColor,
                  iconColor: appBarTextColor,
                  onPlayPause: () {
                    if (isReadingChapter) {
                      if (isPaused) {
                        _resumeReadingChapter(provider);
                      } else {
                        _pauseReadingChapter(provider);
                      }
                    } else {
                      _startReadingChapter(provider);
                    }
                  },
                  onPrevious: () {
                    provider.decrementReadingSentenceIndex();
                    if (provider.currentReadingSentenceIndex >= 0 &&
                        provider.currentReadingSentenceIndex < provider.chapterSentences.length) {
                      final sentence = provider.chapterSentences[provider.currentReadingSentenceIndex];
                      _highlightSentenceInContent(sentence);
                    }
                  },
                  onNext: () {
                    provider.incrementReadingSentenceIndex();
                    if (provider.currentReadingSentenceIndex >= 0 &&
                        provider.currentReadingSentenceIndex < provider.chapterSentences.length) {
                      final sentence = provider.chapterSentences[provider.currentReadingSentenceIndex];
                      _highlightSentenceInContent(sentence);
                    }
                  },
                  onStop: () => _stopReadingChapter(provider),
                  onSettings: () => _openTtsSettings(provider),
                  onShuffleToggle: () {
                    // Optional: Implement shuffle reading
                  },
                ),
              );
            },
          ),

          Selector<PdfViewerProvider, (bool, bool)>(
            selector: (_, p) => (p.isFullScreen, p.isReadingChapter),
            builder: (context, data, child) {
              final isFullScreen = data.$1;
              final isReadingChapter = data.$2;
              return ValueListenableBuilder<String>(
                valueListenable: _localSelectedTextNotifier,
                builder: (context, selectedText, child) {
                  if (isFullScreen || selectedText.isNotEmpty || isReadingChapter) {
                    return const SizedBox.shrink();
                  }
                  final provider = context.read<PdfViewerProvider>();
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appBarBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Page indicator and slider
                        Selector<PdfViewerProvider, (bool, bool)>(
                    selector: (_, p) => (p.showThemeSelectionWidget, p.showFontSelectionWidget),
                    builder: (context, data, child) {
                      final showThemeWidget = data.$1;
                      final showFontWidget = data.$2;
                      if (showThemeWidget || showFontWidget) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 16,left: 16, top: 12),
                        child: Column(
                          children: [
                            Selector<PdfViewerProvider, (int, int, bool)>(
                              selector: (_, p) => (
                                p.currentEpubChapterIndex,
                                p.epubChapters.length,
                                p.isChangingChapter,
                              ),
                              builder: (context, chapterData, child) {
                                final currentChapterIndex = chapterData.$1;
                                final totalChapters = chapterData.$2;
                                final isChangingChapter = chapterData.$3;
                                final provider = context.read<PdfViewerProvider>();
                                
                                return Row(
                                  mainAxisAlignment: provider.readerType == ReaderType.epub
                                      ? MainAxisAlignment.spaceBetween
                                      : MainAxisAlignment.center,
                                  children: [
                                    // Previous chapter button (only for EPUB) - always show, disabled when not at top
                                    if (provider.readerType == ReaderType.epub)
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isAtTopNotifier,
                                        builder: (context, isAtTop, child) {
                                          final isEnabled = isAtTop && currentChapterIndex > 0 && !isChangingChapter;
                                          return ElevatedButton.icon(
                                            onPressed: isEnabled
                                                ? () {
                                                    EpubReaderWidget.loadEpubChapter(
                                                      provider,
                                                      currentChapterIndex - 1,
                                                      _currentEpubContentNotifier,
                                                      _epubScrollController,
                                                      onOriginalContentReady: (originalHtml) {
                                                        _originalChapterHtml = originalHtml;
                                                      },
                                                    );
                                                  }
                                                : null,
                                            icon: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: isChangingChapter
                                                  ? const SizedBox(
                                                      key: ValueKey('loading-icon-prev'),
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.chevron_left,
                                                      size: 16,
                                                      key: ValueKey('icon-prev'),
                                                    ),
                                            ),
                                            label: const Text(
                                              'Previous',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 5,
                                              ),
                                              elevation: 0,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              backgroundColor: isEnabled
                                                  ? FlutterFlowTheme.of(context).black40
                                                  : FlutterFlowTheme.of(context).alternate,
                                              foregroundColor: isEnabled
                                                  ? Colors.white
                                                  : appBarTextColor.withOpacity(0.5),
                                            ),
                                          );
                                        },
                                      ),
                                    // Center text
                                    Expanded(
                                      child: Text(
                                        provider.readerType == ReaderType.epub
                                            ? 'অধ্যায় ${provider.currentPage}/${FFAppState().totalPages}'
                                            : 'পৃষ্ঠা ${provider.currentPage}/${FFAppState().totalPages}',
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: appBarTextColor,
                                            ),
                                      ),
                                    ),
                                    // Next chapter button (only for EPUB) - always show, disabled when not at bottom
                                    if (provider.readerType == ReaderType.epub)
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isAtBottomNotifier,
                                        builder: (context, isAtBottom, child) {
                                          final isEnabled = isAtBottom && currentChapterIndex < totalChapters - 1 && !isChangingChapter;
                                          return ElevatedButton.icon(
                                            onPressed: isEnabled
                                                ? () {
                                                    EpubReaderWidget.loadEpubChapter(
                                                      provider,
                                                      currentChapterIndex + 1,
                                                      _currentEpubContentNotifier,
                                                      _epubScrollController,
                                                      onOriginalContentReady: (originalHtml) {
                                                        _originalChapterHtml = originalHtml;
                                                      },
                                                    );
                                                  }
                                                : null,
                                            icon: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: isChangingChapter
                                                  ? const SizedBox(
                                                      key: ValueKey('loading-icon'),
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.chevron_right,
                                                      size: 16,
                                                      key: ValueKey('icon'),
                                                    ),
                                            ),
                                            label: const Text(
                                              'Next',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            iconAlignment: IconAlignment.end,
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 5,
                                              ),
                                              elevation: 0,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              backgroundColor: isEnabled
                                                  ? FlutterFlowTheme.of(context).black40
                                                  : FlutterFlowTheme.of(context).alternate,
                                              foregroundColor: isEnabled
                                                  ? Colors.white
                                                  : appBarTextColor.withOpacity(0.5),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // if (FFAppState().totalPages > 1)
                            //   SliderTheme(
                            //     data: SliderThemeData(
                            //       activeTrackColor: const Color(0xFFFFD700),
                            //       inactiveTrackColor:
                            //           FlutterFlowTheme.of(context).alternate,
                            //       thumbColor: const Color(0xFFFFD700),
                            //       overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
                            //       thumbShape: const RoundSliderThumbShape(
                            //           enabledThumbRadius: 8),
                            //       trackHeight: 4,
                            //     ),
                            //     child: Slider(
                            //       value: provider.currentPage.toDouble(),
                            //       min: 1,
                            //       max: FFAppState().totalPages.toDouble(),
                            //       onChanged: (value) {
                            //         provider.setCurrentPage(value.toInt());
                            //         if (provider.readerType == ReaderType.pdf) {
                            //           pdfViewerController.jumpToPage(provider.currentPage);
                            //         } else {
                            //           EpubReaderWidget.loadEpubChapter(
                            //             provider,
                            //             provider.currentPage - 1,
                            //             _currentEpubContentNotifier,
                            //             _epubScrollController,
                            //           );
                            //         }
                            //       },
                            //     ),
                            //   ),
                          ],
                        ),
                      );
                    },
                  ),
                        /// Theme Selection Widget (shown in bottom navigation section)
                        Selector<PdfViewerProvider, bool>(
                    selector: (_, p) => p.showThemeSelectionWidget,
                    builder: (context, showWidget, child) {
                      if (!showWidget) return const SizedBox.shrink();
                      
                      return Container(
                        // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ThemeBrightnessWidget(),
                      );
                    },
                  ),
                        /// Font Selection Widget (shown in bottom navigation section)
                        Selector<PdfViewerProvider, bool>(
                    selector: (_, p) => p.showFontSelectionWidget,
                    builder: (context, showWidget, child) {
                      if (!showWidget) return const SizedBox.shrink();
                      
                      return Container(
                        child: FontSelectionWidget(),
                      );
                    },
                  ),
                        /// Bottom action buttons
                        Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      top: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomIcon(
                          Icons.list,
                          'Table of Contents',
                          provider.readerType == ReaderType.epub
                              ? () {
                                  provider.setOpenDrawer('toc');
                                  // Open drawer immediately
                                  if (_scaffoldKey.currentState != null) {
                                    _scaffoldKey.currentState!.openDrawer();
                                  }
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('PDF Table of Contents not available'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          Icons.bookmark,
                          'Bookmarks',
                          () {
                            provider.setOpenDrawer('bookmarks');
                            // Open drawer immediately
                            if (_scaffoldKey.currentState != null) {
                              _scaffoldKey.currentState!.openDrawer();
                            }
                          },
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          provider.isFullScreen
                              ? Icons.fullscreen_exit_outlined
                              : Icons.fullscreen_outlined,
                          'Full Screen Mode',
                          () => PdfViewerHelpers.toggleFullScreen(provider, context),
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          provider.isAutoRotateEnabled
                              ? Icons.screen_rotation
                              : Icons.screen_lock_rotation,
                          'Screen rotation',
                          () => PdfViewerHelpers.toggleAutoRotate(provider),
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          Icons.brightness_6,
                          'Brightness',
                          () {
                            // Toggle theme selection widget overlay
                            provider.setShowThemeSelectionWidget(
                              !provider.showThemeSelectionWidget,
                            );
                            // Close font widget if open
                            if (provider.showFontSelectionWidget) {
                              provider.setShowFontSelectionWidget(false);
                            }
                          },
                          bottomNavIconColor,
                        ),
                        _buildBottomIcon(
                          Icons.text_fields,
                          'Font',
                          provider.readerType == ReaderType.epub
                              ? () {
                                  // Toggle font selection widget
                                  provider.setShowFontSelectionWidget(
                                    !provider.showFontSelectionWidget,
                                  );
                                  // Close theme widget if open
                                  if (provider.showThemeSelectionWidget) {
                                    provider.setShowThemeSelectionWidget(false);
                                  }
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Font settings only available for EPUB'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                          bottomNavIconColor,
                        ),
                      ],
                    ),
                  ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      );
        },
      ),
    );
      },
    );
  }

  Widget _buildBottomIcon(IconData icon, String tooltip, VoidCallback onTap, Color iconColor) {
    return PdfViewerHelpers.buildBottomIcon(icon, tooltip, onTap, iconColor);
  }
}
