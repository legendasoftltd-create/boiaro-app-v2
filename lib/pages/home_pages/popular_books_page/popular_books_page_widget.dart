import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/empty_components/no_popular_book/no_popular_book_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'popular_books_page_model.dart';
export 'popular_books_page_model.dart';

class PopularBooksPageWidget extends StatefulWidget {
  const PopularBooksPageWidget({super.key});

  static String routeName = 'PopularBooksPage';
  static String routePath = '/popularBooksPage';

  @override
  State<PopularBooksPageWidget> createState() => _PopularBooksPageWidgetState();
}

class _PopularBooksPageWidgetState extends State<PopularBooksPageWidget> {
  late PopularBooksPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PopularBooksPageModel());

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
                  title: 'Popular books',
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
                        future: FFAppState()
                            .getFavouriteBookCache(
                          requestFn: () => EbookGroup.getFavouriteBookCall.call(
                            userId: FFAppState().userId,
                            token: FFAppState().token,
                          ),
                        )
                            .then((result) {
                          _model.apiRequestCompleted1 = true;
                          return result;
                        }),
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
                              future: FFAppState()
                                  .popularBookCache(
                                requestFn: () =>
                                    EbookGroup.getPopularBooksApiCall.call(),
                              )
                                  .then((result) {
                                _model.apiRequestCompleted2 = true;
                                return result;
                              }),
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
                                final containerGetPopularBooksApiResponse =
                                    snapshot.data!;

                                return Container(
                                  decoration: BoxDecoration(),
                                  child: Builder(
                                    builder: (context) {
                                      if (EbookGroup.getPopularBooksApiCall
                                              .success(
                                            containerGetPopularBooksApiResponse
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
                                                EbookGroup
                                                    .getPopularBooksApiCall
                                                    .message(
                                                  containerGetPopularBooksApiResponse
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
                                            final popularBookList = EbookGroup
                                                    .getPopularBooksApiCall
                                                    .bookDetailsList(
                                                      containerGetPopularBooksApiResponse
                                                          .jsonBody,
                                                    )
                                                    ?.toList() ??
                                                [];
                                            if (popularBookList.isEmpty) {
                                              return Center(
                                                child: NoPopularBookWidget(),
                                              );
                                            }

                                            return RefreshIndicator(
                                              key: Key(
                                                  'RefreshIndicator_m9b9g2sw'),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              onRefresh: () async {
                                                safeSetState(() {
                                                  FFAppState()
                                                      .clearPopularBookCacheCache();
                                                  _model.apiRequestCompleted2 =
                                                      false;
                                                });
                                                await _model
                                                    .waitForApiRequestCompleted2();
                                              },
                                              child: ListView.separated(
                                                padding: EdgeInsets.fromLTRB(
                                                  0,
                                                  16.0,
                                                  0,
                                                  16.0,
                                                ),
                                                scrollDirection: Axis.vertical,
                                                itemCount:
                                                    popularBookList.length,
                                                separatorBuilder: (_, __) =>
                                                    SizedBox(height: 16.0),
                                                itemBuilder: (context,
                                                    popularBookListIndex) {
                                                  final popularBookListItem =
                                                      popularBookList[
                                                          popularBookListIndex];
                                                  return Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(16.0, 0.0,
                                                                16.0, 0.0),
                                                    child: wrapWithModel(
                                                      model: _model
                                                          .listMainContainerComponentModels
                                                          .getModel(
                                                        getJsonField(
                                                          popularBookListItem,
                                                          r'''$.name''',
                                                        ).toString(),
                                                        popularBookListIndex,
                                                      ),
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          ListMainContainerComponentWidget(
                                                        key: Key(
                                                          'Keyc76_${getJsonField(
                                                            popularBookListItem,
                                                            r'''$.name''',
                                                          ).toString()}',
                                                        ),
                                                        image:
                                                            '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                          popularBookListItem,
                                                          r'''$.image''',
                                                        ).toString()}',
                                                        name: getJsonField(
                                                          popularBookListItem,
                                                          r'''$.name''',
                                                        ).toString(),
                                                        authorName:
                                                            getJsonField(
                                                          popularBookListItem,
                                                          r'''$.author.name''',
                                                        ).toString(),
                                                        averageRating:
                                                            getJsonField(
                                                          popularBookListItem,
                                                          r'''$.averageRating''',
                                                        ).toDouble(),
                                                        isFav: functions.checkFavOrNot(
                                                                EbookGroup.getFavouriteBookCall
                                                                    .favouriteBookDetailsList(
                                                                      containerGetFavouriteBookResponse
                                                                          .jsonBody,
                                                                    )
                                                                    ?.toList(),
                                                                getJsonField(
                                                                  popularBookListItem,
                                                                  r'''$._id''',
                                                                ).toString()) ==
                                                            true,
                                                        indicator: (popularBookListIndex ==
                                                                _model
                                                                    .popularBookIndex) &&
                                                            (_model.isPopularBook ==
                                                                true),
                                                        width: double.infinity,
                                                        isFavAction: () async {
                                                          if (FFAppState()
                                                                  .isLogin ==
                                                              true) {
                                                            _model.isPopularBook =
                                                                true;
                                                            _model.popularBookIndex =
                                                                popularBookListIndex;
                                                            safeSetState(() {});
                                                            if (functions.checkFavOrNot(
                                                                    EbookGroup.getFavouriteBookCall
                                                                        .favouriteBookDetailsList(
                                                                          containerGetFavouriteBookResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList(),
                                                                    getJsonField(
                                                                      popularBookListItem,
                                                                      r'''$._id''',
                                                                    ).toString()) ==
                                                                true) {
                                                              _model.getPopularDetete =
                                                                  await EbookGroup
                                                                      .removeFavouritebookCall
                                                                      .call(
                                                                userId:
                                                                    FFAppState()
                                                                        .userId,
                                                                token:
                                                                    FFAppState()
                                                                        .token,
                                                                bookId:
                                                                    getJsonField(
                                                                  popularBookListItem,
                                                                  r'''$._id''',
                                                                ).toString(),
                                                              );

                                                              safeSetState(() {
                                                                FFAppState()
                                                                    .clearGetFavouriteBookCacheCache();
                                                                _model.apiRequestCompleted1 =
                                                                    false;
                                                              });
                                                              await _model
                                                                  .waitForApiRequestCompleted1();
                                                              await actions
                                                                  .showCustomToastBottom(
                                                                FFAppState()
                                                                    .unFavText,
                                                              );
                                                            } else {
                                                              _model.getPopularAdd =
                                                                  await EbookGroup
                                                                      .addFavouriteBookApiCall
                                                                      .call(
                                                                userId:
                                                                    FFAppState()
                                                                        .userId,
                                                                token:
                                                                    FFAppState()
                                                                        .token,
                                                                bookId:
                                                                    getJsonField(
                                                                  popularBookListItem,
                                                                  r'''$._id''',
                                                                ).toString(),
                                                              );

                                                              safeSetState(() {
                                                                FFAppState()
                                                                    .clearGetFavouriteBookCacheCache();
                                                                _model.apiRequestCompleted1 =
                                                                    false;
                                                              });
                                                              await _model
                                                                  .waitForApiRequestCompleted1();
                                                              await actions
                                                                  .showCustomToastBottom(
                                                                FFAppState()
                                                                    .favText,
                                                              );
                                                            }

                                                            FFAppState()
                                                                .clearGetFavouriteBookCacheCache();
                                                            _model.isPopularBook =
                                                                false;
                                                            safeSetState(() {});
                                                          } else {
                                                            FFAppState()
                                                                    .favChange =
                                                                true;
                                                            FFAppState()
                                                                    .bookId =
                                                                getJsonField(
                                                              popularBookListItem,
                                                              r'''$._id''',
                                                            ).toString();
                                                            FFAppState()
                                                                .update(() {});

                                                            context.pushNamed(
                                                                SignInPageWidget
                                                                    .routeName);
                                                          }

                                                          safeSetState(() {});
                                                        },
                                                        onMainTap: () async {
                                                          context.pushNamed(
                                                            BookDetailspageWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'name':
                                                                  serializeParam(
                                                                getJsonField(
                                                                  popularBookListItem,
                                                                  r'''$.name''',
                                                                ).toString(),
                                                                ParamType
                                                                    .String,
                                                              ),
                                                              'image':
                                                                  serializeParam(
                                                                '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                  popularBookListItem,
                                                                  r'''$.image''',
                                                                ).toString()}',
                                                                ParamType
                                                                    .String,
                                                              ),
                                                              'id':
                                                                  serializeParam(
                                                                getJsonField(
                                                                  popularBookListItem,
                                                                  r'''$._id''',
                                                                ).toString(),
                                                                ParamType
                                                                    .String,
                                                              ),
                                                            }.withoutNulls,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
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
