import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/empty_components/no_categories_yet/no_categories_yet_widget.dart';
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'sub_categories_screen_model.dart';
export 'sub_categories_screen_model.dart';

class SubCategoriesScreenWidget extends StatefulWidget {
  const SubCategoriesScreenWidget({
    super.key,
    required this.id,
    required this.name,
  });

  final String? id;
  final String? name;

  static String routeName = 'SubCategoriesScreen';
  static String routePath = '/subCategoriesScreen';

  @override
  State<SubCategoriesScreenWidget> createState() =>
      _SubCategoriesScreenWidgetState();
}

class _SubCategoriesScreenWidgetState extends State<SubCategoriesScreenWidget> {
  late SubCategoriesScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubCategoriesScreenModel());

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
                  title: widget.name,
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
                        future: (_model.apiRequestCompleter ??=
                                Completer<ApiCallResponse>()
                                  ..complete(EbookGroup
                                      .getsubcategoriesbycategoryApiCall
                                      .call(
                                    categoryId: widget.id,
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
                          final containerGetsubcategoriesbycategoryApiResponse =
                              snapshot.data!;

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getsubcategoriesbycategoryApiCall
                                        .success(
                                      containerGetsubcategoriesbycategoryApiResponse
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
                                          EbookGroup
                                              .getsubcategoriesbycategoryApiCall
                                              .message(
                                            containerGetsubcategoriesbycategoryApiResponse
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
                                      if (EbookGroup
                                                  .getsubcategoriesbycategoryApiCall
                                                  .subcategoryDetailsList(
                                                containerGetsubcategoriesbycategoryApiResponse
                                                    .jsonBody,
                                              ) !=
                                              null &&
                                          (EbookGroup
                                                  .getsubcategoriesbycategoryApiCall
                                                  .subcategoryDetailsList(
                                            containerGetsubcategoriesbycategoryApiResponse
                                                .jsonBody,
                                          ))!
                                              .isNotEmpty) {
                                        return InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
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
                                                    final subcategoryDetailsList =
                                                        EbookGroup
                                                                .getsubcategoriesbycategoryApiCall
                                                                .subcategoryDetailsList(
                                                                  containerGetsubcategoriesbycategoryApiResponse
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
                                                          subcategoryDetailsList
                                                              .length,
                                                          (subcategoryDetailsListIndex) {
                                                        final subcategoryDetailsListItem =
                                                            subcategoryDetailsList[
                                                                subcategoryDetailsListIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .categoryComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              subcategoryDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            subcategoryDetailsListIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              CategoryComponentWidget(
                                                            key: Key(
                                                              'Keymy6_${getJsonField(
                                                                subcategoryDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            image:
                                                                '${FFAppConstants.imageUrl}${getJsonField(
                                                              subcategoryDetailsListItem,
                                                              r'''$.image''',
                                                            ).toString()}',
                                                            name: getJsonField(
                                                              subcategoryDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            onMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                HistoryDetailsPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      subcategoryDetailsListItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'id':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      subcategoryDetailsListItem,
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
                                          model: _model.noCategoriesYetModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: NoCategoriesYetWidget(),
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
