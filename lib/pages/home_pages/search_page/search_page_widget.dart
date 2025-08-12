import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/empty_components/no_result_book_found/no_result_book_found_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'search_page_model.dart';
export 'search_page_model.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({super.key});

  static String routeName = 'SearchPage';
  static String routePath = '/searchPage';

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> {
  late SearchPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SearchPageModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textFieldFocusNode!.addListener(
      () async {
        _model.focus = true;
        safeSetState(() {});
      },
    );
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
                  title: 'Search',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).black20,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: SvgPicture.asset(
                            'assets/images/search.svg',
                            width: 24.0,
                            height: 24.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _model.textController,
                          focusNode: _model.textFieldFocusNode,
                          onChanged: (_) => EasyDebounce.debounce(
                            '_model.textController',
                            Duration(milliseconds: 500),
                            () async {
                              if (_model.textController.text == '') {
                                _model.focus = false;
                                safeSetState(() {});
                                safeSetState(
                                    () => _model.apiRequestCompleter2 = null);
                                await _model.waitForApiRequestCompleted2();
                              } else {
                                _model.focus = true;
                                safeSetState(() {});
                                safeSetState(
                                    () => _model.apiRequestCompleter2 = null);
                                await _model.waitForApiRequestCompleted2();
                              }
                            },
                          ),
                          onFieldSubmitted: (_) async {
                            FFAppState()
                                .addToSearchList(_model.textController.text);
                            FFAppState().update(() {});
                            safeSetState(
                                () => _model.apiRequestCompleter2 = null);
                            await _model.waitForApiRequestCompleted2();
                          },
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            hintText: 'Search ',
                            hintStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  lineHeight: 1.5,
                                ),
                            errorStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).error,
                                  fontSize: 15.0,
                                  letterSpacing: 0.0,
                                  lineHeight: 1.2,
                                ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 17.0,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.5,
                                  ),
                          cursorColor: FlutterFlowTheme.of(context).primary,
                          validator: _model.textControllerValidator
                              .asValidator(context),
                        ),
                      ),
                      if (_model.textController.text != '')
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              safeSetState(() {
                                _model.textController?.clear();
                              });
                              _model.focus = false;
                              safeSetState(() {});
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/close_ic.svg',
                                width: 24.0,
                                height: 24.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Builder(
                    builder: (context) {
                      if (_model.focus == false) {
                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (FFAppState().searchList.isNotEmpty)
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 24.0, 16.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Recent search',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
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
                                        FFAppState().searchList = [];
                                        FFAppState().update(() {});
                                      },
                                      child: Text(
                                        'Clear all',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20.0, 0.0, 20.0, 0.0),
                                child: Builder(
                                  builder: (context) {
                                    final searchList =
                                        FFAppState().searchList.toList();
                                    if (searchList.isEmpty) {
                                      return Center(
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: NoResultBookFoundWidget(),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        24.0,
                                        0,
                                        24.0,
                                      ),
                                      scrollDirection: Axis.vertical,
                                      itemCount: searchList.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 24.0),
                                      itemBuilder: (context, searchListIndex) {
                                        final searchListItem =
                                            searchList[searchListIndex];
                                        return Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                              child: SvgPicture.asset(
                                                'assets/images/search.svg',
                                                width: 24.0,
                                                height: 24.0,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 0.0, 0.0, 0.0),
                                                child: InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    safeSetState(() {
                                                      _model.textController
                                                              ?.text =
                                                          searchListItem;
                                                    });
                                                  },
                                                  child: Text(
                                                    searchListItem,
                                                    maxLines: 1,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                FFAppState()
                                                    .removeAtIndexFromSearchList(
                                                        searchListIndex);
                                                FFAppState().update(() {});
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0.0),
                                                child: Image.asset(
                                                  'assets/images/Plus.png',
                                                  width: 20.0,
                                                  height: 20.0,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return FutureBuilder<ApiCallResponse>(
                          future: FFAppState()
                              .getFavouriteBookCache(
                            uniqueQueryKey: FFAppState().userId,
                            requestFn: () =>
                                EbookGroup.getFavouriteBookCall.call(
                              userId: FFAppState().userId,
                              token: FFAppState().token,
                            ),
                          )
                              .then((result) {
                            try {
                              _model.apiRequestCompleted1 = true;
                              _model.apiRequestLastUniqueKey1 =
                                  FFAppState().userId;
                            } finally {}
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
                              child: Builder(
                                builder: (context) {
                                  if (FFAppState().connected) {
                                    return FutureBuilder<ApiCallResponse>(
                                      future: (_model.apiRequestCompleter2 ??=
                                              Completer<ApiCallResponse>()
                                                ..complete(EbookGroup
                                                    .searchApiCall
                                                    .call(
                                                  search: _model
                                                      .textController.text,
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final listViewSearchApiResponse =
                                            snapshot.data!;

                                        return Builder(
                                          builder: (context) {
                                            final seachFilterList =
                                                EbookGroup.searchApiCall
                                                        .bookDetailsList(
                                                          listViewSearchApiResponse
                                                              .jsonBody,
                                                        )
                                                        ?.toList() ??
                                                    [];
                                            if (seachFilterList.isEmpty) {
                                              return Center(
                                                child: Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  child:
                                                      NoResultBookFoundWidget(),
                                                ),
                                              );
                                            }

                                            return ListView.separated(
                                              padding: EdgeInsets.fromLTRB(
                                                0,
                                                24.0,
                                                0,
                                                24.0,
                                              ),
                                              scrollDirection: Axis.vertical,
                                              itemCount: seachFilterList.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(height: 16.0),
                                              itemBuilder: (context,
                                                  seachFilterListIndex) {
                                                final seachFilterListItem =
                                                    seachFilterList[
                                                        seachFilterListIndex];
                                                return Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          16.0, 0.0, 16.0, 0.0),
                                                  child: wrapWithModel(
                                                    model: _model
                                                        .listMainContainerComponentModels
                                                        .getModel(
                                                      getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.name''',
                                                      ).toString(),
                                                      seachFilterListIndex,
                                                    ),
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child:
                                                        ListMainContainerComponentWidget(
                                                      key: Key(
                                                        'Key2xe_${getJsonField(
                                                          seachFilterListItem,
                                                          r'''$.name''',
                                                        ).toString()}',
                                                      ),
                                                      image:
                                                          '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.image''',
                                                      ).toString()}',
                                                      name: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.name''',
                                                      ).toString(),
                                                      authorName: getJsonField(
                                                        seachFilterListItem,
                                                        r'''$.author.name''',
                                                      ).toString(),
                                                      averageRating:
                                                          getJsonField(
                                                        seachFilterListItem,
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
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString()) ==
                                                          true,
                                                      indicator:
                                                          (seachFilterListIndex ==
                                                                  _model
                                                                      .searchIndex) &&
                                                              (_model.isSearch ==
                                                                  true),
                                                      width: double.infinity,
                                                      isFavAction: () async {
                                                        if (FFAppState()
                                                                .isLogin ==
                                                            true) {
                                                          _model.isSearch =
                                                              true;
                                                          _model.searchIndex =
                                                              seachFilterListIndex;
                                                          safeSetState(() {});
                                                          if (functions.checkFavOrNot(
                                                                  EbookGroup.getFavouriteBookCall
                                                                      .favouriteBookDetailsList(
                                                                        containerGetFavouriteBookResponse
                                                                            .jsonBody,
                                                                      )
                                                                      ?.toList(),
                                                                  getJsonField(
                                                                    seachFilterListItem,
                                                                    r'''$._id''',
                                                                  ).toString()) ==
                                                              true) {
                                                            _model.getSeachDetete =
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
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                            );

                                                            safeSetState(() {
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCacheKey(
                                                                      _model
                                                                          .apiRequestLastUniqueKey1);
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
                                                            _model.getSearchAdd =
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
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                            );

                                                            safeSetState(() {
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCacheKey(
                                                                      _model
                                                                          .apiRequestLastUniqueKey1);
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
                                                          _model.isSearch =
                                                              false;
                                                          safeSetState(() {});
                                                        } else {
                                                          FFAppState()
                                                              .favChange = true;
                                                          FFAppState().bookId =
                                                              getJsonField(
                                                            seachFilterListItem,
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
                                                                seachFilterListItem,
                                                                r'''$.name''',
                                                              ).toString(),
                                                              ParamType.String,
                                                            ),
                                                            'image':
                                                                serializeParam(
                                                              '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                seachFilterListItem,
                                                                r'''$.image''',
                                                              ).toString()}',
                                                              ParamType.String,
                                                            ),
                                                            'id':
                                                                serializeParam(
                                                              getJsonField(
                                                                seachFilterListItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                              ParamType.String,
                                                            ),
                                                          }.withoutNulls,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
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
                            );
                          },
                        );
                      }
                    },
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
