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
import 'best_author_page_model.dart';
export 'best_author_page_model.dart';

import '/flutter_flow/internationalization.dart';
class BestAuthorPageWidget extends StatefulWidget {
  const BestAuthorPageWidget({super.key});

  static String routeName = 'BestAuthorPage';
  static String routePath = '/bestAuthorPage';

  @override
  State<BestAuthorPageWidget> createState() => _BestAuthorPageWidgetState();
}

class _BestAuthorPageWidgetState extends State<BestAuthorPageWidget> {
  late BestAuthorPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _authors = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 24;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BestAuthorPageModel());
    _scrollController.addListener(_onScroll);
    _loadMoreAuthors(isFirstLoad: true);
  }

  void _onScroll() {
    debugPrint('Authors Scroll: pixels=${_scrollController.position.pixels}, max=${_scrollController.position.maxScrollExtent}');
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreAuthors();
    }
  }

  Future<void> _loadMoreAuthors({bool isFirstLoad = false}) async {
    if (_isLoading || (!_hasMore && !isFirstLoad)) return;
    debugPrint('Authors Load: isFirstLoad=$isFirstLoad, offset=$_offset, limit=$_limit, hasMore=$_hasMore');
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await EbookGroup.getauthorsApiCall.call(
        token: FFAppState().token,
        limit: _limit,
        offset: _offset,
      );
      final newAuthors =
          EbookGroup.getauthorsApiCall.authorDetailsList(res.jsonBody) ??
              [];
      debugPrint('Authors API Result: count=${newAuthors.length}');
      if (newAuthors.length < _limit) {
        _hasMore = false;
      }
      setState(() {
        if (isFirstLoad) {
          _authors.clear();
          _offset = 0;
        }
        final existingIds = _authors
            .map((a) => getJsonField(a, r'''$._id''')?.toString())
            .where((id) => id != null)
            .toSet();
        for (final author in newAuthors) {
          final authorId = getJsonField(author, r'''$._id''')?.toString();
          if (authorId == null || !existingIds.contains(authorId)) {
            _authors.add(author);
            if (authorId != null) {
              existingIds.add(authorId);
            }
          }
        }
        _offset += newAuthors.length;
      });

      // If the content is not scrollable yet but we have more, load more automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasMore && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0) {
          debugPrint('Authors screen not filled, auto loading next page');
          _loadMoreAuthors();
        }
      });
    } catch (e) {
      debugPrint('Error loading authors: $e');
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
                  title: FFLocalizations.of(context).getVariableText(enText: 'Best author', bnText: 'সেরা লেখক'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: _authors.isEmpty && !_isLoading
                            ? wrapWithModel(
                                model: _model.noAuthorYetModel,
                                updateCallback: () => safeSetState(() {}),
                                child: NoAuthorYetWidget(),
                              )
                            : RefreshIndicator(
                                key: const Key('RefreshIndicator_3d7e1s76'),
                                color: FlutterFlowTheme.of(context).primary,
                                onRefresh: () async {
                                  setState(() {
                                    _offset = 0;
                                    _hasMore = true;
                                  });
                                  await _loadMoreAuthors(isFirstLoad: true);
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
                                            _authors.length,
                                            (authorDetailsListIndex) {
                                              final authorDetailsListItem = _authors[authorDetailsListIndex];
                                              return wrapWithModel(
                                                model: _model.categoryComponentModels.getModel(
                                                  getJsonField(
                                                    authorDetailsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  authorDetailsListIndex,
                                                ),
                                                updateCallback: () => safeSetState(() {}),
                                                child: CategoryComponentWidget(
                                                  key: Key(
                                                    'Keyhj4_${getJsonField(
                                                      authorDetailsListItem,
                                                      r'''$.name''',
                                                    ).toString()}',
                                                  ),
                                                  icon: '${FFAppConstants.imageUrl}${getJsonField(
                                                    authorDetailsListItem,
                                                    r'''$.image''',
                                                  ).toString()}',
                                                  name: getJsonField(
                                                    authorDetailsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  isSmall: true,
                                                  onMainTap: () async {
                                                    context.pushNamed(
                                                      AboutAuthorPageWidget.routeName,
                                                      queryParameters: {
                                                        'name': serializeParam(
                                                          getJsonField(
                                                            authorDetailsListItem,
                                                            r'''$.name''',
                                                          ).toString(),
                                                          ParamType.String,
                                                        ),
                                                        'authorImage': serializeParam(
                                                          '${FFAppConstants.imageUrl}${getJsonField(
                                                            authorDetailsListItem,
                                                            r'''$.image''',
                                                          ).toString()}',
                                                          ParamType.String,
                                                        ),
                                                        'authorId': serializeParam(
                                                          getJsonField(
                                                            authorDetailsListItem,
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
