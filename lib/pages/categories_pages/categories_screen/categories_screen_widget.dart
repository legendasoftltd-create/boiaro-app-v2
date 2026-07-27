import 'dart:async';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/empty_components/no_categories_yet/no_categories_yet_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'categories_screen_model.dart';
export 'categories_screen_model.dart';

class CategoriesScreenWidget extends StatefulWidget {
  const CategoriesScreenWidget({super.key});

  static String routeName = 'CategoriesScreen';
  static String routePath = '/categoriesScreen';

  @override
  State<CategoriesScreenWidget> createState() => _CategoriesScreenWidgetState();
}

class _CategoriesScreenWidgetState extends State<CategoriesScreenWidget>
    with TickerProviderStateMixin {
  late CategoriesScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebouncer;
  String _searchQuery = '';

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoriesScreenModel());

    animationsMap.addAll({
      'categoryComponentOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 50.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _searchController.dispose();
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
                  title: FFLocalizations.of(context).getVariableText(enText: 'Categories', bnText: 'ক্যাটাগরি'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchDebouncer?.cancel();
                    _searchDebouncer = Timer(const Duration(milliseconds: 400), () {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    });
                  },
                  decoration: InputDecoration(
                    hintText: FFLocalizations.of(context).getVariableText(enText: 'Search category...', bnText: 'ক্যাটাগরি খুঁজুন...'),
                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: FlutterFlowTheme.of(context).secondaryText),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: EbookGroup.getcategoriesApiCall.call(
                          search: _searchQuery,
                        )
                            .then((result) {
                          _model.apiRequestCompleted = true;
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
                          final containerGetcategoriesApiResponse =
                              snapshot.data!;

                          return Container(
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getcategoriesApiCall.success(
                                      containerGetcategoriesApiResponse
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
                                          EbookGroup.getcategoriesApiCall
                                              .message(
                                            containerGetcategoriesApiResponse
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
                                      if (EbookGroup.getcategoriesApiCall
                                                  .categoryDetailsList(
                                                containerGetcategoriesApiResponse
                                                    .jsonBody,
                                              ) !=
                                              null &&
                                          (EbookGroup.getcategoriesApiCall
                                                  .categoryDetailsList(
                                            containerGetcategoriesApiResponse
                                                .jsonBody,
                                          ))!
                                              .isNotEmpty) {
                                        return RefreshIndicator(
                                          key: Key('RefreshIndicator_u0crgoqx'),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          onRefresh: () async {
                                            safeSetState(() {
                                              FFAppState()
                                                  .clearGetCategoriesCacheCache();
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
                                                    final categoryDetailsList =
                                                        EbookGroup
                                                                .getcategoriesApiCall
                                                                .categoryDetailsList(
                                                                  containerGetcategoriesApiResponse
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
                                                          categoryDetailsList
                                                              .length,
                                                          (categoryDetailsListIndex) {
                                                        final categoryDetailsListItem =
                                                            categoryDetailsList[
                                                                categoryDetailsListIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .categoryComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              categoryDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            categoryDetailsListIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              CategoryComponentWidget(
                                                            key: Key(
                                                              'Keyfv8_${getJsonField(
                                                                categoryDetailsListItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            icon:
                                                                '${FFAppConstants.imageUrl}${getJsonField(
                                                              categoryDetailsListItem,
                                                              r'''$.icon''',
                                                            ).toString()}',
                                                            name: getJsonField(
                                                              categoryDetailsListItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            isSmall: true,
                                                            onMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                SubCategoriesScreenWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'id':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      categoryDetailsListItem,
                                                                      r'''$._id''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      categoryDetailsListItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                          ),
                                                        ).animateOnPageLoad(
                                                            animationsMap[
                                                                'categoryComponentOnPageLoadAnimation']!);
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
