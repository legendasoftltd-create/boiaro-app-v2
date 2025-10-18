import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_latest_book/no_latest_book_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'new_books_page_model.dart';
export 'new_books_page_model.dart';

class NewBooksPageWidget extends StatefulWidget {
  const NewBooksPageWidget({super.key});

  static String routeName = 'NewBooksPage';
  static String routePath = '/newBooksPage';

  @override
  State<NewBooksPageWidget> createState() =>
      _NewBooksPageWidgetState();
}

class _NewBooksPageWidgetState extends State<NewBooksPageWidget> {
  late NewBooksPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewBooksPageModel());

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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 21.0, 16.0, 18.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.safePop();
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGrey,
                            shape: BoxShape.circle,
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/arrow_back_appbar_ic.svg',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'New books',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 24.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              lineHeight: 1.5,
                            ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          FFAppState().authorId = [];
                          FFAppState().categoryId = [];
                          FFAppState().update(() {});

                          context.pushNamed(FilterPageWidget.routeName);
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGrey,
                            shape: BoxShape.circle,
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/filter.svg',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
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
                                  .getNewBooksCache(
                                requestFn: () =>
                                    EbookGroup.getNewBooksApiCall.call(),
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
                                final containerGetNewBooksApiResponse =
                                    snapshot.data!;

                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      if (EbookGroup.getNewBooksApiCall
                                              .success(
                                            containerGetNewBooksApiResponse
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
                                                    .getNewBooksApiCall
                                                    .message(
                                                  containerGetNewBooksApiResponse
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
                                            if (EbookGroup
                                                        .getNewBooksApiCall
                                                        .bookDetailsList(
                                                      containerGetNewBooksApiResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (EbookGroup
                                                        .getNewBooksApiCall
                                                        .bookDetailsList(
                                                  containerGetNewBooksApiResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty) {
                                              return RefreshIndicator(
                                                key: Key(
                                                    'RefreshIndicator_newbooks'),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                onRefresh: () async {
                                                  safeSetState(() {
                                                    FFAppState()
                                                        .clearGetNewBooksCacheCache();
                                                    _model.apiRequestCompleted2 =
                                                        false;
                                                  });
                                                  await waitForPendingApiCall(
                                                    resetStatus: () => _model.apiRequestCompleted2 = false,
                                                    stopActiveLoop: () => _model.apiRequestCompleted2,
                                                    minWait: 0,
                                                    maxWait: double.infinity,
                                                  );
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
                                                          final newBooksList = EbookGroup
                                                                  .getNewBooksApiCall
                                                                  .bookDetailsList(
                                                                    containerGetNewBooksApiResponse
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
                                                                newBooksList
                                                                    .length,
                                                                (newBooksListIndex) {
                                                              final newBooksListItem =
                                                                  newBooksList[
                                                                      newBooksListIndex];
                                                              return wrapWithModel(
                                                                model: _model
                                                                    .mainBookComponentModels
                                                                    .getModel(
                                                                  getJsonField(
                                                                    newBooksListItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  newBooksListIndex,
                                                                ),
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child:
                                                                    MainBookComponentWidget(
                                                                  key: Key(
                                                                    'Keynewbook_${getJsonField(
                                                                      newBooksListItem,
                                                                      r'''$.name''',
                                                                    ).toString()}',
                                                                  ),
                                                                  image:
                                                                      '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                    newBooksListItem,
                                                                    r'''$.image''',
                                                                  ).toString()}',
                                                                  bookName:
                                                                      getJsonField(
                                                                    newBooksListItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  id:
                                                                      getJsonField(
                                                                    newBooksListItem,
                                                                    r'''$._id''',
                                                                  ).toString(),
                                                                  price:
                                                                      getJsonField(
                                                                    newBooksListItem,
                                                                    r'''$.price''',
                                                                  ).toString(),
                                                                  authorsName:
                                                                      getJsonField(
                                                                    newBooksListItem,
                                                                    r'''$.author.name''',
                                                                  ).toString(),
                                                                  isFav: functions.checkFavOrNot(
                                                                          EbookGroup.getFavouriteBookCall
                                                                              .favouriteBookDetailsList(
                                                                                containerGetFavouriteBookResponse.jsonBody,
                                                                              )
                                                                              ?.toList(),
                                                                          getJsonField(
                                                                            newBooksListItem,
                                                                            r'''$._id''',
                                                                          ).toString()) ==
                                                                      true,
                                                                  indicator: (newBooksListIndex ==
                                                                          _model
                                                                              .newBooksIndex) &&
                                                                      (_model.isNewBook ==
                                                                          true),
                                                                  isFavAction:
                                                                      () async {
                                                                    if (FFAppState()
                                                                            .isLogin ==
                                                                        true) {
                                                                      _model.isNewBook =
                                                                          true;
                                                                      _model.newBooksIndex =
                                                                          newBooksListIndex;
                                                                      safeSetState(
                                                                          () {});
                                                                      if (functions.checkFavOrNot(
                                                                              EbookGroup.getFavouriteBookCall
                                                                                  .favouriteBookDetailsList(
                                                                                    containerGetFavouriteBookResponse.jsonBody,
                                                                                  )
                                                                                  ?.toList(),
                                                                              getJsonField(
                                                                                newBooksListItem,
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
                                                                            newBooksListItem,
                                                                            r'''$._id''',
                                                                          ).toString(),
                                                                        );

                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetFavouriteBookCacheCache();
                                                                  _model.apiRequestCompleted1 =
                                                                      false;
                                                                });
                                                                await waitForPendingApiCall(
                                                                  resetStatus: () => _model.apiRequestCompleted1 = false,
                                                                  stopActiveLoop: () => _model.apiRequestCompleted1,
                                                                  minWait: 0,
                                                                  maxWait: double.infinity,
                                                                );
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
                                                                            newBooksListItem,
                                                                            r'''$._id''',
                                                                          ).toString(),
                                                                        );

                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetFavouriteBookCacheCache();
                                                                  _model.apiRequestCompleted1 =
                                                                      false;
                                                                });
                                                                await waitForPendingApiCall(
                                                                  resetStatus: () => _model.apiRequestCompleted1 = false,
                                                                  stopActiveLoop: () => _model.apiRequestCompleted1,
                                                                  minWait: 0,
                                                                  maxWait: double.infinity,
                                                                );
                                                                        await actions
                                                                            .showCustomToastBottom(
                                                                          FFAppState()
                                                                              .favText,
                                                                        );
                                                                      }

                                                                      FFAppState()
                                                                          .clearGetFavouriteBookCacheCache();
                                                                      _model.isNewBook =
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
                                                                        newBooksListItem,
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
                                                                            newBooksListItem,
                                                                            r'''$.name''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'price':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            newBooksListItem,
                                                                            r'''$.price''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'image':
                                                                            serializeParam(
                                                                          '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                            newBooksListItem,
                                                                            r'''$.image''',
                                                                          ).toString()}',
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'id':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            newBooksListItem,
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
                                                model: _model
                                                    .noLatestBookModel,
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child:
                                                    NoLatestBookWidget(),
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
