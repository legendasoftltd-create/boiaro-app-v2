// Automatic FlutterFlow imports
import 'dart:async';
import 'dart:developer';

import 'package:a_i_ebook_app/custom_code/widgets/theme_selection_widget.dart';
import 'package:a_i_ebook_app/custom_code/widgets/font_selection_widget.dart';
import 'package:a_i_ebook_app/custom_code/widgets/bookmarks_highlights_drawer.dart';
import 'package:a_i_ebook_app/custom_code/widgets/table_of_contents_drawer.dart';
import 'package:a_i_ebook_app/custom_code/widgets/search_drawer.dart';
import 'package:a_i_ebook_app/custom_code/widgets/settings_drawer.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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
import 'bijoy_converter.dart';
import '/services/reading_report_service.dart';
import '/services/reading_progress_service.dart';
import '/services/progress_sync_service.dart';
import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';

class FlutterPdfViewWidget extends StatefulWidget {
  const FlutterPdfViewWidget({
    super.key,
    this.width,
    this.height,
    this.filePath,
    this.namePage,
    this.bookId,
  });

  final double? width;
  final double? height;
  final String? filePath;
  final String? namePage;
  final String? bookId;

  @override
  State<FlutterPdfViewWidget> createState() => _FlutterPdfViewWidgetState();
}

/// Lightweight widget that handles drawer opening without rebuilding body content
class _DrawerOpener extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _DrawerOpener({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Selector<PdfViewerProvider, String?>(
      selector: (_, p) => p.openDrawer,
      builder: (context, openDrawer, child) {
        // Open drawer when state changes (this widget is invisible and doesn't affect layout)
        if (openDrawer == 'search' || openDrawer == 'settings') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scaffoldKey.currentState != null) {
              scaffoldKey.currentState!.openEndDrawer();
            }
          });
        } else if (openDrawer == 'bookmarks' || openDrawer == 'toc') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scaffoldKey.currentState != null) {
              scaffoldKey.currentState!.openDrawer();
            }
          });
        }
        // Return empty widget - this doesn't render anything
        return const SizedBox.shrink();
      },
    );
  }
}

