import 'package:epub_reader_kit/epub_reader_kit.dart';
import 'package:epubx/epubx.dart' as epubx;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/services/reading_report_service.dart';
import '/services/reading_progress_service.dart';
import '/services/progress_sync_service.dart';
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
    this.isPreviewMode = false,
    this.previewPercent = 100,
  });

  final String? pdf;
  final String? id;
  final String? name;
  final String? image;
  final String? author;
  final bool isPreviewMode;
  final int previewPercent;

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
  bool _previewLimitShown = false;

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
      if (!widget.isPreviewMode) {
        FFAppState().homePageLiveReadBook = widget.image!;
        FFAppState().homePageBookId = widget.id!;
        FFAppState().homePageBookName = widget.name!;
        FFAppState().homePageBookPdf = widget.pdf!;
        FFAppState().homePageBookAuthor = widget.author ?? '';
        FFAppState().update(() {});
      }
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
    if (bounded <= 0) {
      return;
    }
    await ReadingProgressService.upsertProgress(
      bookId: bookId,
      percent: bounded.toDouble(),
      name: widget.name ?? '',
      imageUrl: widget.image ?? '',
      author: widget.author ?? '',
      contentType: 'ebook',
    );
    if (!widget.isPreviewMode) {
      FFAppState().homePageCurrentPdfIndex = bounded;
      FFAppState().homePageTotalPdfPageIndex = 100;
      FFAppState().update(() {});
    }
    await ProgressSyncService.saveReadingProgress(
      bookId: bookId,
      currentPage: bounded,
      totalPages: 100,
    );
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

    // Use getApplicationDocumentsDirectory (getFilesDir on Android) instead of
    // getTemporaryDirectory (getCacheDir). The native epub_reader_kit / Readium
    // plugin cannot reliably access files from the Android cache/temp directory,
    // but the app's documents directory is always accessible by native code.
    final docsDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(docsDir.path, 'native_epub_cache'));
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }

    final uri = Uri.parse(sourcePath);
    final ext = p.extension(uri.path).toLowerCase();
    final safeExt = ext.isEmpty ? '.epub' : ext;
    final bookId = widget.id ?? 'unknown';

    // ── KEY FIX: timestamp-based unique filename ──────────────────────────────
    // The epub_reader_kit plugin has its own SQLite DB keyed by sourceKey
    // (= the local file path). If we reuse the same filename, the plugin finds
    // the OLD stale DB entry and calls readerRepository.open() on it — which
    // fails with "Could not open publication" because the stored Readium
    // publication data no longer matches the new epub content.
    //
    // Fix: embed a timestamp in the filename so every download gets a UNIQUE
    // path → unique sourceKey → plugin always does a fresh import.
    // ─────────────────────────────────────────────────────────────────────────
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'book_${bookId}_$timestamp$safeExt';
    final cachedFile = File(p.join(cacheDir.path, fileName));

    // Clean up any previous timestamped epub files for this book to avoid
    // filling the user's storage over time.
    try {
      for (final f in cacheDir.listSync()) {
        if (f is File) {
          final name = p.basename(f.path);
          if (name.startsWith('book_${bookId}_') && name.endsWith(safeExt) &&
              f.path != cachedFile.path) {
            await f.delete();
          }
        }
      }
    } catch (_) {}

    // Add a cache-busting query param to defeat CDN / proxy caches,
    // BUT skip it for pre-signed URLs (e.g. AWS S3) because those have a
    // cryptographic signature over their exact query parameters — adding any
    // extra param invalidates the signature and causes a 403 error.
    final isPresigned = uri.queryParameters.containsKey('X-Amz-Signature') ||
        uri.queryParameters.containsKey('Signature');
    final fetchUri = isPresigned
        ? uri
        : uri.replace(queryParameters: {
            ...uri.queryParameters,
            '_cb': timestamp.toString(),
          });

    final response = await http.get(fetchUri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to download EPUB (${response.statusCode})',
        uri: uri,
      );
    }

    final bytes = response.bodyBytes;

    // Validate ZIP/PK magic bytes — every valid epub is a zip archive.
    if (bytes.length < 4 ||
        bytes[0] != 0x50 || // 'P'
        bytes[1] != 0x4B) { // 'K'
      final preview = bytes.length > 200
          ? String.fromCharCodes(bytes.sublist(0, 200))
          : String.fromCharCodes(bytes);
      throw Exception(
        'Downloaded file is not a valid EPUB (${bytes.length} bytes). '
        'Server may have returned an error page: $preview',
      );
    }

    await cachedFile.writeAsBytes(bytes, flush: true);

    // Pre-validate the epub structure using epubx before handing to the
    // native Readium reader.  Readium returns the opaque error
    // "No navigator supports this publication" when the epub has structural
    // issues (broken TOC, missing manifest entries, invalid OPF, etc.).
    // Catching it here gives the admin a precise, actionable diagnosis.
    try {
      final book = await epubx.EpubReader.readBook(bytes);
      final hasContent = (book.Chapters?.isNotEmpty == true) ||
          (book.Content?.Html?.isNotEmpty == true);
      if (!hasContent) {
        await cachedFile.delete();
        throw Exception(
          'This book has no readable content.\n'
          'The EPUB file may be empty or corrupted.\n'
          'Please ask support to re-upload a valid EPUB.',
        );
      }
    } catch (e) {
      final msg = e.toString();

      // Re-throw errors we already constructed above.
      if (msg.contains('no readable content') ||
          msg.contains('not a valid EPUB')) {
        rethrow;
      }

      // Specific diagnosis for the most common structural epub errors.
      final userMsg = () {
        if (msg.contains('TOC') || msg.contains('manifest')) {
          return 'This book has a broken Table of Contents — '
              'a TOC entry references a file that does not exist '
              'inside the EPUB package.\n'
              'Technical detail: $msg\n'
              'Please ask support to re-upload a correctly '
              'formatted EPUB file.';
        }
        if (msg.contains('OPF') || msg.contains('container')) {
          return 'This book is missing its package descriptor (OPF/container).\n'
              'The file may not be a real EPUB (e.g. a PDF renamed to .epub).\n'
              'Technical detail: $msg\n'
              'Please ask support to re-upload a valid EPUB.';
        }
        return 'This book file is not a valid EPUB.\n'
            'Technical detail: $msg\n'
            'Please ask support to re-upload the book.';
      }();

      await cachedFile.delete();
      throw Exception(userMsg);
    }

    _openedEpubSource = 'local:${cachedFile.path}';
    return cachedFile.path;
  }

  void _showPreviewLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Preview Ended'),
        content: Text(
          'You\'ve reached the ${widget.previewPercent}% preview limit for '
          '"${widget.name ?? 'this book'}". '
          'Purchase the full book to continue reading.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Buy Now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        _nativeEpubPageSub?.cancel();
        _lastNativeProgressSent = -1;
        _nativeEpubPageSub = EpubReaderService.onPageChanged.listen((percent) {
          if (percent == _lastNativeProgressSent) return;
          _lastNativeProgressSent = percent;
          unawaited(_applyNativeEpubProgress(percent, force: true));
          _showDebugSnack('READING NATIVE EPUB PROGRESS: $percent%');
          if (widget.isPreviewMode && !_previewLimitShown && percent >= widget.previewPercent) {
            _previewLimitShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showPreviewLimitDialog();
            });
          }
        });
        _nativeEpubLaunchInProgress = true;
        _nativeEpubWentBackground = false;
        _showDebugSnack('READING NATIVE EPUB START: bookId=$bookId');
      }
      final path = await _prepareNativeEpubPath(sourcePath);
      final opened = await EpubReaderService.readBook(
        filePath: path,
        previewPercent: widget.isPreviewMode ? widget.previewPercent : 100,
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
