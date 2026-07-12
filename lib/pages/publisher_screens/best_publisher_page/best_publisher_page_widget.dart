import 'package:a_i_ebook_app/pages/home_pages/about_publisher_page/about_publisher_page_widget.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_author_yet/no_author_yet_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'best_publisher_page_model.dart';
export 'best_publisher_page_model.dart';

import '/flutter_flow/internationalization.dart';
class BestPublisherPageWidget extends StatefulWidget {
  const BestPublisherPageWidget({super.key});

  static String routeName = 'BestPublisherPage';
  static String routePath = '/bestPublisherPage';

  @override
  State<BestPublisherPageWidget> createState() =>
      _BestPublisherPageWidgetState();
}

class _BestPublisherPageWidgetState extends State<BestPublisherPageWidget> {
  late BestPublisherPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _publishers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 24;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BestPublisherPageModel());
    _scrollController.addListener(_onScroll);
    _loadMorePublishers(isFirstLoad: true);
  }

  void _onScroll() {
    debugPrint('Publishers Scroll: pixels=${_scrollController.position.pixels}, max=${_scrollController.position.maxScrollExtent}');
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePublishers();
    }
  }

  Future<void> _loadMorePublishers({bool isFirstLoad = false}) async {
    if (_isLoading || (!_hasMore && !isFirstLoad)) return;
    debugPrint('Publishers Load: isFirstLoad=$isFirstLoad, offset=$_offset, limit=$_limit, hasMore=$_hasMore');
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await EbookGroup.getpublishersApiCall.call(
        token: FFAppState().token,
        limit: _limit,
        offset: _offset,
      );
      final newPublishers =
          EbookGroup.getpublishersApiCall.publisherDetailsList(res.jsonBody) ??
              [];
      debugPrint('Publishers API Result: count=${newPublishers.length}');
      if (newPublishers.length < _limit) {
        _hasMore = false;
      }
      setState(() {
        if (isFirstLoad) {
          _publishers.clear();
          _offset = 0;
        }
        final existingIds = _publishers
            .map((p) => getJsonField(p, r'''$._id''')?.toString())
            .where((id) => id != null)
            .toSet();
        for (final publisher in newPublishers) {
          final publisherId = getJsonField(publisher, r'''$._id''')?.toString();
          if (publisherId == null || !existingIds.contains(publisherId)) {
            _publishers.add(publisher);
            if (publisherId != null) {
              existingIds.add(publisherId);
            }
          }
        }
        _offset += newPublishers.length;
      });

      // If the content is not scrollable yet but we have more, load more automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasMore && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0) {
          debugPrint('Publishers screen not filled, auto loading next page');
          _loadMorePublishers();
        }
      });
    } catch (e) {
      debugPrint('Error loading publishers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.singleAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: SingleAppbarWidget(
                  title: FFLocalizations.of(context).getVariableText(enText: 'Best publisher', bnText: 'সেরা প্রকাশক'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: _publishers.isEmpty && !_isLoading
                            ? wrapWithModel(
                                model: _model.noAuthorYetModel,
                                updateCallback: () => safeSetState(() {}),
                                child: NoAuthorYetWidget(),
                              )
                            : RefreshIndicator(
                                key: const Key('RefreshIndicator_3d7e1s78'),
                                color: FlutterFlowTheme.of(context).primary,
                                onRefresh: () async {
                                  setState(() {
                                    _offset = 0;
                                    _hasMore = true;
                                  });
                                  await _loadMorePublishers(isFirstLoad: true);
                                },
                                child: ListView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 16.0),
                                  scrollDirection: Axis.vertical,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                      child: Wrap(
                                        spacing: 16.0,
                                        runSpacing: 16.0,
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment: WrapCrossAlignment.start,
                                        direction: Axis.horizontal,
                                        runAlignment: WrapAlignment.start,
                                        verticalDirection: VerticalDirection.down,
                                        clipBehavior: Clip.none,
                                        children: [
                                          ...List.generate(
                                            _publishers.length,
                                            (publisherDetailsListIndex) {
                                              final publisherDetailsListItem = _publishers[publisherDetailsListIndex];
                                              return wrapWithModel(
                                                model: _model.categoryComponentModels.getModel(
                                                  getJsonField(
                                                    publisherDetailsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  publisherDetailsListIndex,
                                                ),
                                                updateCallback: () => safeSetState(() {}),
                                                child: CategoryComponentWidget(
                                                  key: Key(
                                                    'Keyhj5_${getJsonField(
                                                      publisherDetailsListItem,
                                                      r'''$.name''',
                                                    ).toString()}',
                                                  ),
                                                  icon: '${FFAppConstants.imageUrl}${getJsonField(
                                                    publisherDetailsListItem,
                                                    r'''$.image''',
                                                  ).toString()}',
                                                  name: getJsonField(
                                                    publisherDetailsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  isSmall: true,
                                                  onMainTap: () async {
                                                    context.pushNamed(
                                                      AboutPublisherPageWidget.routeName,
                                                      queryParameters: {
                                                        'name': serializeParam(
                                                          getJsonField(
                                                            publisherDetailsListItem,
                                                            r'''$.name''',
                                                          ).toString(),
                                                          ParamType.String,
                                                        ),
                                                        'publisherImage': serializeParam(
                                                          '${FFAppConstants.imageUrl}${getJsonField(
                                                            publisherDetailsListItem,
                                                            r'''$.image''',
                                                          ).toString()}',
                                                          ParamType.String,
                                                        ),
                                                        'publisherId': serializeParam(
                                                          getJsonField(
                                                            publisherDetailsListItem,
                                                            r'''$._id''',
                                                          ).toString(),
                                                          ParamType.String,
                                                        ),
                                                      }.withoutNulls,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          if (_isLoading)
                                            Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: SizedBox(
                                                  width: 32.0,
                                                  height: 32.0,
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      FlutterFlowTheme.of(context).primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      );
                    } else {
                      return Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Lottie.asset(
                          'assets/jsons/No_Wifi.json',
                          width: 150.0,
                          height: 150.0,
                          fit: BoxFit.contain,
                          animate: true,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
