import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/dialogs/book_review_bottom_sheet/book_review_bottom_sheet_widget.dart';
import '/pages/empty_components/blank_component/blank_component_widget.dart';
import '/pages/shimmers/book_detail_shimmer/book_detail_shimmer_widget.dart';
import '/pages/shimmers/button_detail_page_shimmer/button_detail_page_shimmer_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'book_detailspage_model.dart';
export 'book_detailspage_model.dart';

class BookDetailspageWidget extends StatefulWidget {
  const BookDetailspageWidget({
    super.key,
    required this.name,
    required this.image,
    required this.id,
  });

  final String? name;
  final String? image;
  final String? id;

  static String routeName = 'BookDetailspage';
  static String routePath = '/bookDetailspage';

  @override
  State<BookDetailspageWidget> createState() => _BookDetailspageWidgetState();
}

class _BookDetailspageWidgetState extends State<BookDetailspageWidget> {
  late BookDetailspageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BookDetailspageModel());

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

    return FutureBuilder<ApiCallResponse>(
      future: EbookGroup.getbookdetailsApiCall.call(
        bookId: widget.id,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              child: BookDetailShimmerWidget(),
            ),
          );
        }
        final bookDetailspageGetbookdetailsApiResponse = snapshot.data!;

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: Builder(
            builder: (context) {
              if (EbookGroup.getbookdetailsApiCall.success(
                    bookDetailspageGetbookdetailsApiResponse.jsonBody,
                  ) ==
                  2) {
                return Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Text(
                      valueOrDefault<String>(
                        EbookGroup.getbookdetailsApiCall.message(
                          bookDetailspageGetbookdetailsApiResponse.jsonBody,
                        ),
                        'Message',
                      ),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                return FutureBuilder<ApiCallResponse>(
                  future: (_model.apiRequestCompleter1 ??=
                          Completer<ApiCallResponse>()
                            ..complete(EbookGroup.getFavouriteBookCall.call(
                              userId: FFAppState().userId,
                              token: FFAppState().token,
                            )))
                      .future,
                  builder: (context, snapshot) {
                    // Customize what your widget looks like when it's loading.
                    if (!snapshot.hasData) {
                      return Container(
                        width: double.infinity,
                        child: BookDetailShimmerWidget(),
                      );
                    }
                    final columnGetFavouriteBookResponse = snapshot.data!;

                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            key: Key('RefreshIndicator_dqubpoxi'),
                            color: FlutterFlowTheme.of(context).primary,
                            onRefresh: () async {
                              safeSetState(() {
                                FFAppState().clearGetReviewCacheCacheKey(
                                    _model.apiRequestLastUniqueKey2);
                                _model.apiRequestCompleted2 = false;
                              });
                              await _model.waitForApiRequestCompleted2();
                            },
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                0,
                                0,
                                0,
                                16.0,
                              ),
                              scrollDirection: Axis.vertical,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 480.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(30.0),
                                          bottomRight: Radius.circular(30.0),
                                          topLeft: Radius.circular(0.0),
                                          topRight: Radius.circular(0.0),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 119.0, 16.0, 24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  PageTransition(
                                                    type:
                                                        PageTransitionType.fade,
                                                    child:
                                                        FlutterFlowExpandedImageView(
                                                      image: CachedNetworkImage(
                                                        fadeInDuration:
                                                            Duration(
                                                                milliseconds:
                                                                    200),
                                                        fadeOutDuration:
                                                            Duration(
                                                                milliseconds:
                                                                    200),
                                                        imageUrl:
                                                            widget.image!,
                                                        fit: BoxFit.contain,
                                                        alignment:
                                                            Alignment(0.0, 0.0),
                                                        errorWidget: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Image.asset(
                                                          'assets/images/error_image.png',
                                                          fit: BoxFit.contain,
                                                          alignment: Alignment(
                                                              0.0, 0.0),
                                                        ),
                                                      ),
                                                      allowRotation: false,
                                                      useHeroAnimation: false,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0.0),
                                                child: CachedNetworkImage(
                                                  fadeInDuration: Duration(
                                                      milliseconds: 200),
                                                  fadeOutDuration: Duration(
                                                      milliseconds: 200),
                                                  imageUrl: widget.image!,
                                                  width: 181.0,
                                                  height: 258.0,
                                                  fit: BoxFit.fitWidth,
                                                  alignment:
                                                      Alignment(0.0, 0.0),
                                                  errorWidget: (context, error,
                                                          stackTrace) =>
                                                      Image.asset(
                                                    'assets/images/error_image.png',
                                                    width: 181.0,
                                                    height: 258.0,
                                                    fit: BoxFit.fitWidth,
                                                    alignment:
                                                        Alignment(0.0, 0.0),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              valueOrDefault<String>(
                                                widget.name,
                                                'Book',
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        fontSize: 24.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        lineHeight: 1.5,
                                                      ),
                                            ),
                                            Text(
                                              'By ${EbookGroup.getbookdetailsApiCall.authorName(
                                                bookDetailspageGetbookdetailsApiResponse
                                                    .jsonBody,
                                              )}',
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 15.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        lineHeight: 1.5,
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SafeArea(
                                      child: Container(
                                        decoration: BoxDecoration(),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 16.0, 16.0, 0.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  context.safePop();
                                                },
                                                child: Container(
                                                  width: 44.0,
                                                  height: 44.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment:
                                                      AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            0.0),
                                                    child: SvgPicture.asset(
                                                      'assets/images/arrow_left.svg',
                                                      width: 24.0,
                                                      height: 24.0,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                12.0, 0.0),
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
                                                        if (FFAppState()
                                                                .isLogin ==
                                                            true) {
                                                          if (EbookGroup
                                                                  .getbookdetailsApiCall
                                                                  .accesstype(
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              'free') {
                                                            _model.downloadApiFunction =
                                                                await EbookGroup
                                                                    .downloadpdfApiCall
                                                                    .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              bookId:
                                                                  widget.id,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                            );

                                                            if (EbookGroup
                                                                    .downloadpdfApiCall
                                                                    .success(
                                                                  (_model.downloadApiFunction
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                ) ==
                                                                1) {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    EbookGroup
                                                                        .downloadpdfApiCall
                                                                        .message(
                                                                      (_model.downloadApiFunction
                                                                              ?.jsonBody ??
                                                                          ''),
                                                                    )!,
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                    ),
                                                                  ),
                                                                  duration: Duration(
                                                                      milliseconds:
                                                                          2000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                ),
                                                              );
                                                              FFAppState()
                                                                      .pdfPathSave =
                                                                  EbookGroup
                                                                      .getbookdetailsApiCall
                                                                      .pdf(
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                              )!;
                                                              FFAppState()
                                                                  .update(
                                                                      () {});
                                                              await actions
                                                                  .downloadFile(
                                                                '${FFAppConstants.bookImagesUrl}${EbookGroup.getbookdetailsApiCall.pdf(
                                                                  bookDetailspageGetbookdetailsApiResponse
                                                                      .jsonBody,
                                                                )}',
                                                                EbookGroup
                                                                    .getbookdetailsApiCall
                                                                    .pdf(
                                                                  bookDetailspageGetbookdetailsApiResponse
                                                                      .jsonBody,
                                                                )!,
                                                              );
                                                              safeSetState(() =>
                                                                  _model.apiRequestCompleter3 =
                                                                      null);
                                                              await _model
                                                                  .waitForApiRequestCompleted3();
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    EbookGroup
                                                                        .downloadpdfApiCall
                                                                        .message(
                                                                      (_model.downloadApiFunction
                                                                              ?.jsonBody ??
                                                                          ''),
                                                                    )!,
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                    ),
                                                                  ),
                                                                  duration: Duration(
                                                                      milliseconds:
                                                                          2000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                ),
                                                              );
                                                            }
                                                          } else {
                                                            FFAppState()
                                                                    .pdfPathSave =
                                                                EbookGroup
                                                                    .getbookdetailsApiCall
                                                                    .pdf(
                                                              bookDetailspageGetbookdetailsApiResponse
                                                                  .jsonBody,
                                                            )!;
                                                            FFAppState()
                                                                .update(() {});
                                                            _model.userdownloadvalidity =
                                                                await EbookGroup
                                                                    .usersubscriptionvalidityApiCall
                                                                    .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                            );

                                                            if (EbookGroup
                                                                    .usersubscriptionvalidityApiCall
                                                                    .daysLeft(
                                                                  (_model.userdownloadvalidity
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                ) ==
                                                                null) {
                                                              context.pushNamed(
                                                                  SubscriptionPageWidget
                                                                      .routeName);

                                                              safeSetState(() =>
                                                                  _model.apiRequestCompleter3 =
                                                                      null);
                                                              await _model
                                                                  .waitForApiRequestCompleted3();
                                                            } else {
                                                              if (EbookGroup
                                                                      .usersubscriptionvalidityApiCall
                                                                      .daysLeft(
                                                                    (_model.userdownloadvalidity
                                                                            ?.jsonBody ??
                                                                        ''),
                                                                  )! >
                                                                  0) {
                                                                _model.downloadApiFunctionPaid =
                                                                    await EbookGroup
                                                                        .downloadpdfApiCall
                                                                        .call(
                                                                  userId:
                                                                      FFAppState()
                                                                          .userId,
                                                                  bookId:
                                                                      widget
                                                                          .id,
                                                                  token:
                                                                      FFAppState()
                                                                          .token,
                                                                );

                                                                if (EbookGroup
                                                                        .downloadpdfApiCall
                                                                        .success(
                                                                      (_model.downloadApiFunctionPaid
                                                                              ?.jsonBody ??
                                                                          ''),
                                                                    ) ==
                                                                    1) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content:
                                                                          Text(
                                                                        EbookGroup
                                                                            .downloadpdfApiCall
                                                                            .message(
                                                                          (_model.downloadApiFunctionPaid?.jsonBody ??
                                                                              ''),
                                                                        )!,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                        ),
                                                                      ),
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              2000),
                                                                      backgroundColor:
                                                                          FlutterFlowTheme.of(context)
                                                                              .secondary,
                                                                    ),
                                                                  );
                                                                  FFAppState()
                                                                          .pdfPathSave =
                                                                      EbookGroup
                                                                          .getbookdetailsApiCall
                                                                          .pdf(
                                                                    bookDetailspageGetbookdetailsApiResponse
                                                                        .jsonBody,
                                                                  )!;
                                                                  FFAppState()
                                                                      .update(
                                                                          () {});
                                                                  await actions
                                                                      .downloadFile(
                                                                    '${FFAppConstants.bookImagesUrl}${EbookGroup.getbookdetailsApiCall.pdf(
                                                                      bookDetailspageGetbookdetailsApiResponse
                                                                          .jsonBody,
                                                                    )}',
                                                                    EbookGroup
                                                                        .getbookdetailsApiCall
                                                                        .pdf(
                                                                      bookDetailspageGetbookdetailsApiResponse
                                                                          .jsonBody,
                                                                    )!,
                                                                  );
                                                                  safeSetState(() =>
                                                                      _model.apiRequestCompleter3 =
                                                                          null);
                                                                  await _model
                                                                      .waitForApiRequestCompleted3();
                                                                } else {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content:
                                                                          Text(
                                                                        EbookGroup
                                                                            .downloadpdfApiCall
                                                                            .message(
                                                                          (_model.downloadApiFunctionPaid?.jsonBody ??
                                                                              ''),
                                                                        )!,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                        ),
                                                                      ),
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              2000),
                                                                      backgroundColor:
                                                                          FlutterFlowTheme.of(context)
                                                                              .secondary,
                                                                    ),
                                                                  );
                                                                }
                                                              } else {
                                                                context.pushNamed(
                                                                    SubscriptionPageWidget
                                                                        .routeName);

                                                                safeSetState(() =>
                                                                    _model.apiRequestCompleter3 =
                                                                        null);
                                                                await _model
                                                                    .waitForApiRequestCompleted3();
                                                              }
                                                            }
                                                          }
                                                        } else {
                                                          context.pushNamed(
                                                              SignInPageWidget
                                                                  .routeName);
                                                        }

                                                        safeSetState(() {});
                                                      },
                                                      child: Container(
                                                        width: 44.0,
                                                        height: 44.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryBackground,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      0.0),
                                                          child:
                                                              SvgPicture.asset(
                                                            'assets/images/download.svg',
                                                            width: 24.0,
                                                            height: 24.0,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      if (FFAppState()
                                                              .isLogin ==
                                                          true) {
                                                        _model.isProgress =
                                                            true;
                                                        safeSetState(() {});
                                                        if (functions
                                                                .checkFavOrNot(
                                                                    EbookGroup
                                                                        .getFavouriteBookCall
                                                                        .favouriteBookDetailsList(
                                                                          columnGetFavouriteBookResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList(),
                                                                    EbookGroup
                                                                        .getbookdetailsApiCall
                                                                        .id(
                                                                      bookDetailspageGetbookdetailsApiResponse
                                                                          .jsonBody,
                                                                    )) ==
                                                            true) {
                                                          _model.getDetailBookDetete =
                                                              await EbookGroup
                                                                  .removeFavouritebookCall
                                                                  .call(
                                                            userId: FFAppState()
                                                                .userId,
                                                            token: FFAppState()
                                                                .token,
                                                            bookId: EbookGroup
                                                                .getbookdetailsApiCall
                                                                .id(
                                                              bookDetailspageGetbookdetailsApiResponse
                                                                  .jsonBody,
                                                            ),
                                                          );

                                                          safeSetState(() =>
                                                              _model.apiRequestCompleter1 =
                                                                  null);
                                                          await _model
                                                              .waitForApiRequestCompleted1();
                                                          await actions
                                                              .showCustomToastBottom(
                                                            FFAppState()
                                                                .unFavText,
                                                          );
                                                        } else {
                                                          _model.getDetailBookAdd =
                                                              await EbookGroup
                                                                  .addFavouriteBookApiCall
                                                                  .call(
                                                            userId: FFAppState()
                                                                .userId,
                                                            token: FFAppState()
                                                                .token,
                                                            bookId: EbookGroup
                                                                .getbookdetailsApiCall
                                                                .id(
                                                              bookDetailspageGetbookdetailsApiResponse
                                                                  .jsonBody,
                                                            ),
                                                          );

                                                          safeSetState(() =>
                                                              _model.apiRequestCompleter1 =
                                                                  null);
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
                                                        _model.isProgress =
                                                            false;
                                                        safeSetState(() {});
                                                      } else {
                                                        FFAppState().favChange =
                                                            true;
                                                        FFAppState().bookId =
                                                            EbookGroup
                                                                .getbookdetailsApiCall
                                                                .id(
                                                          bookDetailspageGetbookdetailsApiResponse
                                                              .jsonBody,
                                                        )!;
                                                        FFAppState()
                                                            .update(() {});

                                                        context.pushNamed(
                                                            SignInPageWidget
                                                                .routeName);
                                                      }

                                                      safeSetState(() {});
                                                    },
                                                    child: Container(
                                                      width: 44.0,
                                                      height: 44.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Builder(
                                                        builder: (context) {
                                                          if (!_model
                                                              .isProgress!) {
                                                            return Builder(
                                                              builder:
                                                                  (context) {
                                                                if (functions.checkFavOrNot(
                                                                        EbookGroup.getFavouriteBookCall
                                                                            .favouriteBookDetailsList(
                                                                              columnGetFavouriteBookResponse.jsonBody,
                                                                            )
                                                                            ?.toList(),
                                                                        EbookGroup.getbookdetailsApiCall.id(
                                                                          bookDetailspageGetbookdetailsApiResponse
                                                                              .jsonBody,
                                                                        )) ==
                                                                    true) {
                                                                  return Icon(
                                                                    Icons
                                                                        .favorite_sharp,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    size: 24.0,
                                                                  );
                                                                } else {
                                                                  return Icon(
                                                                    Icons
                                                                        .favorite_border_rounded,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    size: 24.0,
                                                                  );
                                                                }
                                                              },
                                                            );
                                                          } else {
                                                            return Container(
                                                              width: 24.0,
                                                              height: 24.0,
                                                              child: custom_widgets
                                                                  .CirculatIndicator(
                                                                width: 24.0,
                                                                height: 24.0,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 16.0, 16.0, 8.0),
                                  child: Text(
                                    'About the book',
                                    textAlign: TextAlign.start,
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
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    child: custom_widgets.ReadMoreHtml(
                                      width: double.infinity,
                                      height: 80.0,
                                      htmlContent: EbookGroup
                                          .getbookdetailsApiCall
                                          .description(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                      ),
                                      maxLength: 150,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 8.0, 16.0, 16.0),
                                  child: Text(
                                    'Information',
                                    textAlign: TextAlign.start,
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
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 16.0,
                                          color: FlutterFlowTheme.of(context)
                                              .shadowColor,
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
                                          16.0, 16.0, 19.0, 15.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Language',
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 15.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                                Text(
                                                  valueOrDefault<String>(
                                                    EbookGroup
                                                        .getbookdetailsApiCall
                                                        .language(
                                                      bookDetailspageGetbookdetailsApiResponse
                                                          .jsonBody,
                                                    ),
                                                    'Language',
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        fontSize: 17.0,
                                                        letterSpacing: 0.0,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                              ].divide(SizedBox(height: 8.0)),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Rating',
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 15.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.0),
                                                      child: Image.asset(
                                                        'assets/images/star.png',
                                                        width: 21.0,
                                                        height: 21.0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  2.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        valueOrDefault<String>(
                                                          EbookGroup
                                                              .getbookdetailsApiCall
                                                              .averageRating(
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                              )
                                                              ?.toString(),
                                                          '5',
                                                        ),
                                                        maxLines: 1,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 17.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ].divide(SizedBox(height: 8.0)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 16.0, 16.0, 16.0),
                                  child: Text(
                                    'About author',
                                    textAlign: TextAlign.start,
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
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                        AboutAuthorPageWidget.routeName,
                                        queryParameters: {
                                          'name': serializeParam(
                                            valueOrDefault<String>(
                                              EbookGroup.getbookdetailsApiCall
                                                  .authorName(
                                                bookDetailspageGetbookdetailsApiResponse
                                                    .jsonBody,
                                              ),
                                              'Name',
                                            ),
                                            ParamType.String,
                                          ),
                                          'authorImage': serializeParam(
                                            '${FFAppConstants.imageUrl}${EbookGroup.getbookdetailsApiCall.authorimage(
                                              bookDetailspageGetbookdetailsApiResponse
                                                  .jsonBody,
                                            )}',
                                            ParamType.String,
                                          ),
                                          'authorId': serializeParam(
                                            EbookGroup.getbookdetailsApiCall
                                                .authorid(
                                              bookDetailspageGetbookdetailsApiResponse
                                                  .jsonBody,
                                            ),
                                            ParamType.String,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 16.0,
                                            color: FlutterFlowTheme.of(context)
                                                .shadowColor,
                                            offset: Offset(
                                              0.0,
                                              4.0,
                                            ),
                                          )
                                        ],
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 58.0,
                                              height: 58.0,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: CachedNetworkImage(
                                                fadeInDuration:
                                                    Duration(milliseconds: 200),
                                                fadeOutDuration:
                                                    Duration(milliseconds: 200),
                                                imageUrl:
                                                    '${FFAppConstants.imageUrl}${EbookGroup.getbookdetailsApiCall.authorimage(
                                                  bookDetailspageGetbookdetailsApiResponse
                                                      .jsonBody,
                                                )}',
                                                fit: BoxFit.cover,
                                                errorWidget: (context, error,
                                                        stackTrace) =>
                                                    Image.asset(
                                                  'assets/images/error_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 0.0, 0.0, 0.0),
                                                child: Text(
                                                  valueOrDefault<String>(
                                                    EbookGroup
                                                        .getbookdetailsApiCall
                                                        .authorName(
                                                      bookDetailspageGetbookdetailsApiResponse
                                                          .jsonBody,
                                                    ),
                                                    'Name',
                                                  ),
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        fontSize: 17.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                              child: SvgPicture.asset(
                                                'assets/images/info.svg',
                                                width: 24.0,
                                                height: 24.0,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .getReviewCache(
                                    uniqueQueryKey: valueOrDefault<String>(
                                      widget.id,
                                      '0',
                                    ),
                                    requestFn: () =>
                                        EbookGroup.getreviewApiCall.call(
                                      bookId: widget.id,
                                      token: FFAppState().token,
                                    ),
                                  )
                                      .then((result) {
                                    try {
                                      _model.apiRequestCompleted2 = true;
                                      _model.apiRequestLastUniqueKey2 =
                                          valueOrDefault<String>(
                                        widget.id,
                                        '0',
                                      );
                                    } finally {}
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return Container(
                                        width: 0.0,
                                        height: 0.0,
                                        child: BlankComponentWidget(),
                                      );
                                    }
                                    final containerGetreviewApiResponse =
                                        snapshot.data!;

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Builder(
                                        builder: (context) {
                                          if (EbookGroup.getreviewApiCall
                                                  .success(
                                                containerGetreviewApiResponse
                                                    .jsonBody,
                                              ) ==
                                              1) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 16.0,
                                                          16.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Reviews',
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          context.pushNamed(
                                                            RecentReviewsPageWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'reviewId':
                                                                  serializeParam(
                                                                widget.id,
                                                                ParamType
                                                                    .String,
                                                              ),
                                                              'bookId':
                                                                  serializeParam(
                                                                widget.id,
                                                                ParamType
                                                                    .String,
                                                              ),
                                                            }.withoutNulls,
                                                          );
                                                        },
                                                        child: Text(
                                                          'View all',
                                                          textAlign:
                                                              TextAlign.end,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 8.0)),
                                                  ),
                                                ),
                                                Builder(
                                                  builder: (context) {
                                                    final reviewList = (EbookGroup
                                                                .getreviewApiCall
                                                                .reviewsList(
                                                                  containerGetreviewApiResponse
                                                                      .jsonBody,
                                                                )
                                                                ?.toList() ??
                                                            [])
                                                        .take(2)
                                                        .toList();

                                                    return SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: List.generate(
                                                                reviewList
                                                                    .length,
                                                                (reviewListIndex) {
                                                          final reviewListItem =
                                                              reviewList[
                                                                  reviewListIndex];
                                                          return Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        16.0,
                                                                        0.0,
                                                                        16.0),
                                                            child: Container(
                                                              width: 320.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    blurRadius:
                                                                        16.0,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .shadowColor,
                                                                    offset:
                                                                        Offset(
                                                                      0.0,
                                                                      4.0,
                                                                    ),
                                                                  )
                                                                ],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12.0),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            16.0),
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
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          16.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Container(
                                                                            width:
                                                                                48.0,
                                                                            height:
                                                                                48.0,
                                                                            clipBehavior:
                                                                                Clip.antiAlias,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                CachedNetworkImage(
                                                                              fadeInDuration: Duration(milliseconds: 200),
                                                                              fadeOutDuration: Duration(milliseconds: 200),
                                                                              imageUrl: '${FFAppConstants.imageUrl}${getJsonField(
                                                                                reviewListItem,
                                                                                r'''$.userDetails.image''',
                                                                              ).toString()}',
                                                                              fit: BoxFit.cover,
                                                                              errorWidget: (context, error, stackTrace) => Image.asset(
                                                                                'assets/images/error_image.png',
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    getJsonField(
                                                                                      reviewListItem,
                                                                                      r'''$.userDetails.name''',
                                                                                    ).toString(),
                                                                                    maxLines: 1,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          fontSize: 16.0,
                                                                                          letterSpacing: 0.0,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    getJsonField(
                                                                                      reviewListItem,
                                                                                      r'''$.date''',
                                                                                    ).toString(),
                                                                                    maxLines: 1,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          color: FlutterFlowTheme.of(context).secondaryText,
                                                                                          fontSize: 15.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.normal,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                ].divide(SizedBox(height: 4.0)),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children: [
                                                                              Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                                                                                child: ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(0.0),
                                                                                  child: Image.asset(
                                                                                    'assets/images/star.png',
                                                                                    width: 16.0,
                                                                                    height: 16.0,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                getJsonField(
                                                                                  reviewListItem,
                                                                                  r'''$.rating''',
                                                                                ).toString(),
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 15.0,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.normal,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      getJsonField(
                                                                        reviewListItem,
                                                                        r'''$.description''',
                                                                      ).toString(),
                                                                      maxLines:
                                                                          3,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'SF Pro Display',
                                                                            fontSize:
                                                                                17.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            lineHeight:
                                                                                1.5,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                            .divide(SizedBox(
                                                                width: 16.0))
                                                            .addToStart(
                                                                SizedBox(
                                                                    width:
                                                                        16.0))
                                                            .addToEnd(SizedBox(
                                                                width: 16.0)),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          } else {
                                            return Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 16.0, 16.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Reviews',
                                                      textAlign:
                                                          TextAlign.start,
                                                      maxLines: 1,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            fontSize: 20.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            lineHeight: 1.5,
                                                          ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      await showModalBottomSheet(
                                                        isScrollControlled:
                                                            true,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        enableDrag: false,
                                                        context: context,
                                                        builder: (context) {
                                                          return Padding(
                                                            padding: MediaQuery
                                                                .viewInsetsOf(
                                                                    context),
                                                            child: Container(
                                                              height: 489.0,
                                                              child:
                                                                  BookReviewBottomSheetWidget(
                                                                bookId:
                                                                    widget.id!,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ).then((value) =>
                                                          safeSetState(() {}));
                                                    },
                                                    child: Text(
                                                      'Write review',
                                                      textAlign: TextAlign.end,
                                                      maxLines: 1,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            fontSize: 17.0,
                                                            letterSpacing: 0.0,
                                                            lineHeight: 1.5,
                                                          ),
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 8.0)),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 16.0, 0.0, 0.0),
                                  child: FutureBuilder<ApiCallResponse>(
                                    future: FFAppState().getBookbyCategoryCache(
                                      uniqueQueryKey: valueOrDefault<String>(
                                        widget.id,
                                        'id',
                                      ),
                                      requestFn: () => EbookGroup
                                          .getbookbycategoryApiCall
                                          .call(
                                        categoryId: EbookGroup
                                            .getbookdetailsApiCall
                                            .categoryId(
                                          bookDetailspageGetbookdetailsApiResponse
                                              .jsonBody,
                                        ),
                                      ),
                                    ),
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
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      final columnGetbookbycategoryApiResponse =
                                          snapshot.data!;

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (EbookGroup
                                                  .getbookbycategoryApiCall
                                                  .success(
                                                columnGetbookbycategoryApiResponse
                                                    .jsonBody,
                                              ) ==
                                              1)
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 0.0, 16.0),
                                              child: Text(
                                                'Related books',
                                                textAlign: TextAlign.start,
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
                                          if (EbookGroup
                                                  .getbookbycategoryApiCall
                                                  .success(
                                                columnGetbookbycategoryApiResponse
                                                    .jsonBody,
                                              ) ==
                                              1)
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              child: Builder(
                                                builder: (context) {
                                                  final authorRelatedbookDetailslist =
                                                      EbookGroup
                                                              .getbookbycategoryApiCall
                                                              .bookDetailsList(
                                                                columnGetbookbycategoryApiResponse
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
                                                    direction: Axis.horizontal,
                                                    runAlignment:
                                                        WrapAlignment.start,
                                                    verticalDirection:
                                                        VerticalDirection.down,
                                                    clipBehavior: Clip.none,
                                                    children: List.generate(
                                                        authorRelatedbookDetailslist
                                                            .length,
                                                        (authorRelatedbookDetailslistIndex) {
                                                      final authorRelatedbookDetailslistItem =
                                                          authorRelatedbookDetailslist[
                                                              authorRelatedbookDetailslistIndex];
                                                      return wrapWithModel(
                                                        model: _model
                                                            .mainBookComponentModels
                                                            .getModel(
                                                          getJsonField(
                                                            authorRelatedbookDetailslistItem,
                                                            r'''$.name''',
                                                          ).toString(),
                                                          authorRelatedbookDetailslistIndex,
                                                        ),
                                                        updateCallback: () =>
                                                            safeSetState(() {}),
                                                        child:
                                                            MainBookComponentWidget(
                                                          key: Key(
                                                            'Keybek_${getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.name''',
                                                            ).toString()}',
                                                          ),
                                                          image:
                                                              '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                            authorRelatedbookDetailslistItem,
                                                            r'''$.image''',
                                                          ).toString()}',
                                                          bookName:
                                                              getJsonField(
                                                            authorRelatedbookDetailslistItem,
                                                            r'''$.name''',
                                                          ).toString(),
                                                          authorsName:
                                                              getJsonField(
                                                            authorRelatedbookDetailslistItem,
                                                            r'''$.author.name''',
                                                          ).toString(),
                                                          isFav: functions.checkFavOrNot(
                                                                  EbookGroup.getFavouriteBookCall
                                                                      .favouriteBookDetailsList(
                                                                        columnGetFavouriteBookResponse
                                                                            .jsonBody,
                                                                      )
                                                                      ?.toList(),
                                                                  getJsonField(
                                                                    authorRelatedbookDetailslistItem,
                                                                    r'''$._id''',
                                                                  ).toString()) ==
                                                              true,
                                                          indicator: (authorRelatedbookDetailslistIndex ==
                                                                  _model
                                                                      .relatedIndex) &&
                                                              (_model.isRelated ==
                                                                  true),
                                                          isFavAction:
                                                              () async {
                                                            if (FFAppState()
                                                                    .isLogin ==
                                                                true) {
                                                              _model.isRelated =
                                                                  true;
                                                              _model.relatedIndex =
                                                                  authorRelatedbookDetailslistIndex;
                                                              safeSetState(
                                                                  () {});
                                                              if (functions.checkFavOrNot(
                                                                      EbookGroup.getFavouriteBookCall
                                                                          .favouriteBookDetailsList(
                                                                            columnGetFavouriteBookResponse.jsonBody,
                                                                          )
                                                                          ?.toList(),
                                                                      getJsonField(
                                                                        authorRelatedbookDetailslistItem,
                                                                        r'''$._id''',
                                                                      ).toString()) ==
                                                                  true) {
                                                                _model.getPopularDetete =
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
                                                                    authorRelatedbookDetailslistItem,
                                                                    r'''$._id''',
                                                                  ).toString(),
                                                                );

                                                                safeSetState(() =>
                                                                    _model.apiRequestCompleter1 =
                                                                        null);
                                                                await _model
                                                                    .waitForApiRequestCompleted1();
                                                                await actions
                                                                    .showCustomToastBottom(
                                                                  FFAppState()
                                                                      .unFavText,
                                                                );
                                                              } else {
                                                                _model.getPopularAdd =
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
                                                                    authorRelatedbookDetailslistItem,
                                                                    r'''$._id''',
                                                                  ).toString(),
                                                                );

                                                                safeSetState(() =>
                                                                    _model.apiRequestCompleter1 =
                                                                        null);
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
                                                              _model.isRelated =
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
                                                                authorRelatedbookDetailslistItem,
                                                                r'''$._id''',
                                                              ).toString();
                                                              FFAppState()
                                                                  .update(
                                                                      () {});

                                                              context.pushNamed(
                                                                  SignInPageWidget
                                                                      .routeName);
                                                            }

                                                            safeSetState(() {});
                                                          },
                                                          isMainTap: () async {
                                                            context.pushNamed(
                                                              BookDetailspageWidget
                                                                  .routeName,
                                                              queryParameters: {
                                                                'name':
                                                                    serializeParam(
                                                                  getJsonField(
                                                                    authorRelatedbookDetailslistItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  ParamType
                                                                      .String,
                                                                ),
                                                                'image':
                                                                    serializeParam(
                                                                  '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                    authorRelatedbookDetailslistItem,
                                                                    r'''$.image''',
                                                                  ).toString()}',
                                                                  ParamType
                                                                      .String,
                                                                ),
                                                                'id':
                                                                    serializeParam(
                                                                  getJsonField(
                                                                    authorRelatedbookDetailslistItem,
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
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        FutureBuilder<ApiCallResponse>(
                          future:
                              EbookGroup.usersubscriptionvalidityApiCall.call(
                            userId: FFAppState().userId,
                            token: FFAppState().token,
                          ),
                          builder: (context, snapshot) {
                            // Customize what your widget looks like when it's loading.
                            if (!snapshot.hasData) {
                              return Container(
                                width: double.infinity,
                                height: 88.0,
                                child: ButtonDetailPageShimmerWidget(),
                              );
                            }
                            final containerUsersubscriptionvalidityApiResponse =
                                snapshot.data!;

                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 16.0,
                                    color: FlutterFlowTheme.of(context)
                                        .shadowColor,
                                    offset: Offset(
                                      0.0,
                                      4.0,
                                    ),
                                  )
                                ],
                              ),
                              child: FutureBuilder<ApiCallResponse>(
                                future: (_model.apiRequestCompleter3 ??=
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
                                    return Container(
                                      width: double.infinity,
                                      height: 88.0,
                                      child: ButtonDetailPageShimmerWidget(),
                                    );
                                  }
                                  final containerDownloadhistoryApiResponse =
                                      snapshot.data!;

                                  return Container(
                                    decoration: BoxDecoration(),
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: FFButtonWidget(
                                              onPressed: () async {
                                                if (EbookGroup
                                                        .getbookdetailsApiCall
                                                        .accesstype(
                                                      bookDetailspageGetbookdetailsApiResponse
                                                          .jsonBody,
                                                    ) ==
                                                    'free') {
                                                  context.pushNamed(
                                                    ReadBookCustomPageWidget
                                                        .routeName,
                                                    queryParameters: {
                                                      'pdf': serializeParam(
                                                        '${FFAppConstants.bookImagesUrl}${EbookGroup.getbookdetailsApiCall.pdf(
                                                          bookDetailspageGetbookdetailsApiResponse
                                                              .jsonBody,
                                                        )}',
                                                        ParamType.String,
                                                      ),
                                                      'id': serializeParam(
                                                        widget.id,
                                                        ParamType.String,
                                                      ),
                                                      'name': serializeParam(
                                                        widget.name,
                                                        ParamType.String,
                                                      ),
                                                      'image': serializeParam(
                                                        widget.image,
                                                        ParamType.String,
                                                      ),
                                                    }.withoutNulls,
                                                  );

                                                  if (widget.id ==
                                                      FFAppState()
                                                          .homePageBookId) {
                                                    FFAppState().totalPages = 1;
                                                    FFAppState().update(() {});
                                                  } else {
                                                    FFAppState().totalPages = 1;
                                                    FFAppState()
                                                        .homePageCurrentPdfIndex = 1;
                                                    FFAppState().update(() {});
                                                  }
                                                } else {
                                                  if (FFAppState().isLogin ==
                                                      true) {
                                                    _model.uservalidity =
                                                        await EbookGroup
                                                            .usersubscriptionvalidityApiCall
                                                            .call(
                                                      userId:
                                                          FFAppState().userId,
                                                      token: FFAppState().token,
                                                    );

                                                    if (EbookGroup
                                                            .usersubscriptionvalidityApiCall
                                                            .daysLeft(
                                                          (_model.uservalidity
                                                                  ?.jsonBody ??
                                                              ''),
                                                        ) ==
                                                        null) {
                                                      context.pushNamed(
                                                          SubscriptionPageWidget
                                                              .routeName);
                                                    } else {
                                                      if (EbookGroup
                                                              .usersubscriptionvalidityApiCall
                                                              .daysLeft(
                                                            (_model.uservalidity
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )! >
                                                          0) {
                                                        context.pushNamed(
                                                          ReadBookCustomPageWidget
                                                              .routeName,
                                                          queryParameters: {
                                                            'pdf':
                                                                serializeParam(
                                                              '${FFAppConstants.bookImagesUrl}${EbookGroup.getbookdetailsApiCall.pdf(
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                              )}',
                                                              ParamType.String,
                                                            ),
                                                            'id':
                                                                serializeParam(
                                                              widget.id,
                                                              ParamType.String,
                                                            ),
                                                            'name':
                                                                serializeParam(
                                                              widget.name,
                                                              ParamType.String,
                                                            ),
                                                            'image':
                                                                serializeParam(
                                                              widget.image,
                                                              ParamType.String,
                                                            ),
                                                          }.withoutNulls,
                                                        );

                                                        if (widget.id ==
                                                            FFAppState()
                                                                .homePageBookId) {
                                                          FFAppState()
                                                              .totalPages = 1;
                                                          FFAppState()
                                                              .update(() {});
                                                        } else {
                                                          FFAppState()
                                                              .totalPages = 1;
                                                          FFAppState()
                                                              .homePageCurrentPdfIndex = 1;
                                                          FFAppState()
                                                              .update(() {});
                                                        }
                                                      } else {
                                                        context.pushNamed(
                                                            SubscriptionPageWidget
                                                                .routeName);
                                                      }
                                                    }
                                                  } else {
                                                    context.pushNamed(
                                                        SignInPageWidget
                                                            .routeName);
                                                  }
                                                }

                                                safeSetState(() {});
                                              },
                                              text: valueOrDefault<String>(
                                                () {
                                                  if (valueOrDefault<String>(
                                                        EbookGroup
                                                            .getbookdetailsApiCall
                                                            .accesstype(
                                                          bookDetailspageGetbookdetailsApiResponse
                                                              .jsonBody,
                                                        ),
                                                        'free',
                                                      ) ==
                                                      'free') {
                                                    return 'Read book';
                                                  } else if (EbookGroup
                                                          .usersubscriptionvalidityApiCall
                                                          .daysLeft(
                                                        containerUsersubscriptionvalidityApiResponse
                                                            .jsonBody,
                                                      ) ==
                                                      null) {
                                                    return 'Buy subscription';
                                                  } else {
                                                    return (EbookGroup
                                                                .usersubscriptionvalidityApiCall
                                                                .daysLeft(
                                                              containerUsersubscriptionvalidityApiResponse
                                                                  .jsonBody,
                                                            )! >
                                                            0
                                                        ? 'Read book'
                                                        : 'Buy subscription');
                                                  }
                                                }(),
                                                'Buy subscription',
                                              ),
                                              options: FFButtonOptions(
                                                width: 206.0,
                                                height: 56.0,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        24.0, 0.0, 24.0, 0.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryBackground,
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          lineHeight: 1.2,
                                                        ),
                                                elevation: 0.0,
                                                borderSide: BorderSide(
                                                  color: Colors.transparent,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
}