class _FlutterPdfViewWidgetState extends State<FlutterPdfViewWidget>
    with WidgetsBindingObserver {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PdfViewerController pdfViewerController = PdfViewerController();
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
  String? _resolvedFilePath;
  String? _originalChapterHtml; // Store original HTML before highlights
  bool _isLoading = true;
  Timer? _progressHeartbeatTimer;
  bool _hasEndedForBackground = false;
  ScaffoldMessengerState? _scaffoldMessenger;
  bool _initialProgressLoaded = false;

  // Auto-scroll timers
  Timer? _autoScrollTimer; // For interval-based auto-scroll
  Timer? _continuousScrollTimer; // For continuous auto-scroll

  // Button click debouncing to prevent rapid clicks from queuing operations
  DateTime? _lastButtonClick;
  static const _buttonDebounceMs = 300; // 300ms debounce

  /// Check if enough time has passed since last button click
  bool _canProcessClick() {
    final now = DateTime.now();
    if (_lastButtonClick != null &&
        now.difference(_lastButtonClick!).inMilliseconds < _buttonDebounceMs) {
      return false; // Too soon, ignore click
    }
    _lastButtonClick = now;
    return true;
  }

  void _onReadingDebug(String message) {
    if (!mounted || !kDebugMode) return;
    if (message.contains('PROGRESS SKIP')) return;
    final messenger = _scaffoldMessenger;
    if (messenger == null) return;
    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } catch (_) {
      // Ignore snackbar attempts while the widget tree is tearing down.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolvedFilePath = _resolveFilePath(widget.filePath);
    if (widget.filePath == null) {
      _isLoading = false;
    }
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    // Add scroll listener to detect top/bottom position
    _epubScrollController.addListener(_checkScrollPosition);

    // Listen to content changes to check scroll position after content loads
    _currentEpubContentNotifier.addListener(_onContentChanged);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapReader());
    });
  }

  Future<void> _bootstrapReader() async {
    if (!mounted) return;
    final provider = context.read<PdfViewerProvider>();
    await _loadInitialProgress(provider);
    if (!mounted) return;

    _currentBookId = PdfViewerTextOperations.generateBookId(_resolvedFilePath);
    provider.loadHighlights(_currentBookId!);
    provider.loadBookmarks(_currentBookId!);

    PdfViewerHelpers.determineReaderType(_resolvedFilePath, provider);
    if (provider.currentPage <= 0) {
      provider.setCurrentPage(1);
    }
    PdfViewerHelpers.getInitialBrightness(provider);
    ReadingReportService.instance.setDebugListener(_onReadingDebug);

    // Register book read/view — fire-and-forget, auth optional
    unawaited(_registerBookRead());

    unawaited(_startReadingSession());
    _startProgressHeartbeat();

    if (provider.readerType == ReaderType.epub) {
      EpubReaderWidget.loadEpubBook(
        _resolvedFilePath,
        provider,
        context,
        (index) => EpubReaderWidget.loadEpubChapter(
          provider,
          index,
          _currentEpubContentNotifier,
          _epubScrollController,
          onOriginalContentReady: (originalHtml) {
            _originalChapterHtml = originalHtml;
            if (provider.epubSearchText != null &&
                provider.epubSearchText!.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 200), () {
                _applyEpubSearchHighlights(provider);
              });
            }
          },
        ),
        initialChapterIndex: (provider.currentPage - 1).clamp(0, 1000000),
      );
    }
    ScreenProtector.protectDataLeakageOn();

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && provider.readerType == ReaderType.epub) {
        _startAutoScroll(provider);
      }
    });
  }

  Future<void> _loadInitialProgress(PdfViewerProvider provider) async {
    if (_initialProgressLoaded) {
      return;
    }
    _initialProgressLoaded = true;
    final bookId = (widget.bookId ?? FFAppState().homePageBookId).trim();
    if (bookId.isEmpty) {
      return;
    }
    final remote = await ProgressSyncService.fetchReadingProgress(bookId);
    if (!remote.hasProgress) {
      return;
    }
    final currentPage = remote.currentPage <= 0 ? 1 : remote.currentPage;
    provider.setCurrentPage(currentPage);
    FFAppState().homePageCurrentPdfIndex = currentPage;
    if (remote.totalPages > 0) {
      FFAppState().homePageTotalPdfPageIndex = remote.totalPages;
      FFAppState().totalPages = remote.totalPages;
    }
    FFAppState().update(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  String? _resolveFilePath(String? path) {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }
    if (trimmed.startsWith('file://')) {
      return Uri.parse(trimmed).toFilePath();
    }
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed)) {
      return trimmed;
    }
    if (trimmed.startsWith('/') && File(trimmed).existsSync()) {
      return trimmed;
    }
    return Uri.parse(FFAppConstants.webUrl).resolve(trimmed).toString();
  }

  List<PdfTocItem> _processBookmarks(
      PdfBookmarkBase bookmarks, PdfDocument document) {
    List<PdfTocItem> items = [];
    for (int i = 0; i < bookmarks.count; i++) {
      try {
        final bookmark = bookmarks[i];
        int pageNumber = -1;

        // Try standard destination
        if (bookmark.destination != null) {
          final page = bookmark.destination!.page;
          final index = document.pages.indexOf(page);
          if (index >= 0) {
            pageNumber = index + 1;
          }
        }
        // Try named destination if standard failed
        else if (bookmark.namedDestination != null) {
          final namedDest = bookmark.namedDestination!;
          if (namedDest.destination != null) {
            final page = namedDest.destination!.page;
            final index = document.pages.indexOf(page);
            if (index >= 0) {
              pageNumber = index + 1;
            }
          }
        }

        // Add item with recursive call
        items.add(PdfTocItem(
          title: bookmark.title,
          pageNumber: pageNumber > 0 ? pageNumber : 1, // Fallback to 1
          children: _processBookmarks(bookmark, document),
        ));
      } catch (e) {
        log("Error processing bookmark index $i: $e");
      }
    }
    return items;
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

  // Auto-scroll methods
  void _startAutoScroll(PdfViewerProvider provider) {
    _stopAutoScroll(); // Stop any existing timers

    final intervalSeconds = provider.autoScrollInterval;
    final speedPercent = provider.autoScrollSpeed;

    // If both are 0 or very small, don't start auto-scroll
    if (intervalSeconds <= 0 && speedPercent <= 0) {
      return;
    }

    // Interval-based auto-scroll (jumps at intervals)
    if (intervalSeconds > 0) {
      _autoScrollTimer = Timer.periodic(
        Duration(seconds: intervalSeconds.round()),
        (_) => _performAutoScroll(provider, isInterval: true),
      );
    }

    // Continuous auto-scroll (smooth scrolling)
    if (speedPercent > 0) {
      // Use fixed 20ms update rate (50fps) for smooth scrolling
      _continuousScrollTimer = Timer.periodic(
        const Duration(milliseconds: 20),
        (_) => _performAutoScroll(provider, isInterval: false),
      );
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _continuousScrollTimer?.cancel();
    _continuousScrollTimer = null;
  }

  void _performAutoScroll(PdfViewerProvider provider,
      {required bool isInterval}) {
    if (!mounted || !_epubScrollController.hasClients) return;

    try {
      final position = _epubScrollController.position;
      if (!position.hasContentDimensions || !position.hasPixels) return;

      final maxScroll = position.maxScrollExtent;
      final currentPixels = position.pixels;

      // If already at bottom, optionally go to next chapter or stop
      if (currentPixels >= maxScroll - 10) {
        // At bottom, try to go to next chapter
        if (provider.readerType == ReaderType.epub &&
            provider.currentEpubChapterIndex <
                provider.epubChapters.length - 1) {
          setCurrentPage(provider);
        }
        return;
      }
      if (isInterval) {
        // Interval-based: scroll by a fixed amount (e.g., one viewport height)
        final viewportHeight = position.viewportDimension;
        final targetScroll =
            (currentPixels + viewportHeight * 0.8).clamp(0.0, maxScroll);

        _epubScrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Continuous: scroll by small increments based on speed
        // Speed 100% -> ~5px per 20ms (~250px/s)
        final speedPercent = provider.autoScrollSpeed;
        final scrollDelta = (speedPercent / 20.0);

        final targetScroll =
            (currentPixels + scrollDelta).clamp(0.0, maxScroll);
        _epubScrollController.jumpTo(targetScroll);
      }
    } catch (e) {
      // Ignore scroll errors
    }
  }



  Future<void> _registerBookRead() async {
    final bookId = (widget.bookId ?? FFAppState().homePageBookId).trim();
    if (bookId.isEmpty) return;
    try {
      await EbookGroup.registerBookReadApiCall.call(
        bookId: bookId,
        token: FFAppState().token.isNotEmpty ? FFAppState().token : null,
      );
      debugPrint('BOOK READ REGISTERED: bookId=$bookId');
    } catch (e) {
      debugPrint('BOOK READ REGISTER ERROR: $e');
    }
  }

  Future<void> _startReadingSession() async {
    final bookId = (widget.bookId ?? FFAppState().homePageBookId).trim();
    if (bookId.isEmpty) return;
    await ReadingReportService.instance.startSession(bookId: bookId);
    _hasEndedForBackground = false;
  }

  void _startProgressHeartbeat() {
    _stopProgressHeartbeat();
    _progressHeartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      final provider = context.read<PdfViewerProvider>();
      unawaited(_reportProgress(provider, force: true, fromHeartbeat: true));
    });
  }

  void _stopProgressHeartbeat() {
    _progressHeartbeatTimer?.cancel();
    _progressHeartbeatTimer = null;
  }

  Future<void> _reportProgress(
    PdfViewerProvider provider, {
    bool force = false,
    bool fromHeartbeat = false,
  }) async {
    if (fromHeartbeat && !ReadingReportService.instance.hasActiveSession) {
      await _startReadingSession();
    }
    final percent = _calculateProgressPercent(provider);
    final bookId = (widget.bookId ?? FFAppState().homePageBookId).trim();
    if (bookId.isNotEmpty) {
      final name = (widget.namePage ?? FFAppState().homePageBookName).trim();
      final imageUrl = FFAppState().homePageLiveReadBook.trim();
      final totalPages = provider.readerType == ReaderType.pdf
          ? (FFAppState().totalPages <= 0 ? 1 : FFAppState().totalPages)
          : (provider.epubChapters.isEmpty ? 1 : provider.epubChapters.length);
      final currentPage = provider.readerType == ReaderType.pdf
          ? provider.currentPage.clamp(1, totalPages)
          : (provider.currentEpubChapterIndex + 1).clamp(1, totalPages);
      unawaited(ReadingProgressService.upsertProgress(
        bookId: bookId,
        percent: percent.toDouble(),
        name: name,
        imageUrl: imageUrl,
        contentType: provider.readerType == ReaderType.epub ? 'ebook' : 'ebook',
      ));
      unawaited(ProgressSyncService.saveReadingProgress(
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
      ));
    }
    await ReadingReportService.instance.updateProgress(
      percentage: percent,
      force: force,
    );
  }

  int _calculateProgressPercent(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.pdf) {
      final total = FFAppState().totalPages <= 0 ? 1 : FFAppState().totalPages;
      final current = provider.currentPage.clamp(1, total);
      return ((current / total) * 100).round().clamp(0, 100);
    }

    final total =
        provider.epubChapters.isEmpty ? 1 : provider.epubChapters.length;
    final current = (provider.currentEpubChapterIndex + 1).clamp(1, total);
    return ((current / total) * 100).round().clamp(0, 100);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      if (_hasEndedForBackground) {
        unawaited(_startReadingSession());
        _startProgressHeartbeat();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final provider = context.read<PdfViewerProvider>();
      unawaited(_reportProgress(provider, force: true));
      unawaited(ReadingReportService.instance.endSession());
      _stopProgressHeartbeat();
      _hasEndedForBackground = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopProgressHeartbeat();
    ReadingReportService.instance.setDebugListener(null);
    final provider = context.read<PdfViewerProvider>();
    unawaited(_reportProgress(provider, force: true));
    unawaited(ReadingReportService.instance.endSession());
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
    _stopAutoScroll(); // Cancel auto-scroll timers
    flutterTts.stop();
    ScreenProtector.protectDataLeakageOff();
    super.dispose();
  }

  void setCurrentPage(PdfViewerProvider provider) {
    // Debounce rapid clicks to prevent queuing multiple operations
    if (!_canProcessClick()) return;

    if (provider.readerType == ReaderType.epub) {
      if (provider.currentEpubChapterIndex < provider.epubChapters.length - 1) {
        EpubReaderWidget.loadEpubChapter(
          provider,
          provider.currentEpubChapterIndex + 1,
          _currentEpubContentNotifier,
          _epubScrollController,
          onOriginalContentReady: (originalHtml) {
            _originalChapterHtml = originalHtml;
            // Restart auto-scroll after chapter loads
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _startAutoScroll(provider);
            });
          },
        );
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          unawaited(_reportProgress(provider, force: true));
        });
      }
    } else {
      if (provider.currentPage != FFAppState().totalPages) {
        provider.incrementPage();
        pdfViewerController.jumpToPage(provider.currentPage);
        unawaited(_reportProgress(provider, force: true));
      }
    }
  }

  void setCurrentMinusPage(PdfViewerProvider provider) {
    // Debounce rapid clicks to prevent queuing multiple operations
    if (!_canProcessClick()) return;

    if (provider.readerType == ReaderType.epub) {
      if (provider.currentEpubChapterIndex > 0) {
        EpubReaderWidget.loadEpubChapter(
          provider,
          provider.currentEpubChapterIndex - 1,
          _currentEpubContentNotifier,
          _epubScrollController,
          onOriginalContentReady: (originalHtml) {
            _originalChapterHtml = originalHtml;
            // Restart auto-scroll after chapter loads
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _startAutoScroll(provider);
            });
          },
        );
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          unawaited(_reportProgress(provider, force: true));
        });
      }
    } else {
      if (provider.currentPage > 1) {
        provider.decrementPage();
        pdfViewerController.jumpToPage(provider.currentPage);
        unawaited(_reportProgress(provider, force: true));
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
    String originalHtml =
        _originalChapterHtml ?? _currentEpubContentNotifier.value;

    // Remove any existing mark tags from original HTML to get clean content
    if (originalHtml.contains('<mark')) {
      originalHtml = originalHtml
          .replaceAll(RegExp(r'<mark[^>]*>'), '')
          .replaceAll('</mark>', '');
    }

    final chapterId = provider.currentEpubChapterIndex.toString();
    final chapterName = provider.epubChapters.isNotEmpty &&
            provider.currentEpubChapterIndex < provider.epubChapters.length
        ? provider.epubChapters[provider.currentEpubChapterIndex].Title ??
            'Chapter ${provider.currentEpubChapterIndex + 1}'
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
        chapterName =
            provider.epubChapters[provider.currentEpubChapterIndex].Title ??
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
        RegExp(r'<mark class="reading-sentence"[^>]*>(.*?)</mark>',
            dotAll: true),
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

  void _scrollToHighlightedSentence(
      int sentenceCharIndex, int totalContentLength) {
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
              final contentBeforeSentence = currentContent.substring(
                  0, sentenceCharIndex.clamp(0, currentContent.length));
              final visibleTextBefore =
                  _extractVisibleText(contentBeforeSentence);
              final totalVisibleText = _extractVisibleText(currentContent);

              if (totalVisibleText.isNotEmpty) {
                final visibleTextRatio =
                    visibleTextBefore.length / totalVisibleText.length;
                // Blend both methods: 70% sentence index, 30% visible text position
                contentRatio = (contentRatio * 0.7) + (visibleTextRatio * 0.3);
              }
            }
          } else if (totalContentLength > 0) {
            // Fallback: Use visible text position if sentence index not available
            final contentBeforeSentence = currentContent.substring(
                0, sentenceCharIndex.clamp(0, currentContent.length));
            final visibleTextBefore =
                _extractVisibleText(contentBeforeSentence);
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
          targetScrollPosition =
              (targetScrollPosition - viewportOffset).clamp(0.0, maxScroll);

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
              final targetScroll =
                  (contentRatio * maxScroll).clamp(0.0, maxScroll);

              _epubScrollController.animateTo(
                targetScroll,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            } else if (maxScroll > 0 && totalContentLength > 0) {
              // Last fallback: character position
              final contentRatio = sentenceCharIndex / totalContentLength;
              final targetScroll =
                  (contentRatio * maxScroll).clamp(0.0, maxScroll);

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

  Future<void> _searchEpub(PdfViewerProvider provider) async {
    final searchText = provider.searchText.trim();
    if (searchText.isEmpty) {
      _clearEpubSearch(provider);
      return;
    }

    // Set loading state
    provider.setSearching(true);

    // Try converting Bijoy to Unicode first if applicable
    String effectiveSearchText = searchText;
    String convertedText = BijoyConverter.convert(searchText);
    if (convertedText != searchText) {
      log('Converted "$searchText" to "$convertedText"');
      effectiveSearchText = convertedText;
    }

    try {
      // Search across all chapters
      final results =
          await PdfViewerEpubSearch.searchInEpub(provider, effectiveSearchText);

      if (results.isNotEmpty) {
        provider.setEpubSearchResults(
          results.length,
          PdfViewerEpubSearch.getCurrentResultIndex(),
          effectiveSearchText,
        );

        // Apply highlights to current chapter if it's already loaded
        // This ensures search terms are visible even if we don't navigate
        final currentIndex = PdfViewerEpubSearch.getCurrentResultIndex();
        _applyEpubSearchHighlights(provider, currentResultIndex: currentIndex);

        // Navigate to first result
        final firstResult = results[0];
        _navigateToEpubSearchResult(provider, firstResult);
      } else {
        provider.setEpubSearchResults(0, -1, searchText);
        // Clear highlights if no results found
        _clearEpubSearchHighlights(provider);
      }
    } finally {
      // Loading state will be cleared in setEpubSearchResults
    }
  }

  void _navigateToEpubSearchResult(
      PdfViewerProvider provider, EpubSearchResult result) {
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
          // Apply search highlights after chapter loads with current result index
          final currentIndex = PdfViewerEpubSearch.getCurrentResultIndex();
          _applyEpubSearchHighlights(provider,
              currentResultIndex: currentIndex);
          // Scroll to the search result position
          _scrollToSearchResult(result);
          // Clear navigating state after a delay to allow UI to update
          Future.delayed(const Duration(milliseconds: 300), () {
            provider.setNavigatingSearchResult(false);
          });
        },
      );
    } else {
      // Chapter already loaded, just apply highlights with current result index and scroll to result
      final currentIndex = PdfViewerEpubSearch.getCurrentResultIndex();
      _applyEpubSearchHighlights(provider, currentResultIndex: currentIndex);
      _scrollToSearchResult(result);
      // Clear navigating state after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        provider.setNavigatingSearchResult(false);
      });
    }
  }

  void _scrollToSearchResult(EpubSearchResult result) {
    if (!_epubScrollController.hasClients || !mounted) return;

    // Wait for layout to complete after content update
    // Use multiple post-frame callbacks to ensure layout is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_epubScrollController.hasClients || !mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!_epubScrollController.hasClients || !mounted) return;

            try {
              final scrollPosition = _epubScrollController.position;
              final maxScroll = scrollPosition.maxScrollExtent;
              final viewportHeight = scrollPosition.viewportDimension;

              if (maxScroll <= 0) return;

              final currentContent = _currentEpubContentNotifier.value;
              if (currentContent.isEmpty) return;

              // Method 1: Try to find the current-search-result element position
              // Calculate position based on plain text ratio (more accurate)
              final plainTextContent =
                  _extractPlainTextForScroll(currentContent);
              final plainTextLength = plainTextContent.length;

              if (plainTextLength > 0) {
                // Find the position of current search result in plain text
                final searchText =
                    context.read<PdfViewerProvider>().epubSearchText ?? '';
                if (searchText.isNotEmpty) {
                  // Find all occurrences and get the one matching our result
                  final searchLower = searchText.toLowerCase();
                  final plainTextLower = plainTextContent.toLowerCase();

                  int occurrenceCount = 0;
                  int targetPosition = -1;
                  int searchIndex = 0;

                  while (searchIndex < plainTextLower.length) {
                    final index =
                        plainTextLower.indexOf(searchLower, searchIndex);
                    if (index == -1) break;

                    if (occurrenceCount == result.matchIndex) {
                      targetPosition = index;
                      break;
                    }

                    occurrenceCount++;
                    searchIndex = index + 1;
                  }

                  if (targetPosition >= 0) {
                    // Calculate scroll position based on plain text ratio
                    final contentRatio = targetPosition / plainTextLength;
                    double targetScrollPosition = contentRatio * maxScroll;

                    // Adjust to position text in upper-middle of viewport (20% from top)
                    final viewportOffset = viewportHeight * 0.2;
                    targetScrollPosition =
                        (targetScrollPosition - viewportOffset)
                            .clamp(0.0, maxScroll);

                    // Get current scroll position
                    final currentScroll = scrollPosition.pixels;
                    final scrollDifference =
                        (targetScrollPosition - currentScroll).abs();

                    if (scrollDifference > 50) {
                      _epubScrollController.animateTo(
                        targetScrollPosition,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                      return;
                    }
                  }
                }
              }

              // Method 2: Fallback to HTML position ratio (less accurate but works)
              final contentLength = currentContent.length;
              if (contentLength > 0 && result.position < contentLength) {
                // Count plain text characters up to result.position
                final plainTextPos = _countPlainTextUpToPosition(
                    currentContent, result.position);
                final plainTextTotal =
                    _extractPlainTextForScroll(currentContent).length;

                if (plainTextTotal > 0) {
                  final contentRatio = plainTextPos / plainTextTotal;
                  double targetScrollPosition = contentRatio * maxScroll;

                  // Adjust for viewport
                  final viewportOffset = viewportHeight * 0.2;
                  targetScrollPosition = (targetScrollPosition - viewportOffset)
                      .clamp(0.0, maxScroll);

                  _epubScrollController.animateTo(
                    targetScrollPosition,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              }
            } catch (e) {
              // Fallback: simple ratio-based scroll
              try {
                if (!_epubScrollController.hasClients || !mounted) return;
                final currentContent = _currentEpubContentNotifier.value;
                final maxScroll =
                    _epubScrollController.position.maxScrollExtent;

                if (maxScroll > 0 && currentContent.isNotEmpty) {
                  final plainTextTotal =
                      _extractPlainTextForScroll(currentContent).length;
                  if (plainTextTotal > 0) {
                    final plainTextPos = _countPlainTextUpToPosition(
                        currentContent, result.position);
                    final contentRatio = plainTextPos / plainTextTotal;
                    final targetScroll =
                        (contentRatio * maxScroll).clamp(0.0, maxScroll);

                    _epubScrollController.animateTo(
                      targetScroll,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              } catch (_) {
                // Ignore scroll errors
              }
            }
          });
        });
      });
    });
  }

  /// Extract plain text from HTML for accurate position calculation
  String _extractPlainTextForScroll(String html) {
    // Remove HTML tags and decode entities
    String text = html.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    return text;
  }

  /// Count plain text characters up to a given HTML position
  int _countPlainTextUpToPosition(String html, int htmlPosition) {
    int count = 0;
    bool insideTag = false;

    for (int i = 0; i < htmlPosition && i < html.length; i++) {
      if (html[i] == '<') {
        insideTag = true;
      } else if (html[i] == '>') {
        insideTag = false;
      } else if (!insideTag && html[i] != '\n' && html[i] != '\r') {
        count++;
      }
    }

    return count;
  }

  void _applyEpubSearchHighlights(PdfViewerProvider provider,
      {int? currentResultIndex}) {
    if (provider.epubSearchText == null || provider.epubSearchText!.isEmpty) {
      return;
    }

    final currentContent = _currentEpubContentNotifier.value;
    // Clear previous search highlights
    final cleanContent =
        PdfViewerEpubSearch.clearSearchHighlights(currentContent);
    // Apply new search highlights with current result index
    final (highlightedContent, _) = PdfViewerEpubSearch.highlightSearchResults(
      cleanContent,
      provider.epubSearchText!,
      currentResultIndex: currentResultIndex,
    );

    provider.setCurrentEpubContent(highlightedContent);
    _currentEpubContentNotifier.value = highlightedContent;
  }

  void _clearEpubSearch(PdfViewerProvider provider) {
    PdfViewerEpubSearch.clearResults();
    provider.clearEpubSearch();
    _clearEpubSearchHighlights(provider);
  }

  void _clearEpubSearchHighlights(PdfViewerProvider provider) {
    // Remove search highlights from current content
    final currentContent = _currentEpubContentNotifier.value;
    if (currentContent.isNotEmpty) {
      final cleanContent =
          PdfViewerEpubSearch.clearSearchHighlights(currentContent);
      provider.setCurrentEpubContent(cleanContent);
      _currentEpubContentNotifier.value = cleanContent;
    }
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

      // Capture page number after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final currentPage = pdfViewerController.pageNumber;
          final currentIndex = provider.searchResult.currentInstanceIndex;
          provider.updateSearchResultDetail(currentIndex, currentPage, null);
          provider.setNavigatingSearchResult(false);
        }
      });
    } else {
      _goToNextEpubSearchResult(provider);
    }
  }

  void _goToPreviousSearchResult(PdfViewerProvider provider) {
    if (provider.readerType == ReaderType.pdf) {
      provider.setNavigatingSearchResult(true);
      PdfViewerPdfOperations.goToPreviousSearchResult(provider);

      // Capture page number after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final currentPage = pdfViewerController.pageNumber;
          final currentIndex = provider.searchResult.currentInstanceIndex;
          provider.updateSearchResultDetail(currentIndex, currentPage, null);
          provider.setNavigatingSearchResult(false);
        }
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
    return Selector<PdfViewerProvider, (ReaderType, AppThemeMode, bool, bool)>(
      selector: (_, p) => (
        p.readerType,
        p.currentThemeMode,
        p.isFullScreen,
        p.isPdfVerticalScroll
      ),
      builder: (context, data, child) {
        final readerType = data.$1;
        final themeMode = data.$2;
        final isFullScreen = data.$3;
        final isPdfVerticalScroll = data.$4;
        final provider = context.read<PdfViewerProvider>();

        log("_currentEpubContent: ${provider.currentEpubContent}");
        Color scaffoldBackgroundColor;
        Color appBarBackgroundColor;
        Color appBarTextColor;
        Color bottomNavIconColor;

        // Apply theme colors for all reader types
        switch (themeMode) {
          case AppThemeMode.light:
            scaffoldBackgroundColor = Colors.white;
            appBarBackgroundColor = Colors.white;
            appBarTextColor = Colors.black;
            bottomNavIconColor = const Color(0xFF57636C); // Secondary Text
            break;
          case AppThemeMode.dark:
            scaffoldBackgroundColor = Colors.black;
            appBarBackgroundColor = Colors.black; // Match scaffold
            appBarTextColor = Colors.white;
            bottomNavIconColor = Colors.white;
            break;
          case AppThemeMode.sepia:
            scaffoldBackgroundColor = const Color(0xFFF5DEB3); // Sepia color
            appBarBackgroundColor = const Color(0xFFF5DEB3); // Match scaffold
            appBarTextColor = Colors.black;
            bottomNavIconColor = const Color(0xFF57636C);
            break;
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
            if (!isOpened &&
                (provider.openDrawer == 'bookmarks' ||
                    provider.openDrawer == 'toc')) {
              // Clear the drawer state when drawer is dismissed
              provider.setOpenDrawer(null);
            }
          },
          onEndDrawerChanged: (isOpened) {
            if (!isOpened &&
                (provider.openDrawer == 'search' ||
                    provider.openDrawer == 'search_pdf' ||
                    provider.openDrawer == 'search_epub' ||
                    provider.openDrawer == 'settings')) {
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
              }
              return const SizedBox.shrink();
            },
          ),
          endDrawer: Selector<PdfViewerProvider, String?>(
            selector: (_, p) => p.openDrawer,
            builder: (context, openDrawer, child) {
              if (openDrawer == 'search' || openDrawer == 'search_epub') {
                return SearchDrawer(
                  searchController: _searchController,
                  pdfController: pdfViewerController,
                  onSearchEpub: () => _searchEpub(provider),
                  onNextResult: () => _goToNextSearchResult(provider),
                  onPreviousResult: () => _goToPreviousSearchResult(provider),
                  onClearSearch: () => _clearSearch(provider),
                );
              } else if (openDrawer == 'search_pdf') {
                return SearchDrawer(
                  searchController: _searchController,
                  pdfController: pdfViewerController,
                  onSearchEpub: null,
                  onNextResult: () => _goToNextSearchResult(provider),
                  onPreviousResult: () => _goToPreviousSearchResult(provider),
                  onClearSearch: () => _clearSearch(provider),
                );
              } else if (openDrawer == 'settings') {
                return SettingsDrawer(
                  onAutoScrollSettingsChanged: () {
                    // Restart auto-scroll with new settings
                    _startAutoScroll(provider);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          body: Stack(
            children: [
              // Main content - no longer wrapped in Selector for openDrawer
              Column(
                children: [
                  /// ---------- Content Viewer ----------
                  Expanded(
                    child: Stack(
                      children: [
                        // PDF Viewer with ColorFilter
                        if (readerType == ReaderType.pdf)
                          Selector<PdfViewerProvider, AppThemeMode>(
                            selector: (_, p) => p.currentThemeMode,
                            builder: (context, themeMode, child) {
                              // Wrap in ClipRect to isolate ColorFilter effects
                              Widget pdfContent = ClipRect(
                                child: child!,
                              );

                              // Apply ColorFilter based on theme
                              if (themeMode == AppThemeMode.dark) {
                                pdfContent = ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.difference,
                                  ),
                                  child: pdfContent,
                                );
                              } else if (themeMode == AppThemeMode.sepia) {
                                pdfContent = ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFF5DEB3),
                                    BlendMode.multiply,
                                  ),
                                  child: pdfContent,
                                );
                              }

                              return pdfContent;
                            },
                            child: Container(
                              padding: EdgeInsets.only(top: 50),
                              color: Colors.white,
                              child: (_resolvedFilePath != null &&
                                      (_resolvedFilePath!.startsWith('http') ||
                                          _resolvedFilePath!
                                              .startsWith('https')))
                                  ? SfPdfViewer.network(
                                      _resolvedFilePath!,
                                      key: _pdfViewerKey,
                                      controller: pdfViewerController,
                                      scrollDirection: isPdfVerticalScroll
                                          ? PdfScrollDirection.vertical
                                          : PdfScrollDirection.horizontal,
                                      pageLayoutMode: isPdfVerticalScroll
                                          ? PdfPageLayoutMode.continuous
                                          : PdfPageLayoutMode.single,
                                      canShowTextSelectionMenu: true,
                                      onDocumentLoaded:
                                          (PdfDocumentLoadedDetails details) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        int totalPages =
                                            details.document.pages.count;
                                        FFAppState().totalPages = totalPages;
                                        FFAppState().update(() {
                                          FFAppState()
                                                  .homePageTotalPdfPageIndex =
                                              FFAppState().totalPages;
                                        });

                                        // Extract TOC
                                        if (details.document.bookmarks.count >
                                            0) {
                                          final toc = _processBookmarks(
                                              details.document.bookmarks,
                                              details.document);
                                          provider.setPdfToc(toc);
                                        } else {
                                          provider.setPdfToc([]);
                                        }

                                        pdfViewerController
                                            .jumpToPage(provider.currentPage);
                                      },
                                      onDocumentLoadFailed:
                                          (PdfDocumentLoadFailedDetails
                                              details) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        log("PDF Load Failed: ${details.error}");
                                      },
                                      onPageChanged: (details) {
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((_) {
                                          provider.setCurrentPage(
                                              details.newPageNumber);
                                          FFAppState().update(() {
                                            FFAppState()
                                                    .homePageCurrentPdfIndex =
                                                provider.currentPage;
                                          });
                                          unawaited(_reportProgress(
                                            provider,
                                            force: true,
                                          ));
                                        });
                                      },
                                      onTextSelectionChanged:
                                          (PdfTextSelectionChangedDetails
                                              details) {
                                        if (details.selectedText != null &&
                                            details.selectedText!.isNotEmpty) {
                                          provider.setSelectedText(
                                              details.selectedText!);
                                        } else {
                                          provider.clearSelectedText();
                                        }
                                      },
                                    )
                                  : SfPdfViewer.file(
                                      File(_resolvedFilePath ?? ''),
                                      key: _pdfViewerKey,
                                      controller: pdfViewerController,
                                      scrollDirection: isPdfVerticalScroll
                                          ? PdfScrollDirection.vertical
                                          : PdfScrollDirection.horizontal,
                                      pageLayoutMode: isPdfVerticalScroll
                                          ? PdfPageLayoutMode.continuous
                                          : PdfPageLayoutMode.single,
                                      canShowTextSelectionMenu: true,
                                      onDocumentLoaded:
                                          (PdfDocumentLoadedDetails details) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        int totalPages =
                                            details.document.pages.count;
                                        FFAppState().totalPages = totalPages;
                                        FFAppState().update(() {
                                          FFAppState()
                                                  .homePageTotalPdfPageIndex =
                                              FFAppState().totalPages;
                                        });

                                        // Extract TOC
                                        if (details.document.bookmarks.count >
                                            0) {
                                          final toc = _processBookmarks(
                                              details.document.bookmarks,
                                              details.document);
                                          provider.setPdfToc(toc);
                                        } else {
                                          provider.setPdfToc([]);
                                        }

                                        pdfViewerController
                                            .jumpToPage(provider.currentPage);
                                      },
                                      onDocumentLoadFailed:
                                          (PdfDocumentLoadFailedDetails
                                              details) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        log("PDF Load Failed: ${details.error}");
                                      },
                                      onPageChanged: (details) {
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((_) {
                                          provider.setCurrentPage(
                                              details.newPageNumber);
                                          FFAppState().update(() {
                                            FFAppState()
                                                    .homePageCurrentPdfIndex =
                                                provider.currentPage;
                                          });
                                          unawaited(_reportProgress(
                                            provider,
                                            force: true,
                                          ));
                                        });
                                      },
                                      onTextSelectionChanged:
                                          (PdfTextSelectionChangedDetails
                                              details) {
                                        if (details.selectedText != null &&
                                            details.selectedText!.isNotEmpty) {
                                          provider.setSelectedText(
                                              details.selectedText!);
                                        } else {
                                          provider.clearSelectedText();
                                        }
                                      },
                                    ),
                            ),
                          )
                        else
                          _buildEpubReader(),

                        /// Loading Indicator
                        if (readerType == ReaderType.pdf && _isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: FlutterFlowTheme.of(context).primaryColor,
                            ),
                          ),

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

                        /// App Bar - Positioned on top of PDF viewer
                        if (!isFullScreen)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
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
                                    color: appBarTextColor.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
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
                                      InkWell(
                                        onTap: () {
                                          if (readerType == ReaderType.pdf) {
                                            provider
                                                .setOpenDrawer('search_pdf');
                                          } else {
                                            provider
                                                .setOpenDrawer('search_epub');
                                          }
                                          _scaffoldKey.currentState
                                              ?.openEndDrawer();
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
                                          selector: (_, p) =>
                                              p.isReadingChapter,
                                          builder: (context, isReadingChapter,
                                              child) {
                                            final p = context
                                                .read<PdfViewerProvider>();
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
                                                    : Icons
                                                        .spatial_audio_off_rounded,
                                                size: 24,
                                                color: isReadingChapter
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primary
                                                    : appBarTextColor,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      if (provider.readerType == ReaderType.pdf)
                                        const SizedBox(width: 16),
                                      Selector<PdfViewerProvider,
                                          (List<int>, int)>(
                                        selector: (_, p) =>
                                            (p.bookmarkedPages, p.currentPage),
                                        builder: (context, data, child) {
                                          final bookmarkedPages = data.$1;
                                          final currentPage = data.$2;
                                          final p =
                                              context.read<PdfViewerProvider>();
                                          return InkWell(
                                            onTap: () => _toggleBookmark(p),
                                            child: Icon(
                                              bookmarkedPages
                                                      .contains(currentPage)
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              size: 24,
                                              color: appBarTextColor,
                                            ),
                                          );
                                        },
                                      ),
                                      if (provider.readerType ==
                                          ReaderType.epub)
                                        InkWell(
                                          onTap: () {
                                            provider.setOpenDrawer('settings');
                                            _scaffoldKey.currentState
                                                ?.openEndDrawer();
                                          },
                                          child: Icon(
                                            Icons.more_vert,
                                            size: 24,
                                            color: appBarTextColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
                          if (!isSpeaking ||
                              isFullScreen ||
                              selectedText.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: appBarBackgroundColor,
                              border: Border(
                                top: BorderSide(
                                  color: FlutterFlowTheme.of(context)
                                      .alternate
                                      .withOpacity(0.2),
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
                                            : FlutterFlowTheme.of(context)
                                                .primary,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isSpeaking
                                                ? Icons.stop
                                                : Icons.volume_up,
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
                    selector: (_, p) =>
                        (p.isFullScreen, p.isReadingChapter, p.isPaused),
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
                              color: FlutterFlowTheme.of(context)
                                  .alternate
                                  .withOpacity(0.2),
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
                                provider.currentReadingSentenceIndex <
                                    provider.chapterSentences.length) {
                              final sentence = provider.chapterSentences[
                                  provider.currentReadingSentenceIndex];
                              _highlightSentenceInContent(sentence);
                            }
                          },
                          onNext: () {
                            provider.incrementReadingSentenceIndex();
                            if (provider.currentReadingSentenceIndex >= 0 &&
                                provider.currentReadingSentenceIndex <
                                    provider.chapterSentences.length) {
                              final sentence = provider.chapterSentences[
                                  provider.currentReadingSentenceIndex];
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
                          if (isFullScreen ||
                              selectedText.isNotEmpty ||
                              isReadingChapter) {
                            return const SizedBox.shrink();
                          }
                          final provider = context.read<PdfViewerProvider>();
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: appBarBackgroundColor,
                              border: Border(
                                top: BorderSide(
                                  color: FlutterFlowTheme.of(context)
                                      .alternate
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// Page indicator and slider
                                Selector<PdfViewerProvider, (bool, bool)>(
                                  selector: (_, p) => (
                                    p.showThemeSelectionWidget,
                                    p.showFontSelectionWidget
                                  ),
                                  builder: (context, data, child) {
                                    final showThemeWidget = data.$1;
                                    final showFontWidget = data.$2;
                                    if (showThemeWidget || showFontWidget)
                                      return const SizedBox.shrink();

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 16, left: 16, top: 12),
                                      child: Column(
                                        children: [
                                          Selector<PdfViewerProvider,
                                              (int, int, bool)>(
                                            selector: (_, p) => (
                                              p.currentEpubChapterIndex,
                                              p.epubChapters.length,
                                              p.isChangingChapter,
                                            ),
                                            builder:
                                                (context, chapterData, child) {
                                              final currentChapterIndex =
                                                  chapterData.$1;
                                              final totalChapters =
                                                  chapterData.$2;
                                              final isChangingChapter =
                                                  chapterData.$3;
                                              final provider = context
                                                  .read<PdfViewerProvider>();

                                              return Row(
                                                mainAxisAlignment: provider
                                                            .readerType ==
                                                        ReaderType.epub
                                                    ? MainAxisAlignment
                                                        .spaceBetween
                                                    : MainAxisAlignment.center,
                                                children: [
                                                  // Previous chapter button (only for EPUB) - always show, disabled when not at top
                                                  if (provider.readerType ==
                                                      ReaderType.epub)
                                                    ValueListenableBuilder<
                                                        bool>(
                                                      valueListenable:
                                                          _isAtTopNotifier,
                                                      builder: (context,
                                                          isAtTop, child) {
                                                        final isEnabled = isAtTop &&
                                                            currentChapterIndex >
                                                                0 &&
                                                            !isChangingChapter;
                                                        return ElevatedButton
                                                            .icon(
                                                          onPressed: isEnabled
                                                              ? () {
                                                                  EpubReaderWidget
                                                                      .loadEpubChapter(
                                                                    provider,
                                                                    currentChapterIndex -
                                                                        1,
                                                                    _currentEpubContentNotifier,
                                                                    _epubScrollController,
                                                                    onOriginalContentReady:
                                                                        (originalHtml) {
                                                                      _originalChapterHtml =
                                                                          originalHtml;
                                                                    },
                                                                  );
                                                                }
                                                              : null,
                                                          icon:
                                                              AnimatedSwitcher(
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        200),
                                                            child: isChangingChapter
                                                                ? const SizedBox(
                                                                    key: ValueKey(
                                                                        'loading-icon-prev'),
                                                                    width: 16,
                                                                    height: 16,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                                  )
                                                                : const Icon(
                                                                    Icons
                                                                        .chevron_left,
                                                                    size: 16,
                                                                    key: ValueKey(
                                                                        'icon-prev'),
                                                                  ),
                                                          ),
                                                          label: const Text(
                                                            'Previous',
                                                            style: TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 20,
                                                              vertical: 5,
                                                            ),
                                                            elevation: 0,
                                                            minimumSize:
                                                                Size.zero,
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            backgroundColor: isEnabled
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .black40
                                                                : FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                            foregroundColor: isEnabled
                                                                ? Colors.white
                                                                : appBarTextColor
                                                                    .withOpacity(
                                                                        0.5),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  // Center text
                                                  Expanded(
                                                    child: Text(
                                                      provider.readerType ==
                                                              ReaderType.epub
                                                          ? 'অধ্যায় ${provider.currentPage}/${FFAppState().totalPages}'
                                                          : 'পৃষ্ঠা ${provider.currentPage}/${FFAppState().totalPages}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                appBarTextColor,
                                                          ),
                                                    ),
                                                  ),
                                                  // Next chapter button (only for EPUB) - always show, disabled when not at bottom
                                                  if (provider.readerType ==
                                                      ReaderType.epub)
                                                    ValueListenableBuilder<
                                                        bool>(
                                                      valueListenable:
                                                          _isAtBottomNotifier,
                                                      builder: (context,
                                                          isAtBottom, child) {
                                                        final isEnabled = isAtBottom &&
                                                            currentChapterIndex <
                                                                totalChapters -
                                                                    1 &&
                                                            !isChangingChapter;
                                                        return ElevatedButton
                                                            .icon(
                                                          onPressed: isEnabled
                                                              ? () {
                                                                  EpubReaderWidget
                                                                      .loadEpubChapter(
                                                                    provider,
                                                                    currentChapterIndex +
                                                                        1,
                                                                    _currentEpubContentNotifier,
                                                                    _epubScrollController,
                                                                    onOriginalContentReady:
                                                                        (originalHtml) {
                                                                      _originalChapterHtml =
                                                                          originalHtml;
                                                                    },
                                                                  );
                                                                }
                                                              : null,
                                                          icon:
                                                              AnimatedSwitcher(
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        200),
                                                            child: isChangingChapter
                                                                ? const SizedBox(
                                                                    key: ValueKey(
                                                                        'loading-icon'),
                                                                    width: 16,
                                                                    height: 16,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                                  )
                                                                : const Icon(
                                                                    Icons
                                                                        .chevron_right,
                                                                    size: 16,
                                                                    key: ValueKey(
                                                                        'icon'),
                                                                  ),
                                                          ),
                                                          label: const Text(
                                                            'Next',
                                                            style: TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                          iconAlignment:
                                                              IconAlignment.end,
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 20,
                                                              vertical: 5,
                                                            ),
                                                            elevation: 0,
                                                            minimumSize:
                                                                Size.zero,
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            backgroundColor: isEnabled
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .black40
                                                                : FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                            foregroundColor: isEnabled
                                                                ? Colors.white
                                                                : appBarTextColor
                                                                    .withOpacity(
                                                                        0.5),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          if (FFAppState().totalPages > 1)
                                            SliderTheme(
                                              data: SliderThemeData(
                                                activeTrackColor:
                                                    const Color(0xFFFFD700),
                                                inactiveTrackColor:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                thumbColor:
                                                    const Color(0xFFFFD700),
                                                overlayColor:
                                                    const Color(0xFFFFD700)
                                                        .withOpacity(0.2),
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                        enabledThumbRadius: 8),
                                                trackHeight: 4,
                                              ),
                                              child: Slider(
                                                value: provider.currentPage
                                                    .toDouble(),
                                                min: 1,
                                                max: FFAppState()
                                                    .totalPages
                                                    .toDouble(),
                                                onChanged: (value) {
                                                  provider.setCurrentPage(
                                                      value.toInt());
                                                  if (provider.readerType ==
                                                      ReaderType.pdf) {
                                                    pdfViewerController
                                                        .jumpToPage(provider
                                                            .currentPage);
                                                  } else {
                                                    EpubReaderWidget
                                                        .loadEpubChapter(
                                                      provider,
                                                      provider.currentPage - 1,
                                                      _currentEpubContentNotifier,
                                                      _epubScrollController,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                /// Theme Selection Widget (shown in bottom navigation section)
                                Selector<PdfViewerProvider, bool>(
                                  selector: (_, p) =>
                                      p.showThemeSelectionWidget,
                                  builder: (context, showWidget, child) {
                                    if (!showWidget)
                                      return const SizedBox.shrink();

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
                                    if (!showWidget)
                                      return const SizedBox.shrink();

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
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                            8,
                                    top: 5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (provider.readerType ==
                                              ReaderType.epub ||
                                          (provider.readerType ==
                                                  ReaderType.pdf &&
                                              provider.pdfToc.isNotEmpty))
                                        _buildBottomIcon(
                                          Icons.list,
                                          'Table of Contents',
                                          () {
                                            provider.setOpenDrawer('toc');
                                            // Open drawer immediately
                                            if (_scaffoldKey.currentState !=
                                                null) {
                                              _scaffoldKey.currentState!
                                                  .openDrawer();
                                            }
                                          },
                                          bottomNavIconColor,
                                        ),
                                      _buildBottomIcon(
                                        Icons.bookmark,
                                        'Bookmarks',
                                        () {
                                          provider.setOpenDrawer('bookmarks');
                                          // Open drawer immediately
                                          if (_scaffoldKey.currentState !=
                                              null) {
                                            _scaffoldKey.currentState!
                                                .openDrawer();
                                          }
                                        },
                                        bottomNavIconColor,
                                      ),
                                      if (provider.readerType == ReaderType.pdf)
                                        _buildBottomIcon(
                                          provider.isPdfVerticalScroll
                                              ? Icons.auto_stories
                                              : Icons.view_day,
                                          provider.isPdfVerticalScroll
                                              ? 'Switch to Flip Mode'
                                              : 'Switch to Scroll Mode',
                                          () => provider
                                              .togglePdfScrollDirection(),
                                          bottomNavIconColor,
                                        ),
                                      _buildBottomIcon(
                                        provider.isFullScreen
                                            ? Icons.fullscreen_exit_outlined
                                            : Icons.fullscreen_outlined,
                                        'Full Screen Mode',
                                        () => PdfViewerHelpers.toggleFullScreen(
                                            provider, context),
                                        bottomNavIconColor,
                                      ),
                                      _buildBottomIcon(
                                        provider.isAutoRotateEnabled
                                            ? Icons.screen_rotation
                                            : Icons.screen_lock_rotation,
                                        'Screen rotation',
                                        () => PdfViewerHelpers.toggleAutoRotate(
                                            provider),
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
                                          if (provider
                                              .showFontSelectionWidget) {
                                            provider.setShowFontSelectionWidget(
                                                false);
                                          }
                                        },
                                        bottomNavIconColor,
                                      ),
                                      if (provider.readerType ==
                                          ReaderType.epub)
                                        _buildBottomIcon(
                                          Icons.text_fields,
                                          'Font',
                                          provider.readerType == ReaderType.epub
                                              ? () {
                                                  // Toggle font selection widget
                                                  provider
                                                      .setShowFontSelectionWidget(
                                                    !provider
                                                        .showFontSelectionWidget,
                                                  );
                                                  // Close theme widget if open
                                                  if (provider
                                                      .showThemeSelectionWidget) {
                                                    provider
                                                        .setShowThemeSelectionWidget(
                                                            false);
                                                  }
                                                }
                                              : () {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Font settings only available for EPUB'),
                                                      duration:
                                                          Duration(seconds: 2),
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
              ),
              // Lightweight drawer opener widget - doesn't rebuild body content
              _DrawerOpener(scaffoldKey: _scaffoldKey),
              _buildBlueLightFilter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlueLightFilter() {
    return Selector<PdfViewerProvider, double>(
      selector: (_, p) => p.blueLightFilter,
      builder: (context, blueLightFilter, child) {
        if (blueLightFilter <= 0) return const SizedBox.shrink();

        return IgnorePointer(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.orangeAccent
                .withOpacity((blueLightFilter / 100.0) * 0.3),
          ),
        );
      },
    );
  }

  Widget _buildBottomIcon(
      IconData icon, String tooltip, VoidCallback onTap, Color iconColor) {
    return PdfViewerHelpers.buildBottomIcon(icon, tooltip, onTap, iconColor);
  }
}
