import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/pages/home_pages/book_detailspage/book_detailspage_widget.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/services/local_download_service.dart';
import '/services/reading_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'purchase_history_page_model.dart';
export 'purchase_history_page_model.dart';

class _LibraryData {
  _LibraryData({
    required this.purchaseResponse,
    required this.downloads,
    required this.progressMap,
  });

  final ApiCallResponse purchaseResponse;
  final List<LocalDownloadedBook> downloads;
  final Map<String, LocalReadingProgress> progressMap;
}

class _LibraryItem {
  _LibraryItem({
    required this.id,
    required this.name,
    required this.author,
    required this.imageUrl,
    required this.contentType,
    required this.isDownloaded,
    required this.isPurchased,
    required this.isFavorite,
    required this.progressPercent,
  });

  final String id;
  final String name;
  final String author;
  final String imageUrl;
  final String contentType;
  final bool isDownloaded;
  final bool isPurchased;
  final bool isFavorite;
  final double progressPercent;
}

class PurchaseHistoryPageWidget extends StatefulWidget {
  const PurchaseHistoryPageWidget({super.key});

  static String routeName = 'PurchaseHistoryPage';
  static String routePath = '/purchaseHistoryPage';

  @override
  State<PurchaseHistoryPageWidget> createState() =>
      _PurchaseHistoryPageWidgetState();
}

