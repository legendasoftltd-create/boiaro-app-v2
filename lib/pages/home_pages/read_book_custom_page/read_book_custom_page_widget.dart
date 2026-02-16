import 'package:epub_reader_kit/epub_reader_kit.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'read_book_custom_page_model.dart';
export 'read_book_custom_page_model.dart';

class ReadBookCustomPageWidget extends StatefulWidget {
  const ReadBookCustomPageWidget({
    super.key,
    required this.pdf,
    required this.id,
    required this.name,
    required this.image,
  });

  final String? pdf;
  final String? id;
  final String? name;
  final String? image;

  static String routeName = 'ReadBookCustomPage';
  static String routePath = '/readBookCustomPage';

  @override
  State<ReadBookCustomPageWidget> createState() =>
      _ReadBookCustomPageWidgetState();
}

class _ReadBookCustomPageWidgetState extends State<ReadBookCustomPageWidget> {
  late ReadBookCustomPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isOpeningEpub = false;
  String? _epubError;

  bool get _isEpub =>
      (widget.pdf ?? '').toLowerCase().trim().contains('.epub');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReadBookCustomPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().homePageLiveReadBook = widget.image!;
      FFAppState().homePageBookId = widget.id!;
      FFAppState().homePageBookName = widget.name!;
      FFAppState().homePageBookPdf = widget.pdf!;
      FFAppState().update(() {});
    });

    if (_isEpub && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await _openEpubWithPlugin();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  Future<void> _openEpubWithPlugin() async {
    final path = widget.pdf?.trim();
    if (path == null || path.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isOpeningEpub = true;
      _epubError = null;
    });

    try {
      final isRemote = path.startsWith('http://') || path.startsWith('https://');
      await EpubReaderService.readBook(
        epubUrl: isRemote ? path : null,
        filePath: isRemote ? null : path,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _epubError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isOpeningEpub = false);
    }
  }

  @override
  void dispose() {
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
          child: _isEpub &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isOpeningEpub) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Opening EPUB reader...',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ] else ...[
                          Text(
                            _epubError ?? 'Open this EPUB in native reader',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _openEpubWithPlugin,
                            child: const Text('Open EPUB Reader'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : custom_widgets.FlutterPdfViewWidget(
                  width: double.infinity,
                  height: double.infinity,
                  filePath: widget.pdf,
                  namePage: widget.name,
                ),
        ),
      ),
    );
  }
}
