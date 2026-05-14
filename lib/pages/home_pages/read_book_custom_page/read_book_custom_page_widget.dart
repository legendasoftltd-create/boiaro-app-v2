import 'package:epub_reader_kit/epub_reader_kit.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/services/reading_report_service.dart';
import '/services/reading_progress_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'read_book_custom_page_model.dart';
export 'read_book_custom_page_model.dart';

class ReadBookCustomPageWidget extends StatefulWidget {
  const ReadBookCustomPageWidget({
    super.key,
    required this.pdf,
    required this.id,
    required this.name,
    required this.image,
    this.author,
  });

  final String? pdf;
  final String? id;
  final String? name;
  final String? image;
  final String? author;

  static String routeName = 'ReadBookCustomPage';
  static String routePath = '/readBookCustomPage';

  @override
  State<ReadBookCustomPageWidget> createState() =>
      _ReadBookCustomPageWidgetState();
}

class _ReadBookCustomPageWidgetState extends State<ReadBookCustomPageWidget>
    with WidgetsBindingObserver {
  late ReadBookCustomPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  ScaffoldMessengerState? _scaffoldMessenger;
  bool _isPreparingReader = true;
  // ignore: unused_field
  bool _isOpeningEpub = false;
  String? _epubError;
  bool _nativeEpubLaunchInProgress = false;
  bool _nativeEpubWentBackground = false;
  StreamSubscription<int>? _nativeEpubPageSub;
  int _lastNativeProgressSent = -1;
  String? _openedEpubSource;

  bool get _isEpub => (widget.pdf ?? '').toLowerCase().trim().contains('.epub');

  void _showDebugSnack(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
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
      // Ignore snackbar calls if route is already torn down.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => ReadBookCustomPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().homePageLiveReadBook = widget.image!;
      FFAppState().homePageBookId = widget.id!;
      FFAppState().homePageBookName = widget.name!;
      FFAppState().homePageBookPdf = widget.pdf!;
      FFAppState().homePageBookAuthor = widget.author ?? '';
      FFAppState().update(() {});
    });

    if (_isEpub && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await _openEpubWithPlugin();
      });
    } else {
      // Give native/pdf renderer a moment and show a consistent loading state.
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        safeSetState(() {
          _isPreparingReader = false;
        });
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_nativeEpubLaunchInProgress) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _nativeEpubWentBackground = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _nativeEpubWentBackground) {
      _nativeEpubLaunchInProgress = false;
      _nativeEpubWentBackground = false;
      unawaited(_handleNativeEpubReturn());
    }
  }

  Future<void> _handleNativeEpubReturn() async {
    await _nativeEpubPageSub?.cancel();
    _nativeEpubPageSub = null;
    await _syncNativeEpubProgress();
    await ReadingReportService.instance.endSession();
    _showDebugSnack('READING NATIVE EPUB END (on resume)');
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  String _resolveEpubSource(String path) {
    final resolved = _resolveBookPath(path);
    if (resolved.isEmpty) return '';
    final isRemote =
        resolved.startsWith('http://') || resolved.startsWith('https://');
    return isRemote ? 'remote:$resolved' : 'local:$resolved';
  }

  String _resolveBookPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
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

  Future<void> _syncNativeEpubProgress() async {
    final source = _openedEpubSource ?? _resolveEpubSource(widget.pdf ?? '');
    if (source.isEmpty) return;
    try {
      final details = await EpubReaderService.getProgressDetails(source);
      final rawPercent = details['percent'];
      final percent = rawPercent is num
          ? rawPercent.toInt()
          : int.tryParse(rawPercent?.toString() ?? '');
      if (percent == null) return;
      _lastNativeProgressSent = percent;
      await _applyNativeEpubProgress(percent, force: true);
    } catch (e) {
      _showDebugSnack('READING NATIVE EPUB PROGRESS FETCH ERROR: $e');
    }
  }

  Future<void> _applyNativeEpubProgress(int percent,
      {bool force = false}) async {
    final bookId = (widget.id ?? '').trim();
    if (bookId.isEmpty) return;
    final bounded = percent.clamp(0, 100);
    await ReadingProgressService.upsertProgress(
      bookId: bookId,
      percent: bounded.toDouble(),
      name: widget.name ?? '',
      imageUrl: widget.image ?? '',
      author: widget.author ?? '',
      contentType: 'ebook',
    );
    FFAppState().homePageCurrentPdfIndex = bounded;
    FFAppState().homePageTotalPdfPageIndex = 100;
    FFAppState().update(() {});
    await ReadingReportService.instance.updateProgress(
      percentage: bounded,
      force: force,
    );
  }

  Future<String> _prepareNativeEpubPath(String sourcePath) async {
    final isRemote = sourcePath.startsWith('http://') ||
        sourcePath.startsWith('https://');
    if (!isRemote) {
      _openedEpubSource = _resolveEpubSource(sourcePath);
      return sourcePath;
    }

    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, 'native_epub_cache'));
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }

    final uri = Uri.parse(sourcePath);
    final ext = p.extension(uri.path).toLowerCase();
    final safeExt = ext.isEmpty ? '.epub' : ext;
    final fileName =
        'book_${widget.id ?? DateTime.now().millisecondsSinceEpoch}$safeExt';
    final cachedFile = File(p.join(cacheDir.path, fileName));

    if (!cachedFile.existsSync() || cachedFile.lengthSync() == 0) {
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Failed to download EPUB (${response.statusCode})',
          uri: uri,
        );
      }
      await cachedFile.writeAsBytes(response.bodyBytes, flush: true);
    }

    _openedEpubSource = 'local:${cachedFile.path}';
    return cachedFile.path;
  }

  Future<void> _openEpubWithPlugin() async {
    final sourcePath = _resolveBookPath(widget.pdf ?? '');
    if (sourcePath.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isPreparingReader = false;
      _isOpeningEpub = true;
      _epubError = null;
    });

    try {
      final bookId = (widget.id ?? '').trim();
      if (bookId.isNotEmpty) {
        await ReadingReportService.instance.startSession(bookId: bookId);
        // Pre-load TTS context into native layer so the in-reader ⚙ button
        // can open Premium settings without a Flutter round-trip.
        unawaited(EpubReaderService.ttsSetContext(
          bookId   : bookId,
          apiBase  : FFAppConstants.mobileApiBaseUrl,
          authToken: FFAppState().token,
        ));
        await _applyNativeEpubProgress(0, force: true);
        _nativeEpubPageSub?.cancel();
        _lastNativeProgressSent = 0;
        _nativeEpubPageSub = EpubReaderService.onPageChanged.listen((percent) {
          if (percent == _lastNativeProgressSent) return;
          _lastNativeProgressSent = percent;
          unawaited(_applyNativeEpubProgress(percent, force: true));
          _showDebugSnack('READING NATIVE EPUB PROGRESS: $percent%');
        });
        _nativeEpubLaunchInProgress = true;
        _nativeEpubWentBackground = false;
        _showDebugSnack('READING NATIVE EPUB START: bookId=$bookId');
      }
      final path = await _prepareNativeEpubPath(sourcePath);
      final opened = await EpubReaderService.readBook(
        filePath: path,
      );
      if (!opened) {
        throw Exception('Failed to open EPUB reader');
      }
    } catch (e) {
      await _nativeEpubPageSub?.cancel();
      _nativeEpubPageSub = null;
      _nativeEpubLaunchInProgress = false;
      _nativeEpubWentBackground = false;
      await ReadingReportService.instance.endSession();
      if (!mounted) return;
      setState(() => _epubError = e.toString());
      _showDebugSnack('READING NATIVE EPUB ERROR: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isOpeningEpub = false);
    }
  }

  @override
  void dispose() {
    _nativeEpubPageSub?.cancel();
    _nativeEpubPageSub = null;

    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              _isEpub &&
                      !kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.android
                  ? (_epubError == null
                      ? const SizedBox.shrink()
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _epubError!,
                                  textAlign: TextAlign.center,
                                  style:
                                      FlutterFlowTheme.of(context).bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _openEpubWithPlugin,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ))
                  : custom_widgets.FlutterPdfViewWidget(
                      width: double.infinity,
                      height: double.infinity,
                      filePath: widget.pdf,
                      namePage: widget.name,
                      bookId: widget.id,
                    ),
              if (_isPreparingReader && !_isEpub)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: FlutterFlowTheme.of(context)
                      .primaryBackground
                      .withValues(alpha: 0.96),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Opening reader...',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
