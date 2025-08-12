import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_download_yet/no_download_yet_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DownloadPageModel());

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
                  title: 'Download',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected == true) {
                      return FutureBuilder<ApiCallResponse>(
                        future: FFAppState()
                            .getFavouriteBookCache(
                          requestFn: () => EbookGroup.getFavouriteBookCall.call(
                            userId: FFAppState().userId,
                            token: FFAppState().token,
                          ),
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
                                            .downloadhistoryApiCall
                                            .call(
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context).primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final containerDownloadhistoryApiResponse =
                                    snapshot.data!;

                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(),
                                  child: Builder(
                                    builder: (context) {
                                      if (EbookGroup.downloadhistoryApiCall
                                              .success(
                                            containerDownloadhistoryApiResponse
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
                                                    .downloadhistoryApiCall
                                                    .message(
                                                  containerDownloadhistoryApiResponse
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
                                                        .downloadhistoryApiCall
                                                        .downloadDetailsList(
                                                      containerDownloadhistoryApiResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (EbookGroup
                                                        .downloadhistoryApiCall
                                                        .downloadDetailsList(
                                                  containerDownloadhistoryApiResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty) {
                                              return RefreshIndicator(
                                                key: Key(
                                                    'RefreshIndicator_2twh3rth'),
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
                                                          final downloadDetailsList = EbookGroup
                                                                  .downloadhistoryApiCall
                                                                  .downloadDetailsList(
                                                                    containerDownloadhistoryApiResponse
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
                                                                downloadDetailsList
                                                                    .length,
                                                                (downloadDetailsListIndex) {
                                                              final downloadDetailsListItem =
                                                                  downloadDetailsList[
                                                                      downloadDetailsListIndex];
                                                              return wrapWithModel(
                                                                model: _model
                                                                    .mainBookComponentModels
                                                                    .getModel(
                                                                  getJsonField(
                                                                    downloadDetailsListItem,
                                                                    r'''$.bookDetails.name''',
                                                                  ).toString(),
                                                                  downloadDetailsListIndex,
                                                                ),
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child:
                                                                    MainBookComponentWidget(
                                                                  key: Key(
                                                                    'Keyoxg_${getJsonField(
                                                                      downloadDetailsListItem,
                                                                      r'''$.bookDetails.name''',
                                                                    ).toString()}',
                                                                  ),
                                                                  image:
                                                                      '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                    downloadDetailsListItem,
                                                                    r'''$.bookDetails.image''',
                                                                  ).toString()}',
                                                                  bookName:
                                                                      getJsonField(
                                                                    downloadDetailsListItem,
                                                                    r'''$.bookDetails.name''',
                                                                  ).toString(),
                                                                  authorsName:
                                                                      getJsonField(
                                                                    downloadDetailsListItem,
                                                                    r'''$.bookDetails.author.name''',
                                                                  ).toString(),
                                                                  isFav: functions.checkFavOrNot(
                                                                          EbookGroup.getFavouriteBookCall
                                                                              .favouriteBookDetailsList(
                                                                                containerGetFavouriteBookResponse.jsonBody,
                                                                              )
                                                                              ?.toList(),
                                                                          getJsonField(
                                                                            downloadDetailsListItem,
                                                                            r'''$.bookDetails._id''',
                                                                          ).toString()) ==
                                                                      true,
                                                                  indicator: (downloadDetailsListIndex ==
                                                                          _model
                                                                              .downloadIndex) &&
                                                                      (_model.isDownload ==
                                                                          true),
                                                                  isFavAction:
                                                                      () async {
                                                                    _model.isDownload =
                                                                        true;
                                                                    _model.downloadIndex =
                                                                        downloadDetailsListIndex;
                                                                    safeSetState(
                                                                        () {});
                                                                    if (functions.checkFavOrNot(
                                                                            EbookGroup.getFavouriteBookCall
                                                                                .favouriteBookDetailsList(
                                                                                  containerGetFavouriteBookResponse.jsonBody,
                                                                                )
                                                                                ?.toList(),
                                                                            getJsonField(
                                                                              downloadDetailsListItem,
                                                                              r'''$.bookDetails._id''',
                                                                            ).toString()) ==
                                                                        true) {
                                                                      _model.getPopularDetete = await EbookGroup
                                                                          .removeFavouritebookCall
                                                                          .call(
                                                                        userId:
                                                                            FFAppState().userId,
                                                                        token: FFAppState()
                                                                            .token,
                                                                        bookId:
                                                                            getJsonField(
                                                                          downloadDetailsListItem,
                                                                          r'''$.bookDetails._id''',
                                                                        ).toString(),
                                                                      );

                                                                      safeSetState(
                                                                          () {
                                                                        FFAppState()
                                                                            .clearGetFavouriteBookCacheCache();
                                                                        _model.apiRequestCompleted2 =
                                                                            false;
                                                                      });
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
                                                                        token: FFAppState()
                                                                            .token,
                                                                        bookId:
                                                                            getJsonField(
                                                                          downloadDetailsListItem,
                                                                          r'''$.bookDetails._id''',
                                                                        ).toString(),
                                                                      );

                                                                      safeSetState(
                                                                          () {
                                                                        FFAppState()
                                                                            .clearGetFavouriteBookCacheCache();
                                                                        _model.apiRequestCompleted2 =
                                                                            false;
                                                                      });
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
                                                                    _model.isDownload =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});

                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  isMainTap:
                                                                      () async {
                                                                    context
                                                                        .pushNamed(
                                                                      ReadBookCustomPageWidget
                                                                          .routeName,
                                                                      queryParameters:
                                                                          {
                                                                        'pdf':
                                                                            serializeParam(
                                                                          '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                            downloadDetailsListItem,
                                                                            r'''$.bookDetails.pdf''',
                                                                          ).toString()}',
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'id':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            downloadDetailsListItem,
                                                                            r'''$.bookDetails._id''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'name':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            downloadDetailsListItem,
                                                                            r'''$.bookDetails.name''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'image':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            downloadDetailsListItem,
                                                                            r'''$.bookDetails.image''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                      }.withoutNulls,
                                                                    );

                                                                    if (getJsonField(
                                                                          downloadDetailsListItem,
                                                                          r'''$.bookDetails._id''',
                                                                        ) ==
                                                                        FFAppState()
                                                                            .homePageBookId) {
                                                                      FFAppState()
                                                                          .totalPages = 1;
                                                                      FFAppState()
                                                                          .update(
                                                                              () {});
                                                                    } else {
                                                                      FFAppState()
                                                                          .totalPages = 1;
                                                                      FFAppState()
                                                                          .homePageCurrentPdfIndex = 1;
                                                                      FFAppState()
                                                                          .update(
                                                                              () {});
                                                                    }
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
                                                model:
                                                    _model.noDownloadYetModel,
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: NoDownloadYetWidget(),
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
