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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BestAuthorPageModel());

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
                model: _model.singleAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: SingleAppbarWidget(
                  title: 'Best author',
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: FFAppState()
                            .getauthorsCache(
                          uniqueQueryKey: FFAppState().userId,
                          requestFn: () => EbookGroup.getauthorsApiCall.call(),
                        )
                            .then((result) {
                          try {
                            _model.apiRequestCompleted = true;
                            _model.apiRequestLastUniqueKey =
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
                          final containerGetauthorsApiResponse = snapshot.data!;

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getauthorsApiCall.success(
                                      containerGetauthorsApiResponse.jsonBody,
                                    ) ==
                                    2) {
                                  return Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Text(
                                        valueOrDefault<String>(
                                          EbookGroup.getauthorsApiCall.message(
                                            containerGetauthorsApiResponse
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
                                      if (EbookGroup.getauthorsApiCall
                                                  .authorDetailsList(
                                                containerGetauthorsApiResponse
                                                    .jsonBody,
                                              ) !=
                                              null &&
                                          (EbookGroup.getauthorsApiCall
                                                  .authorDetailsList(
                                            containerGetauthorsApiResponse
                                                .jsonBody,
                                          ))!
                                              .isNotEmpty) {
                                        return RefreshIndicator(
                                          key: Key('RefreshIndicator_3d7e1s76'),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          onRefresh: () async {
                                            safeSetState(() {
                                              FFAppState()
                                                  .clearGetauthorsCacheCacheKey(
                                                      _model
                                                          .apiRequestLastUniqueKey);
                                              _model.apiRequestCompleted =
                                                  false;
                                            });
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
                                                    final authorDetailsList =
                                                        EbookGroup
                                                                .getauthorsApiCall
                                                                .authorDetailsList(
                                                                  containerGetauthorsApiResponse
                                                                      .jsonBody,
                                                                )
                                                                ?.toList() ??
                                                            [];

                                                    return Wrap(
                                                      spacing: 18.0,
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
                                                          authorDetailsList
                                                              .length,
                                                          (authorDetailsListIndex) {
                                                        final authorDetailsListItem =
                                                            authorDetailsList[
                                                                authorDetailsListIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .categoryComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              authorDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            authorDetailsListIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              CategoryComponentWidget(
                                                            key: Key(
                                                              'Keyhj4_${getJsonField(
                                                                authorDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            image:
                                                                '${FFAppConstants.imageUrl}${getJsonField(
                                                              authorDetailsListItem,
                                                              r'''$.image''',
                                                            ).toString()}',
                                                            name: getJsonField(
                                                              authorDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            onMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                AboutAuthorPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      authorDetailsListItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'authorImage':
                                                                      serializeParam(
                                                                    '${FFAppConstants.imageUrl}${getJsonField(
                                                                      authorDetailsListItem,
                                                                      r'''$.image''',
                                                                    ).toString()}',
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'authorId':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      authorDetailsListItem,
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
                                          model: _model.noAuthorYetModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: NoAuthorYetWidget(),
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
