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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BestNarratorPageModel());

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
                  title: 'Best narrator',
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: FFAppState()
                            .getnarratorsCache(
                          uniqueQueryKey: FFAppState().userId,
                          requestFn: () =>
                              EbookGroup.getnarratorsApiCall.call(),
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
                          final containerGetnarratorsApiResponse =
                              snapshot.data!;

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getnarratorsApiCall.success(
                                      containerGetnarratorsApiResponse.jsonBody,
                                    ) ==
                                    2) {
                                  return Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Text(
                                        valueOrDefault<String>(
                                          EbookGroup.getnarratorsApiCall
                                              .message(
                                            containerGetnarratorsApiResponse
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
                                      if (EbookGroup.getnarratorsApiCall
                                                  .narratorDetailsList(
                                                containerGetnarratorsApiResponse
                                                    .jsonBody,
                                              ) !=
                                              null &&
                                          (EbookGroup.getnarratorsApiCall
                                                  .narratorDetailsList(
                                            containerGetnarratorsApiResponse
                                                .jsonBody,
                                          ))!
                                              .isNotEmpty) {
                                        return RefreshIndicator(
                                          key: Key('RefreshIndicator_k3vczp9b'),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          onRefresh: () async {
                                            safeSetState(() {
                                              FFAppState()
                                                  .clearGetnarratorsCacheCacheKey(
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
                                                    final narratorDetailsList =
                                                        EbookGroup
                                                                .getnarratorsApiCall
                                                                .narratorDetailsList(
                                                                  containerGetnarratorsApiResponse
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
                                                          narratorDetailsList
                                                              .length,
                                                          (narratorDetailsListIndex) {
                                                        final narratorDetailsListItem =
                                                            narratorDetailsList[
                                                                narratorDetailsListIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .categoryComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              narratorDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            narratorDetailsListIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              CategoryComponentWidget(
                                                            key: Key(
                                                              'Keynarr_${getJsonField(
                                                                narratorDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            icon:
                                                                '${FFAppConstants.imageUrl}${getJsonField(
                                                              narratorDetailsListItem,
                                                              r'''$.image''',
                                                            ).toString()}',
                                                            name: getJsonField(
                                                              narratorDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            isSmall: true,
                                                            onMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                AboutNarratorPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      narratorDetailsListItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'narratorImage':
                                                                      serializeParam(
                                                                    '${FFAppConstants.imageUrl}${getJsonField(
                                                                      narratorDetailsListItem,
                                                                      r'''$.image''',
                                                                    ).toString()}',
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'narratorId':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      narratorDetailsListItem,
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
                                          model: _model.noNarratorYetModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: NoNarratorYetWidget(),
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
