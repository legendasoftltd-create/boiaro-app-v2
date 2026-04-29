import 'package:a_i_ebook_app/pages/home_pages/about_publisher_page/about_publisher_page_model.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/shimmers/about_author_sec_shimmer/about_author_sec_shimmer_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/services/follow_service.dart';
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class AboutPublisherPageWidget extends StatefulWidget {
  const AboutPublisherPageWidget({
    super.key,
    required this.name,
    required this.publisherImage,
    required this.publisherId,
  });

  final String? name;
  final String? publisherImage;
  final String? publisherId;

  static String routeName = 'AboutPublisherPage';
  static String routePath = '/aboutPublisherPage';

  @override
  State<AboutPublisherPageWidget> createState() => _AboutPublisherPageWidgetState();
}

class _AboutPublisherPageWidgetState extends State<AboutPublisherPageWidget> {
  late AboutPublisherPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  int? _followersCount;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AboutPublisherPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
        await _loadFollowState();
      }
      safeSetState(() {});
    });
  }

  Future<void> _loadFollowState() async {
    if (!FollowService.supportsFollowEndpoints) return;
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
    final id = (widget.publisherId ?? '').trim();
    if (id.isEmpty) return;
    final state = await FollowService.fetchState(
      entityType: 'publisher',
      entityId: id,
      token: FFAppState().token,
    );
    if (!mounted || state == null) return;
    safeSetState(() {
      _isFollowing = state.isFollowing;
      _followersCount = state.followersCount;
    });
  }

  Future<void> _toggleFollow() async {
    if (!FollowService.supportsFollowEndpoints) {
      await actions.showCustomToastBottom(
          'Follow system is not available in current API version.');
      return;
    }
    if (_isFollowLoading) return;
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    final id = (widget.publisherId ?? '').trim();
    if (id.isEmpty) return;
    safeSetState(() => _isFollowLoading = true);
    final target = !_isFollowing;
    final ok = await FollowService.setFollow(
      entityType: 'publisher',
      entityId: id,
      token: FFAppState().token,
      follow: target,
    );
    if (!mounted) return;
    if (ok) {
      safeSetState(() {
        _isFollowing = target;
        if (_followersCount != null) {
          _followersCount = (_followersCount! + (target ? 1 : -1)).clamp(0, 1 << 30);
        }
      });
      await actions.showCustomToastBottom(
        target ? 'Followed publisher' : 'Unfollowed publisher',
      );
      await _loadFollowState();
    } else {
      await actions.showCustomToastBottom('Unable to update follow status');
    }
    if (mounted) safeSetState(() => _isFollowLoading = false);
  }

  Future<void> _loadPurchasedBooks() async {
    try {
      final response = await EbookGroup.userBookPurchaseRecordsApiCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      );
      
      if (EbookGroup.userBookPurchaseRecordsApiCall.success(
            response.jsonBody ?? '',
          ) ==
          1) {
        final bookIds = EbookGroup.userBookPurchaseRecordsApiCall.bookId(
          response.jsonBody ?? '',
        );
        _model.purchasedBookIds = bookIds ?? [];
        safeSetState(() {});
      }
    } catch (e) {
      debugPrint('Error loading purchased books: $e');
    }
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
                  title: 'About publisher',
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
                        future: (_model.apiRequestCompleter2 ??=
                                Completer<ApiCallResponse>()
                                  ..complete(
                                      EbookGroup.getpublisherdetailsApiCall.call(
                                    publisherId: widget.publisherId,
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
                          final containerGetpublisherdetailsApiResponse =
                              snapshot.data!;

                          return Container(
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getpublisherdetailsApiCall.success(
                                      containerGetpublisherdetailsApiResponse
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
                                          EbookGroup.getpublisherdetailsApiCall
                                              .message(
                                            containerGetpublisherdetailsApiResponse
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
                                  return RefreshIndicator(
                                    key: Key('RefreshIndicator_zhgjuy03'),
                                    color: FlutterFlowTheme.of(context).primary,
                                    onRefresh: () async {
                                      safeSetState(() =>
                                          _model.apiRequestCompleter2 = null);
                                      await _model
                                          .waitForApiRequestCompleted2();
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                              boxShadow: [
                                                BoxShadow(
                                                  blurRadius: 16.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
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
                                                children: [
                                                  Container(
                                                    width: 80.0,
                                                    height: 80.0,
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: CachedNetworkImage(
                                                      fadeInDuration: Duration(
                                                          milliseconds: 200),
                                                      fadeOutDuration: Duration(
                                                          milliseconds: 200),
                                                      imageUrl:
                                                          widget.publisherImage!,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context,
                                                              error,
                                                              stackTrace) =>
                                                          Image.asset(
                                                        'assets/images/error_image.png',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceAround,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            valueOrDefault<
                                                                String>(
                                                              widget.name,
                                                              'Name',
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            maxLines: 2,
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
                                                                          .w500,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              OutlinedButton(
                                                                onPressed: (!FollowService
                                                                            .supportsFollowEndpoints ||
                                                                        _isFollowLoading)
                                                                    ? null
                                                                    : _toggleFollow,
                                                                child: _isFollowLoading
                                                                    ? const SizedBox(
                                                                        width: 14,
                                                                        height: 14,
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          strokeWidth: 2,
                                                                        ),
                                                                      )
                                                                    : Text(!FollowService
                                                                            .supportsFollowEndpoints
                                                                        ? 'Coming soon'
                                                                        : (_isFollowing
                                                                            ? 'Following'
                                                                            : 'Follow')),
                                                              ),
                                                              if (_followersCount != null) ...[
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  '${_followersCount!} followers',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall,
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ].divide(SizedBox(
                                                            height: 8.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (EbookGroup.getpublisherdetailsApiCall
                                                    .description(
                                                  containerGetpublisherdetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                null &&
                                            EbookGroup.getpublisherdetailsApiCall
                                                    .description(
                                                  containerGetpublisherdetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                '')
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 16.0, 16.0, 8.0),
                                            child: Text(
                                              'Description',
                                              textAlign: TextAlign.start,
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        if (EbookGroup.getpublisherdetailsApiCall
                                                    .description(
                                                  containerGetpublisherdetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                null &&
                                            EbookGroup.getpublisherdetailsApiCall
                                                    .description(
                                                  containerGetpublisherdetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                '')
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                boxShadow: [
                                                  BoxShadow(
                                                    blurRadius: 16.0,
                                                    color: FlutterFlowTheme.of(
                                                            context)
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
                                                child:
                                                    custom_widgets.ReadMoreHtml(
                                                  width: double.infinity,
                                                  height: 80.0,
                                                  htmlContent: EbookGroup
                                                      .getpublisherdetailsApiCall
                                                      .description(
                                                    containerGetpublisherdetailsApiResponse
                                                        .jsonBody,
                                                  ),
                                                  maxLength: 150,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if ((widget.publisherId ?? '').isEmpty)
                                          Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 16.0, 16.0, 8.0),
                                          child: Text(
                                            'Contact information',
                                            textAlign: TextAlign.start,
                                            maxLines: 1,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 20.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              boxShadow: [
                                                BoxShadow(
                                                  blurRadius: 16.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
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
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
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
                                                      if (!(EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .facebookurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              null ||
                                                          EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .facebookurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              '')) {
                                                        await launchURL(EbookGroup
                                                            .getpublisherdetailsApiCall
                                                            .facebookurl(
                                                          containerGetpublisherdetailsApiResponse
                                                              .jsonBody,
                                                        )!);
                                                      }
                                                    },
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.0),
                                                      child: Image.asset(
                                                        'assets/images/facebook_ic.png',
                                                        width: 36.0,
                                                        height: 36.0,
                                                        fit: BoxFit.contain,
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
                                                      if (!(EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .instagramurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              null ||
                                                          EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .instagramurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              '')) {
                                                        await launchURL(EbookGroup
                                                            .getpublisherdetailsApiCall
                                                            .instagramurl(
                                                          containerGetpublisherdetailsApiResponse
                                                              .jsonBody,
                                                        )!);
                                                      }
                                                    },
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.0),
                                                      child: SvgPicture.asset(
                                                        'assets/images/instagram.svg',
                                                        width: 36.0,
                                                        height: 36.0,
                                                        fit: BoxFit.cover,
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
                                                      if (!(EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .youtubeurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              null ||
                                                          EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .youtubeurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              '')) {
                                                        await launchURL(EbookGroup
                                                            .getpublisherdetailsApiCall
                                                            .youtubeurl(
                                                          containerGetpublisherdetailsApiResponse
                                                              .jsonBody,
                                                        )!);
                                                      }
                                                    },
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.0),
                                                      child: SvgPicture.asset(
                                                        'assets/images/youtube.svg',
                                                        width: 36.0,
                                                        height: 36.0,
                                                        fit: BoxFit.cover,
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
                                                      if (!(EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .websiteurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              null ||
                                                          EbookGroup
                                                                  .getpublisherdetailsApiCall
                                                                  .websiteurl(
                                                                containerGetpublisherdetailsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              '')) {
                                                        await launchURL(EbookGroup
                                                            .getpublisherdetailsApiCall
                                                            .websiteurl(
                                                          containerGetpublisherdetailsApiResponse
                                                              .jsonBody,
                                                        )!);
                                                      }
                                                    },
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.0),
                                                      child: SvgPicture.asset(
                                                        'assets/images/link(1).svg',
                                                        width: 36.0,
                                                        height: 36.0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 16.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        FutureBuilder<ApiCallResponse>(
                                          future: FFAppState()
                                              .getFavouriteBookCache(
                                            requestFn: () => EbookGroup
                                                .getFavouriteBookCall
                                                .call(
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
                                              return AboutAuthorSecShimmerWidget();
                                            }
                                            final containerGetFavouriteBookResponse =
                                                snapshot.data!;

                                            return Container(
                                              decoration: BoxDecoration(),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 16.0, 0.0, 0.0),
                                                child: FutureBuilder<
                                                    ApiCallResponse>(
                                                  future: EbookGroup
                                                      .getbookbypublisherApiCall
                                                      .call(
                                                    publisherId: widget.publisherId,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return AboutAuthorSecShimmerWidget();
                                                    }
                                                    final columnGetbookbypublisherApiResponse =
                                                        snapshot.data!;

                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (EbookGroup
                                                                .getbookbypublisherApiCall
                                                                .success(
                                                              columnGetbookbypublisherApiResponse
                                                                  .jsonBody,
                                                            ) ==
                                                            1)
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        0.0,
                                                                        16.0,
                                                                        16.0),
                                                            child: Text(
                                                              'Popular books',
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
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
                                                        if (EbookGroup
                                                                .getbookbypublisherApiCall
                                                                .success(
                                                              columnGetbookbypublisherApiResponse
                                                                  .jsonBody,
                                                            ) ==
                                                            1)
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        0.0,
                                                                        16.0,
                                                                        0.0),
                                                            child: Builder(
                                                              builder:
                                                                  (context) {
                                                                final bookDetailsList = EbookGroup
                                                                        .getbookbypublisherApiCall
                                                                        .bookDetailsList(
                                                                          columnGetbookbypublisherApiResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList() ??
                                                                    [];

                                                                return Wrap(
                                                                  spacing: 16.0,
                                                                  runSpacing:
                                                                      16.0,
                                                                  alignment:
                                                                      WrapAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      WrapCrossAlignment
                                                                          .start,
                                                                  direction: Axis
                                                                      .horizontal,
                                                                  runAlignment:
                                                                      WrapAlignment
                                                                          .start,
                                                                  verticalDirection:
                                                                      VerticalDirection
                                                                          .down,
                                                                  clipBehavior:
                                                                      Clip.none,
                                                                  children: List.generate(
                                                                      bookDetailsList
                                                                          .length,
                                                                      (bookDetailsListIndex) {
                                                                    final bookDetailsListItem =
                                                                        bookDetailsList[
                                                                            bookDetailsListIndex];
                                                                    return wrapWithModel(
                                                                      model: _model
                                                                          .mainBookComponentModels
                                                                          .getModel(
                                                                        getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.name''',
                                                                        ).toString(),
                                                                        bookDetailsListIndex,
                                                                      ),
                                                                      updateCallback:
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                      child:
                                                                          MainBookComponentWidget(
                                                                        key:
                                                                            Key(
                                                                          'Keyu5r_${getJsonField(
                                                                            bookDetailsListItem,
                                                                            r'''$.name''',
                                                                          ).toString()}',
                                                                        ),
                                                                        image:
                                                                            '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.image''',
                                                                        ).toString()}',
                                                                        bookName:
                                                                            getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.name''',
                                                                        ).toString(),
                                                                        id:
                                                                            getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$._id''',
                                                                        ).toString(),
                                                                        price:
                                                                            getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.price''',
                                                                        ).toString(),
                                                                        bookType:
                                                                            getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.type''',
                                                                        )?.toString(),
                                                                        discountAmount:
                                                                            getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.discount_amount''',
                                                                        ).toString(),
                                                                        discountPercentage:
                                                                            getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.discount_percentage''',
                                                                        ).toString(),
                                                                        authorsName:
                                                                            'By ${getJsonField(
                                                                          bookDetailsListItem,
                                                                          r'''$.author.name''',
                                                                        ).toString()}',
                                                                        isFav: functions.checkFavOrNot(
                                                                                EbookGroup.getFavouriteBookCall
                                                                                    .favouriteBookDetailsList(
                                                                                      containerGetFavouriteBookResponse.jsonBody,
                                                                                    )
                                                                                    ?.toList(),
                                                                                getJsonField(
                                                                                  bookDetailsListItem,
                                                                                  r'''$._id''',
                                                                                ).toString()) ==
                                                                            true,
                                                                        indicator:
                                                                            (bookDetailsListIndex == _model.popularIndex) &&
                                                                                (_model.isPopular == true),
                                                                        isFavAction:
                                                                            () async {
                                                                          if (FFAppState().isLogin ==
                                                                              true) {
                                                                            _model.isPopular =
                                                                                true;
                                                                            _model.popularIndex =
                                                                                bookDetailsListIndex;
                                                                            safeSetState(() {});
                                                                            if (functions.checkFavOrNot(
                                                                                    EbookGroup.getFavouriteBookCall
                                                                                        .favouriteBookDetailsList(
                                                                                          containerGetFavouriteBookResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList(),
                                                                                    getJsonField(
                                                                                      bookDetailsListItem,
                                                                                      r'''$._id''',
                                                                                    ).toString()) ==
                                                                                true) {
                                                                              _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                                userId: FFAppState().userId,
                                                                                token: FFAppState().token,
                                                                                bookId: getJsonField(
                                                                                  bookDetailsListItem,
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
                                                                                  bookDetailsListItem,
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
                                                                            _model.isPopular =
                                                                                false;
                                                                            safeSetState(() {});
                                                                          } else {
                                                                            FFAppState().favChange =
                                                                                true;
                                                                            FFAppState().bookId =
                                                                                getJsonField(
                                                                              bookDetailsListItem,
                                                                              r'''$._id''',
                                                                            ).toString();
                                                                            FFAppState().update(() {});

                                                                            context.pushNamed(SignInPageWidget.routeName);
                                                                          }

                                                                          safeSetState(
                                                                              () {});
                                                                        },
                                                                        isPurchased: _model.purchasedBookIds.contains(
                                                                          getJsonField(
                                                                            bookDetailsListItem,
                                                                            r'''$._id''',
                                                                          ).toString(),
                                                                        ),
                                                                        isMainTap:
                                                                            () async {
                                                                          context
                                                                              .pushNamed(
                                                                            BookDetailspageWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'name': serializeParam(
                                                                                getJsonField(
                                                                                  bookDetailsListItem,
                                                                                  r'''$.name''',
                                                                                ).toString(),
                                                                                ParamType.String,
                                                                              ),
                                                                              'price': serializeParam(
                                                                                getJsonField(
                                                                                  bookDetailsListItem,
                                                                                  r'''$.price''',
                                                                                ).toString(),
                                                                                ParamType.String,
                                                                              ),
                                                                              'image': serializeParam(
                                                                                '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                  bookDetailsListItem,
                                                                                  r'''$.image''',
                                                                                ).toString()}',
                                                                                ParamType.String,
                                                                              ),
                                                                              'id': serializeParam(
                                                                                getJsonField(
                                                                                  bookDetailsListItem,
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
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
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
