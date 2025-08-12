import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/no_favorites_yet/no_favorites_yet_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'favourite_page_model.dart';
export 'favourite_page_model.dart';

class FavouritePageWidget extends StatefulWidget {
  const FavouritePageWidget({super.key});

  static String routeName = 'FavouritePage';
  static String routePath = '/favouritePage';

  @override
  State<FavouritePageWidget> createState() => _FavouritePageWidgetState();
}

class _FavouritePageWidgetState extends State<FavouritePageWidget> {
  late FavouritePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FavouritePageModel());

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
                  title: 'Favourite',
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
                        future: (_model.apiRequestCompleter ??= Completer<
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
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getFavouriteBookCall.success(
                                      containerGetFavouriteBookResponse
                                          .jsonBody,
                                    ) ==
                                    2) {
                                  return Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Text(
                                        valueOrDefault<String>(
                                          EbookGroup.getFavouriteBookCall
                                              .message(
                                            containerGetFavouriteBookResponse
                                                .jsonBody,
                                          ),
                                          'Message',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              lineHeight: 1.5,
                                            ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Builder(
                                    builder: (context) {
                                      if (EbookGroup.getFavouriteBookCall
                                                  .favouriteBookDetailsList(
                                                containerGetFavouriteBookResponse
                                                    .jsonBody,
                                              ) !=
                                              null &&
                                          (EbookGroup.getFavouriteBookCall
                                                  .favouriteBookDetailsList(
                                            containerGetFavouriteBookResponse
                                                .jsonBody,
                                          ))!
                                              .isNotEmpty) {
                                        return RefreshIndicator(
                                          key: Key('RefreshIndicator_gnh6g9gu'),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          onRefresh: () async {
                                            safeSetState(() => _model
                                                .apiRequestCompleter = null);
                                            await _model
                                                .waitForApiRequestCompleted();
                                          },
                                          child: ListView(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              16.0,
                                              0,
                                              16.0,
                                            ),
                                            scrollDirection: Axis.vertical,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 0.0, 16.0, 0.0),
                                                child: Builder(
                                                  builder: (context) {
                                                    final favList = EbookGroup
                                                            .getFavouriteBookCall
                                                            .favouriteBookDetailsList(
                                                              containerGetFavouriteBookResponse
                                                                  .jsonBody,
                                                            )
                                                            ?.toList() ??
                                                        [];

                                                    return Wrap(
                                                      spacing: 16.0,
                                                      runSpacing: 16.0,
                                                      alignment:
                                                          WrapAlignment.start,
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .start,
                                                      direction:
                                                          Axis.horizontal,
                                                      runAlignment:
                                                          WrapAlignment.start,
                                                      verticalDirection:
                                                          VerticalDirection
                                                              .down,
                                                      clipBehavior: Clip.none,
                                                      children: List.generate(
                                                          favList.length,
                                                          (favListIndex) {
                                                        final favListItem =
                                                            favList[
                                                                favListIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .mainBookComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              favListItem,
                                                              r'''$.bookDetails.name''',
                                                            ).toString(),
                                                            favListIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              MainBookComponentWidget(
                                                            key: Key(
                                                              'Keyz5j_${getJsonField(
                                                                favListItem,
                                                                r'''$.bookDetails.name''',
                                                              ).toString()}',
                                                            ),
                                                            image:
                                                                '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                              favListItem,
                                                              r'''$.bookDetails.image''',
                                                            ).toString()}',
                                                            bookName:
                                                                getJsonField(
                                                              favListItem,
                                                              r'''$.bookDetails.name''',
                                                            ).toString(),
                                                            authorsName:
                                                                getJsonField(
                                                              favListItem,
                                                              r'''$.bookDetails.author.name''',
                                                            ).toString(),
                                                            isFav: true,
                                                            indicator: (favListIndex ==
                                                                    _model
                                                                        .favIndex) &&
                                                                (_model.isFav ==
                                                                    true),
                                                            isFavAction:
                                                                () async {
                                                              _model.isFav =
                                                                  true;
                                                              _model.favIndex =
                                                                  favListIndex;
                                                              safeSetState(
                                                                  () {});
                                                              _model.getAllPoolDetete =
                                                                  await EbookGroup
                                                                      .removeFavouritebookCall
                                                                      .call(
                                                                userId:
                                                                    FFAppState()
                                                                        .userId,
                                                                bookId:
                                                                    getJsonField(
                                                                  favListItem,
                                                                  r'''$.bookDetails._id''',
                                                                ).toString(),
                                                                token:
                                                                    FFAppState()
                                                                        .token,
                                                              );

                                                              safeSetState(() =>
                                                                  _model.apiRequestCompleter =
                                                                      null);
                                                              await _model
                                                                  .waitForApiRequestCompleted();
                                                              await actions
                                                                  .showCustomToastBottom(
                                                                FFAppState()
                                                                    .unFavText,
                                                              );
                                                              FFAppState()
                                                                  .clearGetFavouriteBookCacheCache();
                                                              _model.isFav =
                                                                  false;
                                                              safeSetState(
                                                                  () {});

                                                              safeSetState(
                                                                  () {});
                                                            },
                                                            isMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                BookDetailspageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      favListItem,
                                                                      r'''$.bookDetails.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'image':
                                                                      serializeParam(
                                                                    '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                      favListItem,
                                                                      r'''$.bookDetails.image''',
                                                                    ).toString()}',
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'id':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      favListItem,
                                                                      r'''$.bookDetails._id''',
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
                                          model: _model.noFavoritesYetModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: NoFavoritesYetWidget(),
                                        );
                                      }
                                    },
                                  );
                                }
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
