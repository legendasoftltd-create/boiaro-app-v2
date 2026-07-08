import 'package:epub_reader_kit/epub_reader_kit.dart';
import 'package:epubx/epubx.dart' as epubx;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_pdf_viewer.dart';
import '/flutter_flow/internationalization.dart';
import '/custom_code/widgets/pdf_viewer/flutter_pdf_view_widget.dart';
import '/services/reading_report_service.dart';
import '/services/reading_progress_service.dart';
import '/services/progress_sync_service.dart';
import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';
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
import 'ios_epub_reader_screen.dart';
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
  int _initialPdfPage = 1;

  bool get _isEpub => (widget.pdf ?? '').toLowerCase().trim().contains('.epub');

  void _showDebugSnack(String message) {
    print('EPUB_DEBUG: $message');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    print('DEBUG_INIT: widget.pdf = ${widget.pdf}');
    print('DEBUG_INIT: _isEpub = $_isEpub');
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

    if (_isEpub && !kIsWeb) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        double? initialProgress;
        final bookId = (widget.id ?? '').trim();
        if (bookId.isNotEmpty) {
          final remote = await ProgressSyncService.fetchReadingProgress(bookId);
          if (remote.hasProgress && remote.currentPage > 0) {
            initialProgress = remote.currentPage.toDouble();
          }
        }
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await _openIosEpub(initialProgress: initialProgress);
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          await _openEpubWithPlugin(initialProgress: initialProgress);
        }
      });
    } else {
      // Give native/pdf renderer a moment and show a consistent loading state.
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        final bookId = (widget.id ?? '').trim();
        if (bookId.isNotEmpty) {
          final remote = await ProgressSyncService.fetchReadingProgress(bookId);
          if (remote.hasProgress && remote.currentPage > 0) {
            _initialPdfPage = remote.currentPage;
          }
          await ReadingReportService.instance.startSession(bookId: bookId);
          unawaited(EbookGroup.registerBookReadApiCall.call(
            bookId: bookId,
            token: FFAppState().token.isNotEmpty ? FFAppState().token : null,
          ));
        }
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
    print('EPUB_DEBUG: _prepareNativeEpubPath started with sourcePath=$sourcePath');
    final isRemote = sourcePath.startsWith('http://') ||
        sourcePath.startsWith('https://');
    if (!isRemote) {
      _openedEpubSource = _resolveEpubSource(sourcePath);
      print('EPUB_DEBUG: Returning local path: $_openedEpubSource');
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

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'book_${bookId}$safeExt';
    final cachedFile = File(p.join(cacheDir.path, fileName));

    // Check if the cached file already exists and is a valid EPUB.
    // If it is, return it directly. This avoids downloading it on every open
    // and keeps the path (and therefore sourceKey) stable, allowing
    // the native reader to load the last reading position from the database.
    if (cachedFile.existsSync() && cachedFile.lengthSync() > 0) {
      try {
        final bytes = await cachedFile.readAsBytes();
        final book = await epubx.EpubReader.readBook(bytes);
        final hasContent = (book.Chapters?.isNotEmpty == true) ||
            (book.Content?.Html?.isNotEmpty == true);
        if (hasContent) {
          _openedEpubSource = 'local:${cachedFile.path}';
          return cachedFile.path;
        }
      } catch (e) {
        debugPrint('Cached EPUB validation failed, re-downloading: $e');
        try {
          await cachedFile.delete();
        } catch (_) {}
      }
    }

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
          return FFLocalizations.of(context).getVariableText(
            enText: 'This book has a broken Table of Contents — '
                'a TOC entry references a file that does not exist '
                'inside the EPUB package.\n'
                'Technical detail: $msg\n'
                'Please ask support to re-upload a correctly '
                'formatted EPUB file.',
            bnText: 'এই বইটির সূচিপত্র (TOC) ত্রুটিযুক্ত — '
                'সূচিপত্রের একটি ফাইল EPUB প্যাকেজে খুঁজে পাওয়া যায়নি।\n'
                'প্রযুক্তিগত বিবরণ: $msg\n'
                'অনুগ্রহ করে সঠিকভাবে ফরম্যাট করা EPUB ফাইল পুনরায় আপলোড করার জন্য সহায়তায় যোগাযোগ করুন।',
          );
        }
        if (msg.contains('OPF') || msg.contains('container')) {
          return FFLocalizations.of(context).getVariableText(
            enText: 'This book is missing its package descriptor (OPF/container).\n'
                'The file may not be a real EPUB (e.g. a PDF renamed to .epub).\n'
                'Technical detail: $msg\n'
                'Please ask support to re-upload a valid EPUB.',
            bnText: 'বইটির প্যাকেজ ডেসক্রিপ্টর (OPF/container) পাওয়া যায়নি।\n'
                'ফাইলটি প্রকৃত EPUB নাও হতে পারে (যেমন: .epub নামে পিডিএফ)।\n'
                'প্রযুক্তিগত বিবরণ: $msg\n'
                'অনুগ্রহ করে সঠিক EPUB ফাইল পুনরায় আপলোডের জন্য সহায়তায় যোগাযোগ করুন।',
          );
        }
        return FFLocalizations.of(context).getVariableText(
          enText: 'This book file is not a valid EPUB.\n'
              'Technical detail: $msg\n'
              'Please ask support to re-upload the book.',
          bnText: 'বইটির ফাইলটি সঠিক EPUB ফাইল নয়।\n'
              'প্রযুক্তিগত বিবরণ: $msg\n'
              'অনুগ্রহ করে বইটি পুনরায় আপলোডের জন্য সহায়তায় যোগাযোগ করুন।',
        );
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
        title: Text(FFLocalizations.of(context).getVariableText(enText: 'Preview Ended', bnText: 'প্রিভিউ শেষ')),
        content: Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'You\'ve reached the ${widget.previewPercent}% preview limit for "${widget.name ?? 'this book'}". Purchase the full book to continue reading.',
            bnText: 'â\u0080\u009c${widget.name ?? 'এই বই'}â\u0080\u009d-এর ${widget.previewPercent}% প্রিভিউ শেষ হয়েছে। সম্পূর্ণ বই পড়তে কিনুন।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: Text(FFLocalizations.of(context).getVariableText(enText: 'Buy Now', bnText: 'এখনি কিনুন')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(FFLocalizations.of(context).getVariableText(enText: 'Close', bnText: 'বন্ধ করুন')),
          ),
        ],
      ),
    );
  }

  Future<void> _openIosEpub({double? initialProgress}) async {
    print('EPUB_DEBUG: _openIosEpub started');
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
        unawaited(EbookGroup.registerBookReadApiCall.call(
          bookId: bookId,
          token: FFAppState().token.isNotEmpty ? FFAppState().token : null,
        ));
      }
      
      final path = await _prepareNativeEpubPath(sourcePath);
      print('EPUB_DEBUG: Launching IosEpubReaderScreen with path=$path');
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IosEpubReaderScreen(
            epubPath: path,
            bookTitle: widget.name ?? 'Book',
            initialProgress: initialProgress,
            bookId: bookId,
          ),
        ),
      );
      
      if (mounted) {
        setState(() => _isOpeningEpub = false);
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      print('EPUB_DEBUG: Error opening iOS EPUB: $e');
      if (mounted) {
        setState(() {
          _epubError = 'Failed to load EPUB: $e';
          _isOpeningEpub = false;
        });
      }
    }
  }

  Future<void> _openEpubWithPlugin({double? initialProgress}) async {
    print('EPUB_DEBUG: _openEpubWithPlugin started');
    final sourcePath = _resolveBookPath(widget.pdf ?? '');
    print('EPUB_DEBUG: resolved sourcePath=$sourcePath');
    if (sourcePath.isEmpty || !mounted) {
      print('EPUB_DEBUG: sourcePath is empty or not mounted');
      return;
    }

    setState(() {
      _isPreparingReader = false;
      _isOpeningEpub = true;
      _epubError = null;
    });

    try {
      final bookId = (widget.id ?? '').trim();
      print('EPUB_DEBUG: bookId=$bookId');
      if (bookId.isNotEmpty) {
        await ReadingReportService.instance.startSession(bookId: bookId);
        print('EPUB_DEBUG: startSession finished');

        // Register book read/view — fire-and-forget, auth optional
        unawaited(EbookGroup.registerBookReadApiCall.call(
          bookId: bookId,
          token: FFAppState().token.isNotEmpty ? FFAppState().token : null,
        ));
        print('EPUB_DEBUG: registerBookReadApiCall dispatched');

        // Pre-load TTS context into native layer (Android only)
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
        bookTitle: widget.name,
        initialProgress: initialProgress,
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

  Future<void> _onPdfPageChanged(int page, int totalPages) async {
    final bookId = (widget.id ?? '').trim();
    if (bookId.isEmpty) return;
    final percentage = (page / totalPages * 100).toInt().clamp(0, 100);

    await ReadingProgressService.upsertProgress(
      bookId: bookId,
      percent: percentage.toDouble(),
      name: widget.name ?? '',
      imageUrl: widget.image ?? '',
      author: widget.author ?? '',
      contentType: 'ebook',
    );
    if (!widget.isPreviewMode) {
      FFAppState().homePageCurrentPdfIndex = page;
      FFAppState().homePageTotalPdfPageIndex = totalPages;
      FFAppState().update(() {});
    }
    await ProgressSyncService.saveReadingProgress(
      bookId: bookId,
      currentPage: page,
      totalPages: totalPages,
    );
    await ReadingReportService.instance.updateProgress(
      percentage: percentage,
      force: false,
    );
    if (widget.isPreviewMode && !_previewLimitShown && percentage >= widget.previewPercent) {
      _previewLimitShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPreviewLimitDialog();
      });
    }
    _showDebugSnack('READING PDF PROGRESS: Page $page of $totalPages ($percentage%)');
  }

  @override
  void dispose() {
    _nativeEpubPageSub?.cancel();
    _nativeEpubPageSub = null;

    if (!_isEpub) {
      unawaited(ReadingReportService.instance.endSession());
    }

    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();

    super.dispose();
  }

  Widget _buildPdfViewer() {
    final resolvedPath = _resolveBookPath(widget.pdf ?? '');
    if (resolvedPath.isEmpty) {
      return Center(child: Text(FFLocalizations.of(context).getVariableText(enText: 'Invalid PDF path', bnText: 'অবৈধ PDF ঠিকানা')));
    }
    return FlutterPdfViewWidget(
      width: double.infinity,
      height: double.infinity,
      filePath: resolvedPath,
      namePage: widget.name,
      bookId: widget.id,
      initialPage: _initialPdfPage,
      onPageChanged: _onPdfPageChanged,
    );
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
                      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
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
                                  onPressed: () {
                                    if (defaultTargetPlatform == TargetPlatform.iOS) {
                                      _openIosEpub();
                                    } else {
                                      _openEpubWithPlugin();
                                    }
                                  },
                                  child: Text(FFLocalizations.of(context).getVariableText(enText: 'Retry', bnText: 'আবার চেষ্টা করুন')),
                                ),
                              ],
                            ),
                          ),
                        ))
                  : _buildPdfViewer(),
              if ((_isPreparingReader && !_isEpub) || _isOpeningEpub)
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
                      Text(FFLocalizations.of(context).getVariableText(enText: 'Opening reader...', bnText: 'রিডার খোলা হচ্ছে...'),
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
