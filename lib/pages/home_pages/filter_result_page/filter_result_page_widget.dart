import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_filter_book/no_filter_book_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'filter_result_page_model.dart';
export 'filter_result_page_model.dart';

class FilterResultPageWidget extends StatefulWidget {
  const FilterResultPageWidget({super.key});

  static String routeName = 'FilterResultPage';
  static String routePath = '/FilterResultPage';

  @override
  State<FilterResultPageWidget> createState() => _FilterResultPageWidgetState();
}

class _FilterResultPageWidgetState extends State<FilterResultPageWidget> {
  late FilterResultPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FilterResultPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: 'Filter',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: (_model.apiRequestCompleter2 ??= Completer<
                                ApiCallResponse>()
                              ..complete(EbookGroup.getFavouriteBookCall.call(
                                userId: FFAppState().userId,
                                token: FFAppState().token,
                              )))
                            .future,
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final containerGetFavouriteBookResponse =
                              snapshot.data!;

                          return Container(
                            decoration: BoxDecoration(),
                            child: FutureBuilder<ApiCallResponse>(
                              future: (_model.apiRequestCompleter1 ??=
                                      Completer<ApiCallResponse>()
                                        ..complete(EbookGroup
                                            .getLatestbooksApiCall
                                            .call(
                                          authorIdList: FFAppState().authorId,
                                          categoryIdList:
                                              FFAppState().categoryId,
                                        )))
                                  .future,
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context).primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final containerGetLatestbooksApiResponse =
                                    snapshot.data!;

                                return Container(
                                  decoration: BoxDecoration(),
                                  child: Builder(
                                    builder: (context) {
                                      if (EbookGroup.getLatestbooksApiCall
                                              .success(
                                            containerGetLatestbooksApiResponse
                                                .jsonBody,
                                          ) ==
                                          2) {
                                        return Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            child: Text(
                                              valueOrDefault<String>(
                                                EbookGroup.getLatestbooksApiCall
                                                    .message(
                                                  containerGetLatestbooksApiResponse
                                                      .jsonBody,
                                                ),
                                                'Message',
                                              ),
                                              textAlign: TextAlign.center,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        fontSize: 18.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        lineHeight: 1.5,
                                                      ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Builder(
                                          builder: (context) {
                                            if (EbookGroup.getLatestbooksApiCall
                                                        .bookDetailsList(
                                                      containerGetLatestbooksApiResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (EbookGroup
                                                        .getLatestbooksApiCall
                                                        .bookDetailsList(
                                                  containerGetLatestbooksApiResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty) {
                                              return RefreshIndicator(
                                                key: Key(
                                                    'RefreshIndicator_d0tm108k'),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                onRefresh: () async {
                                                  safeSetState(() => _model
                                                          .apiRequestCompleter1 =
                                                      null);
                                                  await _model
                                                      .waitForApiRequestCompleted1();
                                                },
                                                child: ListView(
                                                  padding: EdgeInsets.fromLTRB(
                                                    0,
                                                    16.0,
                                                    0,
                                                    16.0,
                                                  ),
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  16.0,
                                                                  0.0,
                                                                  16.0,
                                                                  0.0),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final filterBookList = EbookGroup
                                                                  .getLatestbooksApiCall
                                                                  .bookDetailsList(
                                                                    containerGetLatestbooksApiResponse
                                                                        .jsonBody,
                                                                  )
                                                                  ?.toList() ??
                                                              [];

                                                          return Wrap(
                                                            spacing: 16.0,
                                                            runSpacing: 16.0,
                                                            alignment:
                                                                WrapAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                WrapCrossAlignment
                                                                    .start,
                                                            direction:
                                                                Axis.horizontal,
                                                            runAlignment:
                                                                WrapAlignment
                                                                    .start,
                                                            verticalDirection:
                                                                VerticalDirection
                                                                    .down,
                                                            clipBehavior:
                                                                Clip.none,
                                                            children: List.generate(
                                                                filterBookList
                                                                    .length,
                                                                (filterBookListIndex) {
                                                              final filterBookListItem =
                                                                  filterBookList[
                                                                      filterBookListIndex];
                                                              return wrapWithModel(
                                                                model: _model
                                                                    .mainBookComponentModels
                                                                    .getModel(
                                                                  getJsonField(
                                                                    filterBookListItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  filterBookListIndex,
                                                                ),
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child:
                                                                    MainBookComponentWidget(
                                                                  key: Key(
                                                                    'Keydgb_${getJsonField(
                                                                      filterBookListItem,
                                                                      r'''$.name''',
                                                                    ).toString()}',
                                                                  ),
                                                                  image:
                                                                      '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                    filterBookListItem,
                                                                    r'''$.image''',
                                                                  ).toString()}',
                                                                  bookName:
                                                                      getJsonField(
                                                                    filterBookListItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  authorsName:
                                                                      getJsonField(
                                                                    filterBookListItem,
                                                                    r'''$.author.name''',
                                                                  ).toString(),
                                                                  isFav: functions.checkFavOrNot(
                                                                          EbookGroup.getFavouriteBookCall
                                                                              .favouriteBookDetailsList(
                                                                                containerGetFavouriteBookResponse.jsonBody,
                                                                              )
                                                                              ?.toList(),
                                                                          getJsonField(
                                                                            filterBookListItem,
                                                                            r'''$._id''',
                                                                          ).toString()) ==
                                                                      true,
                                                                  indicator: (filterBookListIndex ==
                                                                          _model
                                                                              .filterIndex) &&
                                                                      (_model.isFiler ==
                                                                          true),
                                                                  isFavAction:
                                                                      () async {
                                                                    if (FFAppState()
                                                                            .isLogin ==
                                                                        true) {
                                                                      _model.isFiler =
                                                                          true;
                                                                      _model.filterIndex =
                                                                          filterBookListIndex;
                                                                      safeSetState(
                                                                          () {});
                                                                      if (functions.checkFavOrNot(
                                                                              EbookGroup.getFavouriteBookCall
                                                                                  .favouriteBookDetailsList(
                                                                                    containerGetFavouriteBookResponse.jsonBody,
                                                                                  )
                                                                                  ?.toList(),
                                                                              getJsonField(
                                                                                filterBookListItem,
                                                                                r'''$._id''',
                                                                              ).toString()) ==
                                                                          true) {
                                                                        _model.getPopularDetete = await EbookGroup
                                                                            .removeFavouritebookCall
                                                                            .call(
                                                                          userId:
                                                                              FFAppState().userId,
                                                                          token:
                                                                              FFAppState().token,
                                                                          bookId:
                                                                              getJsonField(
                                                                            filterBookListItem,
                                                                            r'''$._id''',
                                                                          ).toString(),
                                                                        );

                                                                        safeSetState(() =>
                                                                            _model.apiRequestCompleter2 =
                                                                                null);
                                                                        await _model
                                                                            .waitForApiRequestCompleted2();
                                                                        await actions
                                                                            .showCustomToastBottom(
                                                                          FFAppState()
                                                                              .unFavText,
                                                                        );
                                                                      } else {
                                                                        _model.getPopularAdd = await EbookGroup
                                                                            .addFavouriteBookApiCall
                                                                            .call(
                                                                          userId:
                                                                              FFAppState().userId,
                                                                          token:
                                                                              FFAppState().token,
                                                                          bookId:
                                                                              getJsonField(
                                                                            filterBookListItem,
                                                                            r'''$._id''',
                                                                          ).toString(),
                                                                        );

                                                                        safeSetState(() =>
                                                                            _model.apiRequestCompleter2 =
                                                                                null);
                                                                        await _model
                                                                            .waitForApiRequestCompleted2();
                                                                        await actions
                                                                            .showCustomToastBottom(
                                                                          FFAppState()
                                                                              .favText,
                                                                        );
                                                                      }

                                                                      FFAppState()
                                                                          .clearGetFavouriteBookCacheCache();
                                                                      _model.isFiler =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});
                                                                    } else {
                                                                      FFAppState()
                                                                              .favChange =
                                                                          true;
                                                                      FFAppState()
                                                                              .bookId =
                                                                          getJsonField(
                                                                        filterBookListItem,
                                                                        r'''$._id''',
                                                                      ).toString();
                                                                      FFAppState()
                                                                          .update(
                                                                              () {});

                                                                      context.pushNamed(
                                                                          SignInPageWidget
                                                                              .routeName);
                                                                    }

                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  isMainTap:
                                                                      () async {
                                                                    context
                                                                        .pushNamed(
                                                                      BookDetailspageWidget
                                                                          .routeName,
                                                                      queryParameters:
                                                                          {
                                                                        'name':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            filterBookListItem,
                                                                            r'''$.name''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'image':
                                                                            serializeParam(
                                                                          '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                            filterBookListItem,
                                                                            r'''$.image''',
                                                                          ).toString()}',
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'id':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            filterBookListItem,
                                                                            r'''$._id''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                      }.withoutNulls,
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            }),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              return wrapWithModel(
                                                model: _model.noFilterBookModel,
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: NoFilterBookWidget(),
                                              );
                                            }
                                          },
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