class _PurchaseHistoryPageWidgetState extends State<PurchaseHistoryPageWidget>
    with SingleTickerProviderStateMixin {
  late PurchaseHistoryPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _selectedChipIndex = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PurchaseHistoryPageModel());
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<_LibraryData> _loadLibraryData() async {
    final purchaseResponse = await EbookGroup.userBookPurchaseRecordsApiCall.call(
      userId: FFAppState().userId,
      token: FFAppState().token,
    );
    final downloads = await LocalDownloadService.getAllDownloads();
    final progressMap = await ReadingProgressService.getAllProgress();
    return _LibraryData(
      purchaseResponse: purchaseResponse,
      downloads: downloads.where((e) => e.existsOnDisk).toList(),
      progressMap: progressMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: FutureBuilder<_LibraryData>(
            future: _loadLibraryData(),
            builder: (context, snapshot) {
              Widget bodyContent;

              // Customize what your widget displays when the call is in progress,
              // has an error, or is awaiting the results.
              if (!snapshot.hasData) {
                bodyContent = Center(
                  child: CircularProgressIndicator(
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                );
              } else {
                final data = snapshot.data!;
                final response = data.purchaseResponse;
                final purchaseOk = response.statusCode == 200;
                final purchaseDetails = purchaseOk
                    ? (EbookGroup.userBookPurchaseRecordsApiCall.purchaseDetails(
                            response.jsonBody) ??
                        <dynamic>[])
                    : <dynamic>[];

                final bookIds = purchaseOk
                    ? (EbookGroup.userBookPurchaseRecordsApiCall
                            .bookId(response.jsonBody) ??
                        <String>[])
                    : <String>[];
                final bookNames = purchaseOk
                    ? (EbookGroup.userBookPurchaseRecordsApiCall
                            .bookName(response.jsonBody) ??
                        <String>[])
                    : <String>[];
                final bookImages = purchaseOk
                    ? (EbookGroup.userBookPurchaseRecordsApiCall
                            .bookImage(response.jsonBody) ??
                        <String>[])
                    : <String>[];
                final authorNames = purchaseOk
                    ? (EbookGroup.userBookPurchaseRecordsApiCall
                            .authorName(response.jsonBody) ??
                        <String>[])
                    : <String>[];

                final downloadedById = <String, LocalDownloadedBook>{};
                for (final item in data.downloads) {
                  if (item.bookId.trim().isEmpty) continue;
                  downloadedById[item.bookId] = item;
                }

                final items = <_LibraryItem>[];
                for (var i = 0; i < purchaseDetails.length; i++) {
                  final purchaseItem = purchaseDetails[i];
                  final bookId = (i < bookIds.length ? bookIds[i] : '').trim();
                  if (bookId.isEmpty) continue;
                  final imagePath = i < bookImages.length ? bookImages[i] : '';
                  final imageUrl = imagePath.isNotEmpty
                      ? '${FFAppConstants.bookImagesUrl}$imagePath'
                      : '';
                  final contentType = (getJsonField(
                                purchaseItem,
                                r'''$.bookDetails.type''',
                              ) ??
                          getJsonField(
                            purchaseItem,
                            r'''$.contentType''',
                          ) ??
                          getJsonField(
                            purchaseItem,
                            r'''$.type''',
                          ) ??
                          '')
                      .toString()
                      .toLowerCase();
                  final isFavorite = (getJsonField(
                            purchaseItem,
                            r'''$.bookDetails.isFavorite''',
                          ) ??
                          getJsonField(
                            purchaseItem,
                            r'''$.isFavorite''',
                          ) ??
                          getJsonField(
                            purchaseItem,
                            r'''$.favorite''',
                          ) ??
                          false) ==
                      true;
                  final isDownloaded = downloadedById.containsKey(bookId);
                  final progressValue =
                      data.progressMap[bookId]?.percent ?? 0.0;
                  items.add(
                    _LibraryItem(
                      id: bookId,
                      name:
                          i < bookNames.length && bookNames[i].isNotEmpty
                              ? bookNames[i]
                              : 'Unknown Book',
                      author: i < authorNames.length &&
                              authorNames[i].isNotEmpty
                          ? authorNames[i]
                          : 'Unknown Author',
                      imageUrl: imageUrl,
                      contentType:
                          contentType.isEmpty ? 'ebook' : contentType,
                      isDownloaded: isDownloaded,
                      isPurchased: true,
                      isFavorite: isFavorite,
                      progressPercent: progressValue.clamp(0.0, 100.0),
                    ),
                  );
                }

                for (final downloadItem in data.downloads) {
                  if (downloadItem.bookId.trim().isEmpty) continue;
                  final existing = items
                      .any((element) => element.id == downloadItem.bookId);
                  if (existing) continue;
                  final lowerUrl = downloadItem.remoteUrl.toLowerCase();
                  final contentType = lowerUrl.endsWith('.mp3') ||
                          lowerUrl.endsWith('.m4a') ||
                          lowerUrl.endsWith('.m4b')
                      ? 'audiobook'
                      : 'ebook';
                  final progressValue = data
                          .progressMap[downloadItem.bookId]
                          ?.percent ??
                      0.0;
                  items.add(
                    _LibraryItem(
                      id: downloadItem.bookId,
                      name: downloadItem.name.isNotEmpty
                          ? downloadItem.name
                          : 'Unknown Book',
                      author: downloadItem.author.isNotEmpty
                          ? downloadItem.author
                          : 'Unknown Author',
                      imageUrl: downloadItem.image,
                      contentType: contentType,
                      isDownloaded: true,
                      isPurchased: false,
                      isFavorite: false,
                      progressPercent: progressValue.clamp(0.0, 100.0),
                    ),
                  );
                }

                for (final progressEntry in data.progressMap.values) {
                  if (progressEntry.bookId.trim().isEmpty) continue;
                  if (progressEntry.percent <= 0) continue;
                  final existing = items
                      .any((element) => element.id == progressEntry.bookId);
                  if (existing) continue;
                  final contentType = progressEntry.contentType.isNotEmpty
                      ? progressEntry.contentType.toLowerCase()
                      : 'ebook';
                  items.add(
                    _LibraryItem(
                      id: progressEntry.bookId,
                      name: progressEntry.name.isNotEmpty
                          ? progressEntry.name
                          : 'Unknown Book',
                      author: progressEntry.author.isNotEmpty
                          ? progressEntry.author
                          : 'Unknown Author',
                      imageUrl: progressEntry.imageUrl,
                      contentType: contentType,
                      isDownloaded: false,
                      isPurchased: false,
                      isFavorite: false,
                      progressPercent: progressEntry.percent.clamp(0.0, 100.0),
                    ),
                  );
                }

                final filteredItems = items.where((item) {
                  var passesTab = true;
                  if (_selectedTabIndex == 0) {
                    passesTab =
                        item.contentType.isEmpty || item.contentType == 'ebook';
                  } else if (_selectedTabIndex == 1) {
                    passesTab = item.contentType == 'audiobook';
                  } else if (_selectedTabIndex == 2) {
                    passesTab = item.isFavorite;
                  }

                  var passesChip = true;
                  if (_selectedChipIndex == 1) {
                    passesChip = item.progressPercent >= 100.0;
                  } else if (_selectedChipIndex == 2) {
                    passesChip = item.isDownloaded;
                  } else if (_selectedChipIndex == 3) {
                    passesChip = item.isPurchased;
                  }
                  return passesTab && passesChip;
                }).toList();

                if (filteredItems.isEmpty) {
                  bodyContent = Center(
                    child: Text(
                      'No books found',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  );
                } else {
                  bodyContent = ListView.builder(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                    scrollDirection: Axis.vertical,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            BookDetailspageWidget.routeName,
                            queryParameters: {
                              'name': item.name,
                              'image': item.imageUrl,
                              'id': item.id,
                              'authorName': item.author,
                            }.withoutNulls,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 8.0, 16.0, 8.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 4.0,
                                  color:
                                      FlutterFlowTheme.of(context).shadowColor,
                                  offset: const Offset(0.0, 2.0),
                                )
                              ],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  12.0, 12.0, 12.0, 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: item.imageUrl.isEmpty
                                        ? Container(
                                            width: 64.0,
                                            height: 96.0,
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                            ),
                                          )
                                        : Image.network(
                                            item.imageUrl,
                                            width: 64.0,
                                            height: 96.0,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                Container(
                                              width: 64.0,
                                              height: 96.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                            ),
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              12.0, 0.0, 12.0, 0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  letterSpacing: 0.0,
                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                ),
                                            
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0.0, 4.0, 0.0, 0.0),
                                            child: Text(
                                              item.author,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily:
                                                        'SF Pro Display',
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    letterSpacing: 0.0,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 48.0,
                                    height: 48.0,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: item.progressPercent / 100.0,
                                          strokeWidth: 4.0,
                                          backgroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .alternate,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                        ),
                                        Text(
                                          '${item.progressPercent.toStringAsFixed(0)}%',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                fontFamily: 'SF Pro Display',
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              }

              return Column(
                children: [
                  CustomCenterAppbarWidget(
                    title: 'Library',
                    backIcon: false,
                    addIcon: false,
                    onTapAdd: () async {},
                  ),
                  Container(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    child: Column(
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: FlutterFlowTheme.of(context).primary,
                            unselectedLabelColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            indicatorColor: FlutterFlowTheme.of(context).primary,
                            tabs: const [
                              Tab(text: 'Ebook'),
                              Tab(text: 'Audiobook'),
                              Tab(text: 'Favorites'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 10.0, 16.0, 6.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _selectedChipIndex == 0,
                                  onSelected: (_) => setState(() => _selectedChipIndex = 0),
                                  showCheckmark: false,
                                  labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'SF Pro Display',
                                        color: _selectedChipIndex == 0
                                            ? FlutterFlowTheme.of(context).primary
                                            : FlutterFlowTheme.of(context).secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                  selectedColor:
                                      FlutterFlowTheme.of(context).primary.withOpacity(0.12),
                                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                  padding: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 12.0, 6.0),
                                ),
                                const SizedBox(width: 8.0),
                                ChoiceChip(
                                  label: const Text('Read'),
                                  selected: _selectedChipIndex == 1,
                                  onSelected: (_) => setState(() => _selectedChipIndex = 1),
                                  showCheckmark: false,
                                  labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'SF Pro Display',
                                        color: _selectedChipIndex == 1
                                            ? FlutterFlowTheme.of(context).primary
                                            : FlutterFlowTheme.of(context).secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                  selectedColor:
                                      FlutterFlowTheme.of(context).primary.withOpacity(0.12),
                                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                  padding: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 12.0, 6.0),
                                ),
                                const SizedBox(width: 8.0),
                                ChoiceChip(
                                  label: const Text('Downloaded'),
                                  selected: _selectedChipIndex == 2,
                                  onSelected: (_) => setState(() => _selectedChipIndex = 2),
                                  showCheckmark: false,
                                  labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'SF Pro Display',
                                        color: _selectedChipIndex == 2
                                            ? FlutterFlowTheme.of(context).primary
                                            : FlutterFlowTheme.of(context).secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                  selectedColor:
                                      FlutterFlowTheme.of(context).primary.withOpacity(0.12),
                                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                  padding: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 12.0, 6.0),
                                ),
                                const SizedBox(width: 8.0),
                                ChoiceChip(
                                  label: const Text('Purchased'),
                                  selected: _selectedChipIndex == 3,
                                  onSelected: (_) => setState(() => _selectedChipIndex = 3),
                                  showCheckmark: false,
                                  labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                        fontFamily: 'SF Pro Display',
                                        color: _selectedChipIndex == 3
                                            ? FlutterFlowTheme.of(context).primary
                                            : FlutterFlowTheme.of(context).secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                  selectedColor:
                                      FlutterFlowTheme.of(context).primary.withOpacity(0.12),
                                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                  padding: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 12.0, 6.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: bodyContent,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
