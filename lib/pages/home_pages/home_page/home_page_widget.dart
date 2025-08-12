import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/blank_component/blank_component_widget.dart';
import '/pages/shimmers/home_shimmer/home_shimmer_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    animationsMap.addAll({
      'columnOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.linear,
            delay: 50.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, -20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
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
      'rowOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
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
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Builder(
          builder: (context) {
            if (FFAppState().connected == true) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello,',
                                maxLines: 1,
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
                              if (FFAppState().isLogin == true)
                                Text(
                                  '${functions.capitalizeFirst('${getJsonField(
                                    FFAppState().userDetail,
                                    r'''$.firstname''',
                                  ).toString()}')} 👋',
                                  maxLines: 1,
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
                            ],
                          ).animateOnPageLoad(
                              animationsMap['columnOnPageLoadAnimation']!),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context
                                .pushNamed(NotificationsPageWidget.routeName);
                          },
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 16.0,
                                  color:
                                      FlutterFlowTheme.of(context).shadowColor,
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                )
                              ],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/notifications_FILL0_wght400_GRAD0_opsz24.svg',
                                width: 22.0,
                                height: 22.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.pushNamed(SearchPageWidget.routeName);
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16.0,
                              color: FlutterFlowTheme.of(context).shadowColor,
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 15.0, 16.0, 15.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(0.0),
                                child: SvgPicture.asset(
                                  'assets/images/search.svg',
                                  width: 24.0,
                                  height: 24.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  'Search here',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<ApiCallResponse>(
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
                          return HomeShimmerWidget();
                        }
                        final containerGetFavouriteBookResponse =
                            snapshot.data!;

                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(),
                          child: FutureBuilder<ApiCallResponse>(
                            future: FFAppState()
                                .getCategoriesCache(
                              requestFn: () =>
                                  EbookGroup.getcategoriesApiCall.call(),
                            )
                                .then((result) {
                              _model.apiRequestCompleted4 = true;
                              return result;
                            }),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return BlankComponentWidget();
                              }
                              final containerGetcategoriesApiResponse =
                                  snapshot.data!;

                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(),
                                child: FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .getTrendingBooksCache(
                                    requestFn: () => EbookGroup
                                        .getTrendingBooksApiCall
                                        .call(),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted2 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return HomeShimmerWidget();
                                    }
                                    final containerGetTrendingBooksApiResponse =
                                        snapshot.data!;

                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(),
                                      child: FutureBuilder<ApiCallResponse>(
                                        future: FFAppState()
                                            .getauthorsCache(
                                          requestFn: () => EbookGroup
                                              .getauthorsApiCall
                                              .call(),
                                        )
                                            .then((result) {
                                          _model.apiRequestCompleted5 = true;
                                          return result;
                                        }),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return HomeShimmerWidget();
                                          }
                                          final containerGetauthorsApiResponse =
                                              snapshot.data!;

                                          return Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(),
                                            child:
                                                FutureBuilder<ApiCallResponse>(
                                              future: FFAppState()
                                                  .popularBookCache(
                                                requestFn: () => EbookGroup
                                                    .getPopularBooksApiCall
                                                    .call(),
                                              )
                                                  .then((result) {
                                                _model.apiRequestCompleted3 =
                                                    true;
                                                return result;
                                              }),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return HomeShimmerWidget();
                                                }
                                                final containerGetPopularBooksApiResponse =
                                                    snapshot.data!;

                                                return Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(),
                                                  child: Builder(
                                                    builder: (context) {
                                                      if ((EbookGroup
                                                                  .getcategoriesApiCall
                                                                  .success(
                                                                containerGetcategoriesApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2) ||
                                                          (EbookGroup
                                                                  .getTrendingBooksApiCall
                                                                  .success(
                                                                containerGetTrendingBooksApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2) ||
                                                          (EbookGroup
                                                                  .getauthorsApiCall
                                                                  .success(
                                                                containerGetauthorsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2) ||
                                                          (EbookGroup
                                                                  .getPopularBooksApiCall
                                                                  .success(
                                                                containerGetPopularBooksApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2)) {
                                                        return Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        0.0,
                                                                        16.0,
                                                                        0.0),
                                                            child: Text(
                                                              valueOrDefault<
                                                                  String>(
                                                                EbookGroup
                                                                    .getTrendingBooksApiCall
                                                                    .message(
                                                                  containerGetTrendingBooksApiResponse
                                                                      .jsonBody,
                                                                ),
                                                                'Message',
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        18.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    lineHeight:
                                                                        1.5,
                                                                  ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return RefreshIndicator(
                                                          key: Key(
                                                              'RefreshIndicator_hiaxgz4b'),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          onRefresh: () async {
                                                            await Future.wait([
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetFavouriteBookCacheCache();
                                                                  _model.apiRequestCompleted1 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted1();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetCategoriesCacheCache();
                                                                  _model.apiRequestCompleted4 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted4();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetTrendingBooksCacheCache();
                                                                  _model.apiRequestCompleted2 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted2();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetauthorsCacheCache();
                                                                  _model.apiRequestCompleted5 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted5();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearPopularBookCacheCache();
                                                                  _model.apiRequestCompleted3 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted3();
                                                              }),
                                                            ]);
                                                          },
                                                          child: ListView(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            scrollDirection:
                                                                Axis.vertical,
                                                            children: [
                                                              if (FFAppState()
                                                                          .homePageLiveReadBook !=
                                                                      '')
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          16.0,
                                                                          16.0,
                                                                          16.0,
                                                                          16.0),
                                                                  child:
                                                                      InkWell(
                                                                    splashColor:
                                                                        Colors
                                                                            .transparent,
                                                                    focusColor:
                                                                        Colors
                                                                            .transparent,
                                                                    hoverColor:
                                                                        Colors
                                                                            .transparent,
                                                                    highlightColor:
                                                                        Colors
                                                                            .transparent,
                                                                    onTap:
                                                                        () async {
                                                                      context
                                                                          .pushNamed(
                                                                        ReadBookCustomPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'pdf':
                                                                              serializeParam(
                                                                            FFAppState().homePageBookPdf,
                                                                            ParamType.String,
                                                                          ),
                                                                          'id':
                                                                              serializeParam(
                                                                            FFAppState().homePageBookId,
                                                                            ParamType.String,
                                                                          ),
                                                                          'name':
                                                                              serializeParam(
                                                                            FFAppState().homePageBookName,
                                                                            ParamType.String,
                                                                          ),
                                                                          'image':
                                                                              serializeParam(
                                                                            FFAppState().homePageLiveReadBook,
                                                                            ParamType.String,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Color(
                                                                            0xFFD8F1DC),
                                                                        borderRadius:
                                                                            BorderRadius.circular(12.0),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            8.0,
                                                                            8.0,
                                                                            10.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      'Continue reading',
                                                                                      textAlign: TextAlign.start,
                                                                                      maxLines: 1,
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            fontSize: 20.0,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.bold,
                                                                                            lineHeight: 1.5,
                                                                                          ),
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 24.0),
                                                                                      child: Text(
                                                                                        'Let’s continue what you’re started!',
                                                                                        textAlign: TextAlign.start,
                                                                                        maxLines: 1,
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              fontSize: 16.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.normal,
                                                                                              lineHeight: 1.5,
                                                                                            ),
                                                                                      ),
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        children: [
                                                                                          Text(
                                                                                            'Page ${FFAppState().homePageCurrentPdfIndex.toString()} of ${FFAppState().homePageTotalPdfPageIndex.toString()}',
                                                                                            textAlign: TextAlign.start,
                                                                                            maxLines: 1,
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  fontSize: 13.0,
                                                                                                  letterSpacing: 0.0,
                                                                                                  lineHeight: 1.5,
                                                                                                ),
                                                                                          ),
                                                                                          ClipRRect(
                                                                                            borderRadius: BorderRadius.circular(0.0),
                                                                                            child: SvgPicture.asset(
                                                                                              'assets/images/arrow_right.svg',
                                                                                              width: 18.0,
                                                                                              height: 18.0,
                                                                                              fit: BoxFit.cover,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                    LinearPercentIndicator(
                                                                                      percent: valueOrDefault<double>(
                                                                                        FFAppState().homePageCurrentPdfIndex / FFAppState().homePageTotalPdfPageIndex,
                                                                                        1.0,
                                                                                      ),
                                                                                      lineHeight: 6.0,
                                                                                      animation: true,
                                                                                      animateFromLastPercent: true,
                                                                                      progressColor: FlutterFlowTheme.of(context).primaryText,
                                                                                      backgroundColor: Color(0x19000000),
                                                                                      barRadius: Radius.circular(20.0),
                                                                                      padding: EdgeInsets.zero,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            Container(
                                                                              width: 120.0,
                                                                              decoration: BoxDecoration(
                                                                                color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                borderRadius: BorderRadius.circular(12.0),
                                                                              ),
                                                                              child: Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(24.0, 11.0, 24.0, 11.0),
                                                                                child: ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(0.0),
                                                                                  child: CachedNetworkImage(
                                                                                    fadeInDuration: Duration(milliseconds: 200),
                                                                                    fadeOutDuration: Duration(milliseconds: 200),
                                                                                    imageUrl: FFAppState().homePageLiveReadBook,
                                                                                    width: 72.0,
                                                                                    height: 110.0,
                                                                                    fit: BoxFit.cover,
                                                                                    errorWidget: (context, error, stackTrace) => Image.asset(
                                                                                      'assets/images/error_image.png',
                                                                                      width: 72.0,
                                                                                      height: 110.0,
                                                                                      fit: BoxFit.cover,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ).animateOnPageLoad(
                                                                          animationsMap[
                                                                              'containerOnPageLoadAnimation']!),
                                                                ),
                                                              Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: EbookGroup
                                                                              .getcategoriesApiCall
                                                                              .categoryDetailsList(
                                                                            containerGetcategoriesApiResponse.jsonBody,
                                                                          ) !=
                                                                          null &&
                                                                      (EbookGroup
                                                                              .getcategoriesApiCall
                                                                              .categoryDetailsList(
                                                                        containerGetcategoriesApiResponse
                                                                            .jsonBody,
                                                                      ))!
                                                                          .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            16.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              'Categories',
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 20.0,
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
                                                                                context.pushNamed(CategoriesScreenWidget.routeName);
                                                                              },
                                                                              child: Text(
                                                                                'View all',
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.0,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 4.0)),
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation1']!),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final categoryDetailsList = (EbookGroup.getcategoriesApiCall
                                                                                        .categoryDetailsList(
                                                                                          containerGetcategoriesApiResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList() ??
                                                                                    [])
                                                                                .take(4)
                                                                                .toList();

                                                                            return Wrap(
                                                                              spacing: 16.0,
                                                                              runSpacing: 16.0,
                                                                              alignment: WrapAlignment.start,
                                                                              crossAxisAlignment: WrapCrossAlignment.start,
                                                                              direction: Axis.horizontal,
                                                                              runAlignment: WrapAlignment.start,
                                                                              verticalDirection: VerticalDirection.down,
                                                                              clipBehavior: Clip.none,
                                                                              children: List.generate(categoryDetailsList.length, (categoryDetailsListIndex) {
                                                                                final categoryDetailsListItem = categoryDetailsList[categoryDetailsListIndex];
                                                                                return wrapWithModel(
                                                                                  model: _model.categoryComponentModels1.getModel(
                                                                                    getJsonField(
                                                                                      categoryDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    categoryDetailsListIndex,
                                                                                  ),
                                                                                  updateCallback: () => safeSetState(() {}),
                                                                                  child: CategoryComponentWidget(
                                                                                    key: Key(
                                                                                      'Key15y_${getJsonField(
                                                                                        categoryDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString()}',
                                                                                    ),
                                                                                    image: '${FFAppConstants.imageUrl}${getJsonField(
                                                                                      categoryDetailsListItem,
                                                                                      r'''$.image''',
                                                                                    ).toString()}',
                                                                                    name: getJsonField(
                                                                                      categoryDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    isSmall: true,
                                                                                    onMainTap: () async {
                                                                                      context.pushNamed(
                                                                                        SubCategoriesScreenWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'id': serializeParam(
                                                                                            getJsonField(
                                                                                              categoryDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'name': serializeParam(
                                                                                            getJsonField(
                                                                                              categoryDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                        }.withoutNulls,
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                ).animateOnPageLoad(animationsMap['categoryComponentOnPageLoadAnimation']!);
                                                                              }),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: EbookGroup
                                                                              .getTrendingBooksApiCall
                                                                              .bookDetailsList(
                                                                            containerGetTrendingBooksApiResponse.jsonBody,
                                                                          ) !=
                                                                          null &&
                                                                      (EbookGroup
                                                                              .getTrendingBooksApiCall
                                                                              .bookDetailsList(
                                                                        containerGetTrendingBooksApiResponse
                                                                            .jsonBody,
                                                                      ))!
                                                                          .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.all(16.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Text(
                                                                              'Trending books',
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 20.0,
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
                                                                                context.pushNamed(TrendingBooksPageWidget.routeName);
                                                                              },
                                                                              child: Text(
                                                                                'View all',
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.0,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation2']!),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final trendbookDetailsList = (EbookGroup.getTrendingBooksApiCall
                                                                                        .bookDetailsList(
                                                                                          containerGetTrendingBooksApiResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList() ??
                                                                                    [])
                                                                                .take(2)
                                                                                .toList();

                                                                            return Wrap(
                                                                              spacing: 16.0,
                                                                              runSpacing: 16.0,
                                                                              alignment: WrapAlignment.start,
                                                                              crossAxisAlignment: WrapCrossAlignment.start,
                                                                              direction: Axis.horizontal,
                                                                              runAlignment: WrapAlignment.start,
                                                                              verticalDirection: VerticalDirection.down,
                                                                              clipBehavior: Clip.none,
                                                                              children: List.generate(trendbookDetailsList.length, (trendbookDetailsListIndex) {
                                                                                final trendbookDetailsListItem = trendbookDetailsList[trendbookDetailsListIndex];
                                                                                return wrapWithModel(
                                                                                  model: _model.mainBookComponentModels.getModel(
                                                                                    getJsonField(
                                                                                      trendbookDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    trendbookDetailsListIndex,
                                                                                  ),
                                                                                  updateCallback: () => safeSetState(() {}),
                                                                                  child: MainBookComponentWidget(
                                                                                    key: Key(
                                                                                      'Key0kh_${getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString()}',
                                                                                    ),
                                                                                    image: '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                      trendbookDetailsListItem,
                                                                                      r'''$.image''',
                                                                                    ).toString()}',
                                                                                    bookName: getJsonField(
                                                                                      trendbookDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    authorsName: getJsonField(
                                                                                      trendbookDetailsListItem,
                                                                                      r'''$.author.name''',
                                                                                    ).toString(),
                                                                                    isFav: functions.checkFavOrNot(
                                                                                            EbookGroup.getFavouriteBookCall
                                                                                                .favouriteBookDetailsList(
                                                                                                  containerGetFavouriteBookResponse.jsonBody,
                                                                                                )
                                                                                                ?.toList(),
                                                                                            getJsonField(
                                                                                              trendbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString()) ==
                                                                                        true,
                                                                                    indicator: (trendbookDetailsListIndex == _model.trendingIndex) && (_model.isTrending == true),
                                                                                    isFavAction: () async {
                                                                                      if (FFAppState().isLogin == true) {
                                                                                        _model.isTrending = true;
                                                                                        _model.trendingIndex = trendbookDetailsListIndex;
                                                                                        safeSetState(() {});
                                                                                        if (functions.checkFavOrNot(
                                                                                                EbookGroup.getFavouriteBookCall
                                                                                                    .favouriteBookDetailsList(
                                                                                                      containerGetFavouriteBookResponse.jsonBody,
                                                                                                    )
                                                                                                    ?.toList(),
                                                                                                getJsonField(
                                                                                                  trendbookDetailsListItem,
                                                                                                  r'''$._id''',
                                                                                                ).toString()) ==
                                                                                            true) {
                                                                                          _model.getPopularHomeDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                                            userId: FFAppState().userId,
                                                                                            token: FFAppState().token,
                                                                                            bookId: getJsonField(
                                                                                              trendbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                          );

                                                                                          safeSetState(() {
                                                                                            FFAppState().clearGetFavouriteBookCacheCache();
                                                                                            _model.apiRequestCompleted1 = false;
                                                                                          });
                                                                                          await _model.waitForApiRequestCompleted1();
                                                                                          await actions.showCustomToastBottom(
                                                                                            FFAppState().unFavText,
                                                                                          );
                                                                                        } else {
                                                                                          _model.getPopularHomeAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                                                            userId: FFAppState().userId,
                                                                                            token: FFAppState().token,
                                                                                            bookId: getJsonField(
                                                                                              trendbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                          );

                                                                                          safeSetState(() {
                                                                                            FFAppState().clearGetFavouriteBookCacheCache();
                                                                                            _model.apiRequestCompleted1 = false;
                                                                                          });
                                                                                          await _model.waitForApiRequestCompleted1();
                                                                                          await actions.showCustomToastBottom(
                                                                                            FFAppState().favText,
                                                                                          );
                                                                                        }

                                                                                        FFAppState().clearGetFavouriteBookCacheCache();
                                                                                        _model.isTrending = false;
                                                                                        safeSetState(() {});
                                                                                      } else {
                                                                                        FFAppState().favChange = true;
                                                                                        FFAppState().bookId = getJsonField(
                                                                                          trendbookDetailsListItem,
                                                                                          r'''$._id''',
                                                                                        ).toString();
                                                                                        FFAppState().update(() {});

                                                                                        context.pushNamed(SignInPageWidget.routeName);
                                                                                      }

                                                                                      safeSetState(() {});
                                                                                    },
                                                                                    isMainTap: () async {
                                                                                      context.pushNamed(
                                                                                        BookDetailspageWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'name': serializeParam(
                                                                                            getJsonField(
                                                                                              trendbookDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'image': serializeParam(
                                                                                            '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                              trendbookDetailsListItem,
                                                                                              r'''$.image''',
                                                                                            ).toString()}',
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'id': serializeParam(
                                                                                            getJsonField(
                                                                                              trendbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
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
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: EbookGroup
                                                                              .getauthorsApiCall
                                                                              .authorDetailsList(
                                                                            containerGetauthorsApiResponse.jsonBody,
                                                                          ) !=
                                                                          null &&
                                                                      (EbookGroup
                                                                              .getauthorsApiCall
                                                                              .authorDetailsList(
                                                                        containerGetauthorsApiResponse
                                                                            .jsonBody,
                                                                      ))!
                                                                          .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.all(16.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              'Best authors',
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 20.0,
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
                                                                                context.pushNamed(BestAuthorPageWidget.routeName);
                                                                              },
                                                                              child: Text(
                                                                                'View all',
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.0,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 4.0)),
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation3']!),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final authorDetailsList = (EbookGroup.getauthorsApiCall
                                                                                        .authorDetailsList(
                                                                                          containerGetauthorsApiResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList() ??
                                                                                    [])
                                                                                .take(4)
                                                                                .toList();

                                                                            return Wrap(
                                                                              spacing: 16.0,
                                                                              runSpacing: 16.0,
                                                                              alignment: WrapAlignment.start,
                                                                              crossAxisAlignment: WrapCrossAlignment.start,
                                                                              direction: Axis.horizontal,
                                                                              runAlignment: WrapAlignment.start,
                                                                              verticalDirection: VerticalDirection.down,
                                                                              clipBehavior: Clip.none,
                                                                              children: List.generate(authorDetailsList.length, (authorDetailsListIndex) {
                                                                                final authorDetailsListItem = authorDetailsList[authorDetailsListIndex];
                                                                                return wrapWithModel(
                                                                                  model: _model.categoryComponentModels2.getModel(
                                                                                    getJsonField(
                                                                                      authorDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    authorDetailsListIndex,
                                                                                  ),
                                                                                  updateCallback: () => safeSetState(() {}),
                                                                                  child: CategoryComponentWidget(
                                                                                    key: Key(
                                                                                      'Keywz2_${getJsonField(
                                                                                        authorDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString()}',
                                                                                    ),
                                                                                    image: '${FFAppConstants.imageUrl}${getJsonField(
                                                                                      authorDetailsListItem,
                                                                                      r'''$.image''',
                                                                                    ).toString()}',
                                                                                    name: getJsonField(
                                                                                      authorDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    isSmall: true,
                                                                                    onMainTap: () async {
                                                                                      context.pushNamed(
                                                                                        AboutAuthorPageWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'name': serializeParam(
                                                                                            getJsonField(
                                                                                              authorDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'authorImage': serializeParam(
                                                                                            '${FFAppConstants.imageUrl}${getJsonField(
                                                                                              authorDetailsListItem,
                                                                                              r'''$.image''',
                                                                                            ).toString()}',
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'authorId': serializeParam(
                                                                                            getJsonField(
                                                                                              authorDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
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
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: EbookGroup
                                                                              .getPopularBooksApiCall
                                                                              .bookDetailsList(
                                                                            containerGetPopularBooksApiResponse.jsonBody,
                                                                          ) !=
                                                                          null &&
                                                                      (EbookGroup
                                                                              .getPopularBooksApiCall
                                                                              .bookDetailsList(
                                                                        containerGetPopularBooksApiResponse
                                                                            .jsonBody,
                                                                      ))!
                                                                          .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            16.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              'Popular books',
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 20.0,
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
                                                                                context.pushNamed(PopularBooksPageWidget.routeName);
                                                                              },
                                                                              child: Text(
                                                                                'View all',
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.0,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 4.0)),
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation4']!),
                                                                      ),
                                                                      Container(
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            172.0,
                                                                        decoration:
                                                                            BoxDecoration(),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final popularbookDetailsList = (EbookGroup.getPopularBooksApiCall
                                                                                        .bookDetailsList(
                                                                                          containerGetPopularBooksApiResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList() ??
                                                                                    [])
                                                                                .take(2)
                                                                                .toList();

                                                                            return SingleChildScrollView(
                                                                              scrollDirection: Axis.horizontal,
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: List.generate(popularbookDetailsList.length, (popularbookDetailsListIndex) {
                                                                                  final popularbookDetailsListItem = popularbookDetailsList[popularbookDetailsListIndex];
                                                                                  return Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
                                                                                    child: wrapWithModel(
                                                                                      model: _model.listMainContainerComponentModels.getModel(
                                                                                        getJsonField(
                                                                                          popularbookDetailsListItem,
                                                                                          r'''$.name''',
                                                                                        ).toString(),
                                                                                        popularbookDetailsListIndex,
                                                                                      ),
                                                                                      updateCallback: () => safeSetState(() {}),
                                                                                      child: ListMainContainerComponentWidget(
                                                                                        key: Key(
                                                                                          'Key9t2_${getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.name''',
                                                                                          ).toString()}',
                                                                                        ),
                                                                                        image: '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                          popularbookDetailsListItem,
                                                                                          r'''$.image''',
                                                                                        ).toString()}',
                                                                                        name: getJsonField(
                                                                                          popularbookDetailsListItem,
                                                                                          r'''$.name''',
                                                                                        ).toString(),
                                                                                        authorName: getJsonField(
                                                                                          popularbookDetailsListItem,
                                                                                          r'''$.author.name''',
                                                                                        ).toString(),
                                                                                        averageRating: getJsonField(
                                                                                          popularbookDetailsListItem,
                                                                                          r'''$.averageRating''',
                                                                                        ).toDouble(),
                                                                                        isFav: functions.checkFavOrNot(
                                                                                                EbookGroup.getFavouriteBookCall
                                                                                                    .favouriteBookDetailsList(
                                                                                                      containerGetFavouriteBookResponse.jsonBody,
                                                                                                    )
                                                                                                    ?.toList(),
                                                                                                getJsonField(
                                                                                                  popularbookDetailsListItem,
                                                                                                  r'''$._id''',
                                                                                                ).toString()) ==
                                                                                            true,
                                                                                        indicator: (popularbookDetailsListIndex == _model.popularIndex) && (_model.isPopular == true),
                                                                                        width: 330.0,
                                                                                        isFavAction: () async {
                                                                                          if (FFAppState().isLogin == true) {
                                                                                            _model.isPopular = true;
                                                                                            _model.popularIndex = popularbookDetailsListIndex;
                                                                                            safeSetState(() {});
                                                                                            if (functions.checkFavOrNot(
                                                                                                    EbookGroup.getFavouriteBookCall
                                                                                                        .favouriteBookDetailsList(
                                                                                                          containerGetFavouriteBookResponse.jsonBody,
                                                                                                        )
                                                                                                        ?.toList(),
                                                                                                    getJsonField(
                                                                                                      popularbookDetailsListItem,
                                                                                                      r'''$._id''',
                                                                                                    ).toString()) ==
                                                                                                true) {
                                                                                              _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                                                userId: FFAppState().userId,
                                                                                                token: FFAppState().token,
                                                                                                bookId: getJsonField(
                                                                                                  popularbookDetailsListItem,
                                                                                                  r'''$._id''',
                                                                                                ).toString(),
                                                                                              );

                                                                                              safeSetState(() {
                                                                                                FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                _model.apiRequestCompleted1 = false;
                                                                                              });
                                                                                              await _model.waitForApiRequestCompleted1();
                                                                                              await actions.showCustomToastBottom(
                                                                                                FFAppState().unFavText,
                                                                                              );
                                                                                            } else {
                                                                                              _model.getPopularAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                                                                userId: FFAppState().userId,
                                                                                                token: FFAppState().token,
                                                                                                bookId: getJsonField(
                                                                                                  popularbookDetailsListItem,
                                                                                                  r'''$._id''',
                                                                                                ).toString(),
                                                                                              );

                                                                                              safeSetState(() {
                                                                                                FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                _model.apiRequestCompleted1 = false;
                                                                                              });
                                                                                              await _model.waitForApiRequestCompleted1();
                                                                                              await actions.showCustomToastBottom(
                                                                                                FFAppState().favText,
                                                                                              );
                                                                                            }

                                                                                            FFAppState().clearGetFavouriteBookCacheCache();
                                                                                            _model.isPopular = false;
                                                                                            safeSetState(() {});
                                                                                          } else {
                                                                                            FFAppState().favChange = true;
                                                                                            FFAppState().bookId = getJsonField(
                                                                                              popularbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString();
                                                                                            FFAppState().update(() {});

                                                                                            context.pushNamed(SignInPageWidget.routeName);
                                                                                          }

                                                                                          safeSetState(() {});
                                                                                        },
                                                                                        onMainTap: () async {
                                                                                          context.pushNamed(
                                                                                            BookDetailspageWidget.routeName,
                                                                                            queryParameters: {
                                                                                              'name': serializeParam(
                                                                                                getJsonField(
                                                                                                  popularbookDetailsListItem,
                                                                                                  r'''$.name''',
                                                                                                ).toString(),
                                                                                                ParamType.String,
                                                                                              ),
                                                                                              'image': serializeParam(
                                                                                                '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                                  popularbookDetailsListItem,
                                                                                                  r'''$.image''',
                                                                                                ).toString()}',
                                                                                                ParamType.String,
                                                                                              ),
                                                                                              'id': serializeParam(
                                                                                                getJsonField(
                                                                                                  popularbookDetailsListItem,
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
                                                                                }).divide(SizedBox(width: 16.0)).addToStart(SizedBox(width: 16.0)).addToEnd(SizedBox(width: 16.0)),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ].addToStart(SizedBox(height: 24.0)),
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
    );
  }
}
