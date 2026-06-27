import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/pages/home_pages/book_detailspage/book_detailspage_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/local_download_service.dart';
import '/services/reading_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'purchase_history_page_model.dart';
export 'purchase_history_page_model.dart';

class _LibraryData {
  _LibraryData({
    required this.purchaseResponse,
    required this.favoriteResponse,
    required this.downloads,
    required this.progressMap,
    this.continueReading = const [],
    this.continueListening = const [],
  });

  final ApiCallResponse purchaseResponse;
  final ApiCallResponse favoriteResponse;
  final List<LocalDownloadedBook> downloads;
  final Map<String, LocalReadingProgress> progressMap;
  /// Items from the homepage API "continueReading" list (ebooks in progress).
  final List<dynamic> continueReading;
  /// Items from the homepage API "continueListening" list (audiobooks in progress).
  final List<dynamic> continueListening;
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
  final int initialTabIndex;
  const PurchaseHistoryPageWidget({super.key, this.initialTabIndex = 0});

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
  late int _selectedTabIndex;
  int _selectedChipIndex = 0;

  String _normalizeContentType(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('audio')) return 'audiobook';
    if (value.contains('hard') || value.contains('print')) return 'hardcopy';
    return 'ebook';
  }

  String _typeLabel(String contentType) {
    switch (_normalizeContentType(contentType)) {
      case 'audiobook':
        return 'Audiobook';
      case 'hardcopy':
        return 'Hardcopy';
      default:
        return 'Ebook';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _model = createModel(context, () => PurchaseHistoryPageModel());
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
    final futures = await Future.wait([
      EbookGroup.userBookPurchaseRecordsApiCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      ),
      EbookGroup.getFavouriteBookCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      ),
      LocalDownloadService.getAllDownloads(),
      ReadingProgressService.getAllProgress(),
      // Fetch homepage data for continue reading/listening (best-effort)
      if (FFAppState().isLogin)
        EbookGroup.getHomepageApiCall
            .call(token: FFAppState().token)
            .catchError((_) => ApiCallResponse({}, {}, 0)),
    ]);

    final homeJson =
        futures.length > 4 ? (futures[4] as ApiCallResponse).jsonBody : null;
    final continueReading =
        EbookGroup.getHomepageApiCall.continueReadingList(homeJson)?.toList() ??
            [];
    final continueListening =
        EbookGroup.getHomepageApiCall
                .continueListeningList(homeJson)
                ?.toList() ??
            [];

    return _LibraryData(
      purchaseResponse: futures[0] as ApiCallResponse,
      favoriteResponse: futures[1] as ApiCallResponse,
      downloads: (futures[2] as List<LocalDownloadedBook>)
          .where((e) => e.existsOnDisk)
          .toList(),
      progressMap: futures[3] as Map<String, LocalReadingProgress>,
      continueReading: continueReading,
      continueListening: continueListening,
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
              Widget bodyContent = const SizedBox.shrink();

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
                  final imageUrl = imagePath.isEmpty
                      ? ''
                      : (imagePath.startsWith('http')
                          ? imagePath
                          : '${FFAppConstants.bookImagesUrl}$imagePath');
                  final contentType = (getJsonField(
                                purchaseItem,
                                r'''$.format''',
                              ) ??
                          getJsonField(
                            purchaseItem,
                            r'''$.contentType''',
                          ) ??
                          getJsonField(
                            purchaseItem,
                            r'''$.type''',
                          ) ??
                          getJsonField(
                                purchaseItem,
                                r'''$.bookDetails.type''',
                              ) ??
                          '')
                      .toString()
                      .toLowerCase();
                  final normalizedType = _normalizeContentType(contentType);
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
                      contentType: normalizedType,
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
                      contentType: _normalizeContentType(contentType),
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
                      contentType: _normalizeContentType(contentType),
                      isDownloaded: false,
                      isPurchased: false,
                      isFavorite: false,
                      progressPercent: progressEntry.percent.clamp(0.0, 100.0),
                    ),
                  );
                }

                final favResponse = data.favoriteResponse;
                final favOk = favResponse.succeeded;
                final favDetails = favOk
                    ? (EbookGroup.getFavouriteBookCall
                            .favouriteBookDetailsList(favResponse.jsonBody) ??
                        [])
                    : [];

                for (final favItem in favDetails) {
                  final bookId = getJsonField(favItem, r'''$.bookDetails._id''')
                      .toString();
                  if (bookId.isEmpty) continue;
                  final existingIdx =
                      items.indexWhere((element) => element.id == bookId);
                  if (existingIdx != -1) {
                    final old = items[existingIdx];
                    items[existingIdx] = _LibraryItem(
                      id: old.id,
                      name: old.name,
                      author: old.author,
                      imageUrl: old.imageUrl,
                      contentType: old.contentType,
                      isDownloaded: old.isDownloaded,
                      isPurchased: old.isPurchased,
                      isFavorite: true,
                      progressPercent: old.progressPercent,
                    );
                  } else {
                    final name =
                        getJsonField(favItem, r'''$.bookDetails.name''')
                            .toString();
                    final author = getJsonField(
                            favItem, r'''$.bookDetails.author.name''')
                        .toString();
                    final image =
                        getJsonField(favItem, r'''$.bookDetails.image''')
                            .toString();
                    final type =
                        getJsonField(favItem, r'''$.bookDetails.type''')
                            .toString();
                    items.add(
                      _LibraryItem(
                        id: bookId,
                        name: name.isNotEmpty ? name : 'Unknown Book',
                        author: author.isNotEmpty ? author : 'Unknown Author',
                        imageUrl: image.isEmpty
                            ? ''
                            : (image.startsWith('http')
                                ? image
                                : '${FFAppConstants.bookImagesUrl}$image'),
                        contentType: _normalizeContentType(type),
                        isDownloaded: downloadedById.containsKey(bookId),
                        isPurchased: false,
                        isFavorite: true,
                        progressPercent:
                            data.progressMap[bookId]?.percent ?? 0.0,
                      ),
                    );
                  }
                }

                // ── When "Read" chip is active, show API-based Continue sections ──
                if (_selectedChipIndex == 1) {
                  final isEbookTab = _selectedTabIndex == 0;
                  final isAudioTab = _selectedTabIndex == 1;
                  final isFavTab = _selectedTabIndex == 2;

                  List<dynamic> continueItems = [];
                  String sectionLabel = '';
                  bool isAudio = false;

                  if (isEbookTab) {
                    continueItems = data.continueReading;
                    sectionLabel = 'Continue Reading';
                    isAudio = false;
                  } else if (isAudioTab) {
                    continueItems = data.continueListening;
                    sectionLabel = 'Continue Listening';
                    isAudio = true;
                  } else if (isFavTab) {
                    // For favorites tab, show favorite books with any progress
                    final favItems = items.where((item) =>
                        item.isFavorite && item.progressPercent > 0).toList();
                    if (favItems.isEmpty) {
                      bodyContent = Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 52,
                                color: FlutterFlowTheme.of(context).secondaryText),
                            const SizedBox(height: 12),
                            Text(
                              'No favourites in progress',
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                          ],
                        ),
                      );
                    } else {
                      bodyContent = ListView.builder(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                        itemCount: favItems.length,
                        itemBuilder: (context, index) =>
                            _buildLibraryBookTile(favItems[index]),
                      );
                    }
                  }

                  // Build continue reading/listening section for ebook and audiobook tabs
                  if (isEbookTab || isAudioTab) {
                    if (continueItems.isEmpty) {
                      bodyContent = Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAudio
                                  ? Icons.headphones_rounded
                                  : Icons.menu_book_rounded,
                              size: 52,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isAudio
                                  ? 'No audiobooks in progress'
                                  : 'No ebooks in progress',
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAudio
                                  ? 'Start listening to see your progress here'
                                  : 'Start reading to see your progress here',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else {
                      bodyContent = ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              sectionLabel,
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                          ...continueItems.map((item) {
                            final bookData =
                                item['book'] as Map<String, dynamic>? ?? {};
                            final bookId =
                                bookData['_id']?.toString() ?? '';
                            final bookName =
                                bookData['name']?.toString() ?? '';
                            final authorRaw = bookData['author'];
                            final author = authorRaw is Map
                                ? (authorRaw['name']?.toString() ?? '')
                                : authorRaw?.toString() ?? '';
                            final imageRaw =
                                bookData['image']?.toString() ?? '';
                            final coverUrl = imageRaw.isEmpty
                                ? ''
                                : (imageRaw.startsWith('http')
                                    ? imageRaw
                                    : '${FFAppConstants.bookImagesUrl}$imageRaw');

                            double progress = 0.0;
                            String progressLabel = '';
                            if (isAudio) {
                              final pct =
                                  (item['percentage'] as num?)?.toDouble() ??
                                      0.0;
                              final pos =
                                  (item['current_position'] as num?)?.toInt() ??
                                      0;
                              final total =
                                  (item['total_duration'] as num?)?.toInt() ?? 0;
                              progress = (pct / 100.0).clamp(0.0, 1.0);
                              if (total > 0) {
                                final posMins = pos ~/ 60;
                                final totMins = total ~/ 60;
                                progressLabel = '$posMins min / $totMins min';
                              } else {
                                progressLabel =
                                    '${pct.toStringAsFixed(0)}% listened';
                              }
                            } else {
                              final pct =
                                  (item['percentage'] as num?)?.toDouble() ??
                                      0.0;
                              final cur =
                                  (item['current_page'] as num?)?.toInt() ?? 0;
                              final tot =
                                  (item['total_pages'] as num?)?.toInt() ?? 0;
                              final isPercentBased = tot == 100;
                              progress = (pct / 100.0).clamp(0.0, 1.0);
                              progressLabel = isPercentBased
                                  ? '${pct.toStringAsFixed(0)}% read'
                                  : 'Page $cur of $tot';
                            }

                            return _buildLibraryContinueCard(
                              bookId: bookId,
                              bookName: bookName,
                              author: author,
                              coverUrl: coverUrl,
                              progress: progress,
                              progressLabel: progressLabel,
                              isAudio: isAudio,
                            );
                          }).toList(),
                        ],
                      );
                    }
                  }
                } else {
                  // ── Normal chip filter (All, Downloaded, Purchased) ──────────────
                  final filteredItems = items.where((item) {
                    final itemType = _normalizeContentType(item.contentType);
                    var passesTab = true;
                    if (_selectedTabIndex == 0) {
                      passesTab = itemType == 'ebook';
                    } else if (_selectedTabIndex == 1) {
                      passesTab = itemType == 'audiobook';
                    } else if (_selectedTabIndex == 2) {
                      passesTab = item.isFavorite;
                    }

                    var passesChip = true;
                    if (_selectedChipIndex == 2) {
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
                      itemBuilder: (context, index) =>
                          _buildLibraryBookTile(filteredItems[index]),
                    );
                  }
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
  // ─────────────────────────────────────────────────────────────────────
  // Helper: standard library book tile (used for All, Downloaded, Purchased)
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildLibraryBookTile(_LibraryItem item) {
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
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: [
              BoxShadow(
                blurRadius: 4.0,
                color: FlutterFlowTheme.of(context).shadowColor,
                offset: const Offset(0.0, 2.0),
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: item.imageUrl.isEmpty
                      ? Container(
                          width: 64.0,
                          height: 96.0,
                          color: FlutterFlowTheme.of(context).alternate,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                        )
                      : Image.network(
                          item.imageUrl,
                          width: 64.0,
                          height: 96.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 64.0,
                            height: 96.0,
                            color: FlutterFlowTheme.of(context).alternate,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        12.0, 0.0, 12.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 4.0, 0.0, 0.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.author,
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 3.0,
                                ),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  _typeLabel(item.contentType),
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color:
                                            FlutterFlowTheme.of(context).primary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                            ],
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
                            FlutterFlowTheme.of(context).alternate,
                        color: FlutterFlowTheme.of(context).primary,
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
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helper: resume card for Continue Reading / Continue Listening sections
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildLibraryContinueCard({
    required String bookId,
    required String bookName,
    required String author,
    required String coverUrl,
    required double progress,
    required String progressLabel,
    required bool isAudio,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final typeIcon = isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded;
    final subtitleText = author.isNotEmpty
        ? '$author \u2022 ${isAudio ? 'Audiobook' : 'eBook'}'
        : (isAudio ? 'Audiobook' : 'eBook');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.pushNamed(
            BookDetailspageWidget.routeName,
            queryParameters: {
              'name': bookName,
              'image': coverUrl,
              'id': bookId,
              'authorName': author,
            }.withoutNulls,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                blurRadius: 4.0,
                color: FlutterFlowTheme.of(context).shadowColor,
                offset: const Offset(0.0, 2.0),
              )
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              // ── Cover ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: coverUrl.isEmpty
                        ? Container(
                            width: 60,
                            height: 80,
                            color: FlutterFlowTheme.of(context).alternate,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 60,
                              height: 80,
                              color: FlutterFlowTheme.of(context).alternate,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primaryText
                            .withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        typeIcon,
                        size: 12,
                        color: FlutterFlowTheme.of(context).primaryBackground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // ── Text + progress ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 12,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progressLabel,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 11,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: safeProgress,
                        minHeight: 5,
                        backgroundColor: FlutterFlowTheme.of(context)
                            .primaryText
                            .withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 10),
              // // ── Continue button ──
              // Container(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              //   decoration: BoxDecoration(
              //     color: FlutterFlowTheme.of(context).primary,
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: Text(
              //     'Continue',
              //     style: TextStyle(
              //       fontFamily: 'SF Pro Display',
              //       fontSize: 12,
              //       fontWeight: FontWeight.w700,
              //       color: Colors.white,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
