import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/empty_components/no_download_yet/no_download_yet_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import '/services/local_download_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'download_page_model.dart';
export 'download_page_model.dart';

class DownloadPageWidget extends StatefulWidget {
  const DownloadPageWidget({super.key});

  static String routeName = 'DownloadPage';
  static String routePath = '/downloadPage';

  @override
  State<DownloadPageWidget> createState() => _DownloadPageWidgetState();
}

class _DownloadPageWidgetState extends State<DownloadPageWidget> {
  late DownloadPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<LocalDownloadedBook> _downloads = [];
  final Set<String> _deletingBookIds = <String>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DownloadPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDownloads();
    });
  }

  Future<void> _loadDownloads() async {
    final items = await LocalDownloadService.getAllDownloads();
    if (!mounted) return;
    safeSetState(() {
      _downloads = items.where((e) => e.existsOnDisk).toList();
      _isLoading = false;
    });
  }

  Future<void> _openDownloadedBook(LocalDownloadedBook item) async {
    if (!item.existsOnDisk) {
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'File not found on device', bnText: 'ডিভাইসে ফাইলটি পাওয়া যায়নি'));
      await _loadDownloads();
      return;
    }

    context.pushNamed(
      ReadBookCustomPageWidget.routeName,
      queryParameters: {
        'pdf': serializeParam(item.localPath, ParamType.String),
        'id': serializeParam(item.bookId, ParamType.String),
        'name': serializeParam(item.name, ParamType.String),
        'author': serializeParam(item.author, ParamType.String),
        'image': serializeParam(item.image, ParamType.String),
      }.withoutNulls,
    );
  }

  Future<void> _deleteDownloadedBook(LocalDownloadedBook item) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(FFLocalizations.of(context).getVariableText(enText: 'Delete download', bnText: 'ডাউনলোড মুছুন')),
            content: Text(FFLocalizations.of(context).getVariableText(enText: 'Remove "${item.name}" from this device?', bnText: '"${item.name}" এই ডিভাইস থেকে মুছে দেবেন?')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(FFLocalizations.of(context).getVariableText(enText: 'Cancel', bnText: 'বাতিল করুন')),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  FFLocalizations.of(context).getVariableText(enText: 'Delete', bnText: 'মুছুন'),
                  style: TextStyle(
                    color: FlutterFlowTheme.of(dialogContext).error,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    safeSetState(() {
      _deletingBookIds.add(item.bookId);
    });

    try {
      await LocalDownloadService.deleteDownloadByBookId(item.bookId);
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Download deleted', bnText: 'ডাউনলোড মুছে ফেলা হয়েছে'));
      await _loadDownloads();
    } catch (_) {
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to delete download', bnText: 'ডাউনলোড মুছতে ব্যর্থ হয়েছে'));
      if (!mounted) return;
      safeSetState(() {
        _deletingBookIds.remove(item.bookId);
      });
      return;
    }

    if (!mounted) return;
    safeSetState(() {
      _deletingBookIds.remove(item.bookId);
    });
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: FFLocalizations.of(context).getVariableText(enText: 'Download', bnText: 'ডাউনলোড'),
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        ),
                      )
                    : _downloads.isEmpty
                        ? wrapWithModel(
                            model: _model.noDownloadYetModel,
                            updateCallback: () => safeSetState(() {}),
                            child: NoDownloadYetWidget(),
                          )
                        : RefreshIndicator(
                            color: FlutterFlowTheme.of(context).primary,
                            onRefresh: _loadDownloads,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemBuilder: (context, index) {
                                final item = _downloads[index];
                                final isDeleting =
                                    _deletingBookIds.contains(item.bookId);
                                return InkWell(
                                  onTap: isDeleting
                                      ? null
                                      : () => _openDownloadedBook(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: FlutterFlowTheme.of(context)
                                              .shadowColor,
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: item.image,
                                            width: 64,
                                            height: 92,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, error, stack) =>
                                                    Image.asset(
                                              'assets/images/error_image.png',
                                              width: 64,
                                              height: 92,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.author.isEmpty
                                                    ? FFLocalizations.of(context).getVariableText(enText: 'Unknown author', bnText: 'অজ্ঞাত লেখক')
                                                    : item.author,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 13,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                        ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.download_done_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    FFLocalizations.of(context).getVariableText(enText: 'Downloaded', bnText: 'ডাউনলোড হয়েছে'),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        isDeleting
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                  ),
                                                ),
                                              )
                                            : PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  size: 20,
                                                ),
                                                onSelected: (value) async {
                                                  if (value == 'delete') {
                                                    await _deleteDownloadedBook(
                                                        item);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(FFLocalizations.of(context).getVariableText(enText: 'Delete', bnText: 'মুছুন')),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemCount: _downloads.length,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
