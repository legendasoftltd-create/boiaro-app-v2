import 'package:a_i_ebook_app/pages/home_pages/about_publisher_page/about_publisher_page_widget.dart';

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
import 'best_publisher_page_model.dart';
export 'best_publisher_page_model.dart';

class BestPublisherPageWidget extends StatefulWidget {
  const BestPublisherPageWidget({super.key});

  static String routeName = 'BestPublisherPage';
  static String routePath = '/bestPublisherPage';

  @override
  State<BestPublisherPageWidget> createState() =>
      _BestPublisherPageWidgetState();
}

class _BestPublisherPageWidgetState extends State<BestPublisherPageWidget> {
  late BestPublisherPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BestPublisherPageModel());

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
                  title: 'Best publisher',
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: FFAppState()
                            .getpublishersCache(
                          uniqueQueryKey: FFAppState().userId,
                          requestFn: () =>
                              EbookGroup.getpublishersApiCall.call(),
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
                          final containerGetpublishersApiResponse =
                              snapshot.data!;

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getpublishersApiCall.success(
                                      containerGetpublishersApiResponse
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
                                          EbookGroup.getpublishersApiCall
                                              .message(
                                            containerGetpublishersApiResponse
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
                                      if (EbookGroup.getpublishersApiCall
                                                  .publisherDetailsList(
                                                containerGetpublishersApiResponse
                                                    .jsonBody,
                                              ) !=
                                              null &&
                                          (EbookGroup.getpublishersApiCall
                                                  .publisherDetailsList(
                                            containerGetpublishersApiResponse
                                                .jsonBody,
                                          ))!
                                              .isNotEmpty) {
                                        return RefreshIndicator(
                                          key: Key('RefreshIndicator_3d7e1s78'),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          onRefresh: () async {
                                            safeSetState(() {
                                              FFAppState()
                                                  .clearGetpublishersCacheCacheKey(
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
                                                    final publisherDetailsList =
                                                        EbookGroup
                                                                .getpublishersApiCall
                                                                .publisherDetailsList(
                                                                  containerGetpublishersApiResponse
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
                                                          publisherDetailsList
                                                              .length,
                                                          (publisherDetailsListIndex) {
                                                        final publisherDetailsListItem =
                                                            publisherDetailsList[
                                                                publisherDetailsListIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .categoryComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              publisherDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            publisherDetailsListIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              CategoryComponentWidget(
                                                            key: Key(
                                                              'Keyhj5_${getJsonField(
                                                                publisherDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            icon:
                                                                '${FFAppConstants.imageUrl}${getJsonField(
                                                              publisherDetailsListItem,
                                                              r'''$.image''',
                                                            ).toString()}',
                                                            name: getJsonField(
                                                              publisherDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            isSmall: true,
                                                            onMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                AboutPublisherPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      publisherDetailsListItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'publisherImage':
                                                                      serializeParam(
                                                                    '${FFAppConstants.imageUrl}${getJsonField(
                                                                      publisherDetailsListItem,
                                                                      r'''$.image''',
                                                                    ).toString()}',
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'publisherId':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      publisherDetailsListItem,
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
