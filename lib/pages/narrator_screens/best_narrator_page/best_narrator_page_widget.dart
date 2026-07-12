import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_narrator_yet/no_narrator_yet_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'best_narrator_page_model.dart';
export 'best_narrator_page_model.dart';

import '/flutter_flow/internationalization.dart';
class BestNarratorPageWidget extends StatefulWidget {
  const BestNarratorPageWidget({super.key});

  static String routeName = 'BestNarratorPage';
  static String routePath = '/bestNarratorPage';

  @override
  State<BestNarratorPageWidget> createState() => _BestNarratorPageWidgetState();
}

class _BestNarratorPageWidgetState extends State<BestNarratorPageWidget> {
  late BestNarratorPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _narrators = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 24;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BestNarratorPageModel());
    _scrollController.addListener(_onScroll);
    _loadMoreNarrators(isFirstLoad: true);
  }

  void _onScroll() {
    debugPrint('Narrators Scroll: pixels=${_scrollController.position.pixels}, max=${_scrollController.position.maxScrollExtent}');
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNarrators();
    }
  }

  Future<void> _loadMoreNarrators({bool isFirstLoad = false}) async {
    if (_isLoading || (!_hasMore && !isFirstLoad)) return;
    debugPrint('Narrators Load: isFirstLoad=$isFirstLoad, offset=$_offset, limit=$_limit, hasMore=$_hasMore');
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await EbookGroup.getnarratorsApiCall.call(
        token: FFAppState().token,
        limit: _limit,
        offset: _offset,
      );
      final newNarrators =
          EbookGroup.getnarratorsApiCall.narratorDetailsList(res.jsonBody) ??
              [];
      debugPrint('Narrators API Result: count=${newNarrators.length}');
      if (newNarrators.length < _limit) {
        _hasMore = false;
      }
      setState(() {
        if (isFirstLoad) {
          _narrators.clear();
          _offset = 0;
        }
        final existingIds = _narrators
            .map((n) => getJsonField(n, r'''$._id''')?.toString())
            .where((id) => id != null)
            .toSet();
        for (final narrator in newNarrators) {
          final narratorId = getJsonField(narrator, r'''$._id''')?.toString();
          if (narratorId == null || !existingIds.contains(narratorId)) {
            _narrators.add(narrator);
            if (narratorId != null) {
              existingIds.add(narratorId);
            }
          }
        }
        _offset += newNarrators.length;
      });

      // If the content is not scrollable yet but we have more, load more automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasMore && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0) {
          debugPrint('Narrators screen not filled, auto loading next page');
          _loadMoreNarrators();
        }
      });
    } catch (e) {
      debugPrint('Error loading narrators: $e');
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
                  title: FFLocalizations.of(context).getVariableText(enText: 'Best narrator', bnText: 'সেরা ভয়েস আর্টিস্ট'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: _narrators.isEmpty && !_isLoading
                            ? wrapWithModel(
                                model: _model.noNarratorYetModel,
                                updateCallback: () => safeSetState(() {}),
                                child: NoNarratorYetWidget(),
                              )
                            : RefreshIndicator(
                                key: const Key('RefreshIndicator_k3vczp9b'),
                                color: FlutterFlowTheme.of(context).primary,
                                onRefresh: () async {
                                  setState(() {
                                    _offset = 0;
                                    _hasMore = true;
                                  });
                                  await _loadMoreNarrators(isFirstLoad: true);
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
                                            _narrators.length,
                                            (narratorDetailsListIndex) {
                                              final narratorDetailsListItem = _narrators[narratorDetailsListIndex];
                                              return wrapWithModel(
                                                model: _model.categoryComponentModels.getModel(
                                                  getJsonField(
                                                    narratorDetailsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  narratorDetailsListIndex,
                                                ),
                                                updateCallback: () => safeSetState(() {}),
                                                child: CategoryComponentWidget(
                                                  key: Key(
                                                    'Keynarr_${getJsonField(
                                                      narratorDetailsListItem,
                                                      r'''$.name''',
                                                    ).toString()}',
                                                  ),
                                                  icon: '${FFAppConstants.imageUrl}${getJsonField(
                                                    narratorDetailsListItem,
                                                    r'''$.image''',
                                                  ).toString()}',
                                                  name: getJsonField(
                                                    narratorDetailsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  isSmall: true,
                                                  onMainTap: () async {
                                                    context.pushNamed(
                                                      AboutNarratorPageWidget.routeName,
                                                      queryParameters: {
                                                        'name': serializeParam(
                                                          getJsonField(
                                                            narratorDetailsListItem,
                                                            r'''$.name''',
                                                          ).toString(),
                                                          ParamType.String,
                                                        ),
                                                        'narratorImage': serializeParam(
                                                          '${FFAppConstants.imageUrl}${getJsonField(
                                                            narratorDetailsListItem,
                                                            r'''$.image''',
                                                          ).toString()}',
                                                          ParamType.String,
                                                        ),
                                                        'narratorId': serializeParam(
                                                          getJsonField(
                                                            narratorDetailsListItem,
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
