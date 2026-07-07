import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:screen_protector/screen_protector.dart';

import 'theme_selection_widget.dart';
import 'bookmarks_highlights_drawer.dart';
import 'search_drawer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'pdf_viewer_provider.dart';
import 'pdf_viewer_helpers.dart';
import 'pdf_viewer_text_operations.dart';
import 'pdf_viewer_pdf_operations.dart';
import '/services/reading_report_service.dart';

class FlutterPdfViewWidget extends StatefulWidget {
  const FlutterPdfViewWidget({
    super.key,
    this.width,
    this.height,
    this.filePath,
    this.namePage,
    this.bookId,
    this.initialPage,
    this.onPageChanged,
  });

  final double? width;
  final double? height;
  final String? filePath;
  final String? namePage;
  final String? bookId;
  final int? initialPage;
  final void Function(int page, int totalPages)? onPageChanged;

  @override
  State<FlutterPdfViewWidget> createState() => _FlutterPdfViewWidgetState();
}

class _DrawerOpener extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _DrawerOpener({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Selector<PdfViewerProvider, String?>(
      selector: (_, p) => p.openDrawer,
      builder: (context, openDrawer, child) {
        if (openDrawer == 'search_pdf') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scaffoldKey.currentState != null) {
              scaffoldKey.currentState!.openEndDrawer();
            }
          });
        } else if (openDrawer == 'bookmarks') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scaffoldKey.currentState != null) {
              scaffoldKey.currentState!.openDrawer();
            }
          });
        }
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
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _localSelectedTextNotifier = ValueNotifier<String>('');
  String? _currentBookId;
  String? _resolvedFilePath;
  bool _isLoading = true;
  Timer? _progressHeartbeatTimer;
  bool _hasEndedForBackground = false;
  ScaffoldMessengerState? _scaffoldMessenger;
  bool _initialProgressLoaded = false;

  // Button click debouncing
  DateTime? _lastButtonClick;
  static const _buttonDebounceMs = 300;

  bool _canProcessClick() {
    final now = DateTime.now();
    if (_lastButtonClick != null &&
        now.difference(_lastButtonClick!).inMilliseconds < _buttonDebounceMs) {
      return false;
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
    } catch (_) {}
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapReader());
    });
  }

  Future<void> _bootstrapReader() async {
    if (!mounted) return;
    final provider = context.read<PdfViewerProvider>();
    _currentBookId = PdfViewerTextOperations.generateBookId(_resolvedFilePath);
    provider.setCurrentBookId(_currentBookId);
    provider.loadHighlights(_currentBookId!);
    provider.loadBookmarks(_currentBookId!);

    PdfViewerHelpers.determineReaderType(_resolvedFilePath, provider);
    
    final initialPage = widget.initialPage ?? provider.currentPage;
    provider.setCurrentPage(initialPage > 0 ? initialPage : 1);
    
    PdfViewerHelpers.getInitialBrightness(provider);
    ReadingReportService.instance.setDebugListener(_onReadingDebug);

    ScreenProtector.protectDataLeakageOn();
    
    // Fire initial page changed callback
    widget.onPageChanged?.call(provider.currentPage, FFAppState().totalPages);
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


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ReadingReportService.instance.setDebugListener(null);
    unawaited(ReadingReportService.instance.endSession());
    final provider = context.read<PdfViewerProvider>();
    PdfViewerHelpers.restoreOriginalBrightness(provider);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _searchController.dispose();
    _localSelectedTextNotifier.dispose();
    ScreenProtector.protectDataLeakageOff();
    super.dispose();
  }

  void setCurrentPage(PdfViewerProvider provider) {
    if (!_canProcessClick()) return;
    if (provider.currentPage != FFAppState().totalPages) {
      provider.incrementPage();
      pdfViewerController.jumpToPage(provider.currentPage);
      widget.onPageChanged?.call(provider.currentPage, FFAppState().totalPages);
    }
  }

  void setCurrentMinusPage(PdfViewerProvider provider) {
    if (!_canProcessClick()) return;
    if (provider.currentPage > 1) {
      provider.decrementPage();
      pdfViewerController.jumpToPage(provider.currentPage);
      widget.onPageChanged?.call(provider.currentPage, FFAppState().totalPages);
    }
  }

  void _toggleBookmark(PdfViewerProvider provider) async {
    if (_currentBookId == null) {
      log('Cannot toggle bookmark: bookId is null');
      return;
    }
    final currentPage = provider.currentPage;
    await provider.toggleBookmark(
      currentPage,
      bookId: _currentBookId,
      chapterId: currentPage.toString(),
      chapterName: 'Page $currentPage',
    );
  }

  void _clearSearch(PdfViewerProvider provider) {
    PdfViewerPdfOperations.clearSearch(provider, _searchController);
  }

  void _goToNextSearchResult(PdfViewerProvider provider) {
    provider.setNavigatingSearchResult(true);
    PdfViewerPdfOperations.goToNextSearchResult(provider);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final currentPage = pdfViewerController.pageNumber;
        final currentIndex = provider.searchResult.currentInstanceIndex;
        provider.updateSearchResultDetail(currentIndex, currentPage, null);
        provider.setNavigatingSearchResult(false);
      }
    });
  }

  void _goToPreviousSearchResult(PdfViewerProvider provider) {
    provider.setNavigatingSearchResult(true);
    PdfViewerPdfOperations.goToPreviousSearchResult(provider);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final currentPage = pdfViewerController.pageNumber;
        final currentIndex = provider.searchResult.currentInstanceIndex;
        provider.updateSearchResultDetail(currentIndex, currentPage, null);
        provider.setNavigatingSearchResult(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    return Selector<PdfViewerProvider, (AppThemeMode, bool, bool)>(
      selector: (_, p) => (
        p.currentThemeMode,
        p.isFullScreen,
        p.isPdfVerticalScroll
      ),
      builder: (context, data, child) {
        final themeMode = data.$1;
        final isFullScreen = data.$2;
        final isPdfVerticalScroll = data.$3;
        final provider = context.read<PdfViewerProvider>();

        Color scaffoldBackgroundColor;
        Color appBarBackgroundColor;
        Color appBarTextColor;
        Color bottomNavIconColor;

        switch (themeMode) {
          case AppThemeMode.light:
            scaffoldBackgroundColor = Colors.white;
            appBarBackgroundColor = Colors.white;
            appBarTextColor = Colors.black;
            bottomNavIconColor = const Color(0xFF57636C);
            break;
          case AppThemeMode.dark:
            scaffoldBackgroundColor = Colors.black;
            appBarBackgroundColor = Colors.black;
            appBarTextColor = Colors.white;
            bottomNavIconColor = Colors.white;
            break;
          case AppThemeMode.sepia:
            scaffoldBackgroundColor = const Color(0xFFF5DEB3);
            appBarBackgroundColor = const Color(0xFFF5DEB3);
            appBarTextColor = Colors.black;
            bottomNavIconColor = const Color(0xFF57636C);
            break;
        }

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
            if (!isOpened && provider.openDrawer == 'bookmarks') {
              provider.setOpenDrawer(null);
            }
          },
          onEndDrawerChanged: (isOpened) {
            if (!isOpened && provider.openDrawer == 'search_pdf') {
              provider.setOpenDrawer(null);
            }
          },
          drawer: Selector<PdfViewerProvider, String?>(
            selector: (_, p) => p.openDrawer,
            builder: (context, openDrawer, child) {
              if (openDrawer == 'bookmarks') {
                return BookmarksHighlightsDrawer(
                  pdfController: pdfViewerController,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          endDrawer: Selector<PdfViewerProvider, String?>(
            selector: (_, p) => p.openDrawer,
            builder: (context, openDrawer, child) {
              if (openDrawer == 'search_pdf') {
                return SearchDrawer(
                  searchController: _searchController,
                  pdfController: pdfViewerController,
                  onNextResult: () => _goToNextSearchResult(provider),
                  onPreviousResult: () => _goToPreviousSearchResult(provider),
                  onClearSearch: () => _clearSearch(provider),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Selector<PdfViewerProvider, AppThemeMode>(
                          selector: (_, p) => p.currentThemeMode,
                          builder: (context, themeMode, child) {
                            Widget pdfContent = ClipRect(
                              child: child!,
                            );

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
                            padding: const EdgeInsets.only(top: 50),
                            color: Colors.white,
                            child: (_resolvedFilePath != null &&
                                    (_resolvedFilePath!.startsWith('http') ||
                                        _resolvedFilePath!.startsWith('https')))
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
                                      int totalPages = details.document.pages.count;
                                      FFAppState().totalPages = totalPages;
                                      FFAppState().update(() {
                                        FFAppState().homePageTotalPdfPageIndex =
                                            FFAppState().totalPages;
                                      });

                                      pdfViewerController.jumpToPage(provider.currentPage);
                                    },
                                    onDocumentLoadFailed:
                                        (PdfDocumentLoadFailedDetails details) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      log("PDF Load Failed: ${details.error}");
                                    },
                                    onPageChanged: (details) {
                                      SchedulerBinding.instance
                                          .addPostFrameCallback((_) {
                                        provider.setCurrentPage(details.newPageNumber);
                                        widget.onPageChanged?.call(details.newPageNumber, FFAppState().totalPages);
                                      });
                                    },
                                    onTextSelectionChanged:
                                        (PdfTextSelectionChangedDetails details) {
                                      if (details.selectedText != null &&
                                          details.selectedText!.isNotEmpty) {
                                        provider.setSelectedText(details.selectedText!);
                                        _localSelectedTextNotifier.value = details.selectedText!;
                                      } else {
                                        provider.clearSelectedText();
                                        _localSelectedTextNotifier.value = '';
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
                                      int totalPages = details.document.pages.count;
                                      FFAppState().totalPages = totalPages;
                                      FFAppState().update(() {
                                        FFAppState().homePageTotalPdfPageIndex =
                                            FFAppState().totalPages;
                                      });

                                      pdfViewerController.jumpToPage(provider.currentPage);
                                    },
                                    onDocumentLoadFailed:
                                        (PdfDocumentLoadFailedDetails details) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      log("PDF Load Failed: ${details.error}");
                                    },
                                    onPageChanged: (details) {
                                      SchedulerBinding.instance
                                          .addPostFrameCallback((_) {
                                        provider.setCurrentPage(details.newPageNumber);
                                        widget.onPageChanged?.call(details.newPageNumber, FFAppState().totalPages);
                                      });
                                    },
                                    onTextSelectionChanged:
                                        (PdfTextSelectionChangedDetails details) {
                                      if (details.selectedText != null &&
                                          details.selectedText!.isNotEmpty) {
                                        provider.setSelectedText(details.selectedText!);
                                        _localSelectedTextNotifier.value = details.selectedText!;
                                      } else {
                                        provider.clearSelectedText();
                                        _localSelectedTextNotifier.value = '';
                                      }
                                    },
                                  ),
                          ),
                        ),
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        if (isFullScreen)
                          Positioned(
                            top: 20,
                            right: 20,
                            child: InkWell(
                              onTap: () {
                                PdfViewerHelpers.toggleFullScreen(provider, context);
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
                                          provider.setOpenDrawer('search_pdf');
                                          _scaffoldKey.currentState?.openEndDrawer();
                                        },
                                        child: Icon(
                                          Icons.search,
                                          size: 24,
                                          color: appBarTextColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Selector<PdfViewerProvider, (List<int>, int)>(
                                        selector: (_, p) => (p.bookmarkedPages, p.currentPage),
                                        builder: (context, data, child) {
                                          final bookmarkedPages = data.$1;
                                          final currentPage = data.$2;
                                          return InkWell(
                                            onTap: () => _toggleBookmark(provider),
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Selector<PdfViewerProvider, bool>(
                    selector: (_, p) => p.isFullScreen,
                    builder: (context, isFullScreen, child) {
                      if (isFullScreen) {
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Selector<PdfViewerProvider, bool>(
                              selector: (_, p) => p.showThemeSelectionWidget,
                              builder: (context, showThemeWidget, child) {
                                if (showThemeWidget) return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(right: 16, left: 16, top: 12),
                                  child: Column(
                                    children: [
                                      if (FFAppState().totalPages > 1)
                                        SliderTheme(
                                          data: SliderThemeData(
                                            activeTrackColor: const Color(0xFFFFD700),
                                            inactiveTrackColor:
                                                FlutterFlowTheme.of(context).alternate,
                                            thumbColor: const Color(0xFFFFD700),
                                            overlayColor:
                                                const Color(0xFFFFD700).withOpacity(0.2),
                                            thumbShape: const RoundSliderThumbShape(
                                                enabledThumbRadius: 8),
                                            trackHeight: 4,
                                          ),
                                          child: Slider(
                                            value: provider.currentPage.toDouble(),
                                            min: 1,
                                            max: FFAppState().totalPages.toDouble(),
                                            onChanged: (value) {
                                              provider.setCurrentPage(value.toInt());
                                              pdfViewerController.jumpToPage(provider.currentPage);
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Selector<PdfViewerProvider, bool>(
                              selector: (_, p) => p.showThemeSelectionWidget,
                              builder: (context, showWidget, child) {
                                if (!showWidget) return const SizedBox.shrink();
                                return Container(
                                  child: const ThemeBrightnessWidget(),
                                );
                              },
                            ),
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
                                    Icons.bookmark,
                                    'Bookmarks',
                                    () {
                                      provider.setOpenDrawer('bookmarks');
                                      if (_scaffoldKey.currentState != null) {
                                        _scaffoldKey.currentState!.openDrawer();
                                      }
                                    },
                                    bottomNavIconColor,
                                  ),
                                  _buildBottomIcon(
                                    provider.isPdfVerticalScroll
                                        ? Icons.auto_stories
                                        : Icons.view_day,
                                    provider.isPdfVerticalScroll
                                        ? 'Switch to Flip Mode'
                                        : 'Switch to Scroll Mode',
                                    () => provider.togglePdfScrollDirection(),
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
                                      provider.setShowThemeSelectionWidget(
                                        !provider.showThemeSelectionWidget,
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
                  ),
                ],
              ),
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
            color: Colors.orangeAccent.withOpacity((blueLightFilter / 100.0) * 0.3),
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
