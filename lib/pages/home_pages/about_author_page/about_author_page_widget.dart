import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
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
import 'package:share_plus/share_plus.dart';
import '/app_constants.dart';
import 'about_author_page_model.dart';
export 'about_author_page_model.dart';

class AboutAuthorPageWidget extends StatefulWidget {
  const AboutAuthorPageWidget({
    super.key,
    required this.name,
    required this.authorImage,
    required this.authorId,
  });

  final String? name;
  final String? authorImage;
  final String? authorId;

  static String routeName = 'AboutAuthorPage';
  static String routePath = '/aboutAuthorPage';

  @override
  State<AboutAuthorPageWidget> createState() => _AboutAuthorPageWidgetState();
}

class _AboutAuthorPageWidgetState extends State<AboutAuthorPageWidget> {
  late AboutAuthorPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  int? _followersCount;

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AboutAuthorPageModel());
    _scrollController.addListener(_onScroll);
    _loadMoreBooks(isFirstLoad: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
        await _loadFollowState();
        await _reloadFollowStateFromAuthorList();
      }
      safeSetState(() {});
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadMoreBooks({bool isFirstLoad = false}) async {
    if (_isLoading || (!_hasMore && !isFirstLoad)) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await EbookGroup.getbookbyauthorApiCall.call(
        authorId: widget.authorId,
        limit: _limit,
        cursor: isFirstLoad ? null : _nextCursor,
      );
      final newBooks =
          EbookGroup.getbookbyauthorApiCall.bookDetailsList(res.jsonBody) ??
              [];
      final nextCursorVal =
          EbookGroup.getbookbyauthorApiCall.nextCursor(res.jsonBody);

      setState(() {
        if (isFirstLoad) {
          _books.clear();
          _offset = 0;
        }
        final existingIds = _books
            .map((book) => getJsonField(book, r'''$._id''')?.toString())
            .where((id) => id != null)
            .toSet();
        for (final book in newBooks) {
          final bookId = getJsonField(book, r'''$._id''')?.toString();
          if (bookId == null || !existingIds.contains(bookId)) {
            _books.add(book);
            if (bookId != null) {
              existingIds.add(bookId);
            }
          }
        }
        _offset += newBooks.length;
        _nextCursor = nextCursorVal;
        if (_nextCursor == null || _nextCursor!.isEmpty) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }
      });

      // Auto load next page if content doesn't fill screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasMore && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0) {
          _loadMoreBooks();
        }
      });
    } catch (e) {
      // Error loading author books
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFollowState() async {
    if (!FollowService.supportsFollowEndpoints) return;
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
    final id = (widget.authorId ?? '').trim();
    if (id.isEmpty) return;
    final state = await FollowService.fetchState(
      entityType: 'author',
      entityId: id,
      token: FFAppState().token,
    );
    if (!mounted || state == null) return;
    safeSetState(() {
      _isFollowing = state.isFollowing;
      _followersCount = state.followersCount;
    });
  }

  Future<void> _reloadFollowStateFromAuthorList() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
    final id = (widget.authorId ?? '').trim();
    if (id.isEmpty) return;
    final res = await EbookGroup.getauthorsApiCall.call(
      token: FFAppState().token,
    );
    final list = EbookGroup.getauthorsApiCall.authorDetailsList(res.jsonBody)
            ?.toList() ??
        <dynamic>[];
    for (final row in list) {
      final rid = getJsonField(row, r'''$._id''')?.toString() ?? '';
      if (rid != id) continue;
      final followedRaw = getJsonField(row, r'''$.followed''');
      if (!mounted) return;
      safeSetState(() {
        _isFollowing = followedRaw == true;
      });
      return;
    }
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
    final id = (widget.authorId ?? '').trim();
    if (id.isEmpty) return;
    safeSetState(() => _isFollowLoading = true);
    final target = !_isFollowing;
    final ok = await FollowService.setFollow(
      entityType: 'author',
      entityId: id,
      token: FFAppState().token,
      follow: target,
    );
    if (!mounted) return;
    if (ok) {
      safeSetState(() {
        _isFollowing = target;
        if (_followersCount != null) {
          _followersCount =
              (_followersCount! + (target ? 1 : -1)).clamp(0, 1 << 30);
        }
      });
      await actions.showCustomToastBottom(
        target ? 'Followed author' : 'Unfollowed author',
      );
      await _reloadFollowStateFromAuthorList();
    } else {
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Unable to update follow status', bnText: 'অনুসরণ অবস্থা আপডেট করতে ব্যর্থ'));
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
      // Error loading purchased books
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
                  title: FFLocalizations.of(context).getVariableText(enText: 'About author', bnText: 'লেখক সম্পর্কে'),
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                  shareIcon: true,
                  onTapShare: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        uri: Uri.parse(
                          "${FFAppConstants.webUrl}/author/${widget.authorId}"
                        ),
                      ),
                    );
                  },
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
                                      EbookGroup.getauthordetailsApiCall.call(
                                    authorId: widget.authorId,
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
                          final containerGetauthordetailsApiResponse =
                              snapshot.data!;
                          return Container(
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getauthordetailsApiCall.success(
                                      containerGetauthordetailsApiResponse
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
                                          EbookGroup.getauthordetailsApiCall
                                              .message(
                                            containerGetauthordetailsApiResponse
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
                                  final authorList = EbookGroup.getauthordetailsApiCall.authorDetails(
                                    containerGetauthordetailsApiResponse.jsonBody,
                                  );
                                  final authorMap = authorList != null && authorList.isNotEmpty
                                      ? Map<String, dynamic>.from(authorList.first)
                                      : null;
                                  if (authorMap != null && _followersCount == null) {
                                    _followersCount = authorMap['followers_count'] as int? ?? 0;
                                    _isFollowing = authorMap['followed'] == true;
                                  }

                                  final authorName = (widget.name != null && widget.name!.isNotEmpty)
                                      ? widget.name!
                                      : (authorMap?['name']?.toString() ?? 'Name');
                                  final imageUrl = (widget.authorImage != null && widget.authorImage!.isNotEmpty)
                                      ? widget.authorImage!
                                      : '${FFAppConstants.imageUrl}${authorMap?['image'] ?? ""}';

                                  return RefreshIndicator(
                                    key: Key('RefreshIndicator_zhgjuy02'),
                                    onRefresh: () async {
                                      safeSetState(() {
                                        _model.apiRequestCompleter2 = null;
                                        _offset = 0;
                                        _hasMore = true;
                                      });
                                      await Future.wait([
                                        _model.waitForApiRequestCompleted2(),
                                        _loadMoreBooks(isFirstLoad: true),
                                      ]);
                                    },
                                    child: ListView(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        16.0,
                                        0,
                                        16.0,
                                      ),
                                      scrollDirection: Axis.vertical,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                              borderRadius: BorderRadius.circular(16.0),
                                              border: Border.all(
                                                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.4),
                                                width: 1.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  blurRadius: 12.0,
                                                  color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.05),
                                                  offset: const Offset(0.0, 4.0),
                                                )
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        width: 72.0,
                                                        height: 72.0,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                                                            width: 2.0,
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(2.0),
                                                          child: Container(
                                                            clipBehavior: Clip.antiAlias,
                                                            decoration: const BoxDecoration(
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: CachedNetworkImage(
                                                              fadeInDuration: const Duration(milliseconds: 200),
                                                              fadeOutDuration: const Duration(milliseconds: 200),
                                                              imageUrl: imageUrl,
                                                              fit: BoxFit.cover,
                                                              errorWidget: (context, error, stackTrace) => Image.asset(
                                                                'assets/images/error_image.png',
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16.0),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              authorName,
                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                    fontFamily: 'SF Pro Display',
                                                                    fontSize: 18.0,
                                                                    letterSpacing: 0.0,
                                                                    fontWeight: FontWeight.bold,
                                                                    lineHeight: 1.3,
                                                                  ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 6.0),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                                              decoration: BoxDecoration(
                                                                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(6.0),
                                                              ),
                                                              child: Text(FFLocalizations.of(context).getVariableText(enText: 'Author', bnText: 'লেখক'),
                                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                      fontFamily: 'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                      fontSize: 11.0,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16.0),
                                                  Divider(
                                                    height: 1.0,
                                                    thickness: 1.0,
                                                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.4),
                                                  ),
                                                  const SizedBox(height: 16.0),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          _buildStatItem(
                                                            context,
                                                            label: FFLocalizations.of(context).getVariableText(enText: 'Followers', bnText: 'অনুসারী'),
                                                            value: _followersCount != null ? '$_followersCount' : '${authorMap?['followers_count'] ?? 0}',
                                                          ),
                                                          const SizedBox(width: 24.0),
                                                          _buildStatItem(
                                                            context,
                                                            label: FFLocalizations.of(context).getVariableText(enText: 'Books', bnText: 'বই'),
                                                            value: '${authorMap?['books_count'] ?? 0}',
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height: 38.0,
                                                        width: 110.0,
                                                        child: ElevatedButton(
                                                          onPressed: (!FollowService.supportsFollowEndpoints || _isFollowLoading)
                                                              ? null
                                                              : _toggleFollow,
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: _isFollowing
                                                                ? Colors.transparent
                                                                : FlutterFlowTheme.of(context).primary,
                                                            elevation: _isFollowing ? 0 : 2,
                                                            side: _isFollowing
                                                                ? BorderSide(
                                                                    color: FlutterFlowTheme.of(context).alternate,
                                                                    width: 1.5,
                                                                  )
                                                                : BorderSide.none,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(20.0),
                                                            ),
                                                            padding: EdgeInsets.zero,
                                                          ),
                                                          child: _isFollowLoading
                                                              ? SizedBox(
                                                                  width: 16.0,
                                                                  height: 16.0,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth: 2.0,
                                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                                      _isFollowing
                                                                          ? FlutterFlowTheme.of(context).primary
                                                                          : Colors.white,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Text(
                                                                  _isFollowing ? 'Following' : 'Follow',
                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                        fontFamily: 'SF Pro Display',
                                                                        color: _isFollowing
                                                                            ? FlutterFlowTheme.of(context).secondaryText
                                                                            : Colors.white,
                                                                        fontSize: 13.0,
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
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
                                        if (EbookGroup.getauthordetailsApiCall
                                                    .description(
                                                  containerGetauthordetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                null &&
                                            EbookGroup.getauthordetailsApiCall
                                                    .description(
                                                  containerGetauthordetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                '')
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 16.0, 16.0, 8.0),
                                            child: Text(FFLocalizations.of(context).getVariableText(enText: 'Description', bnText: 'বিবরণ'),
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
                                        if (EbookGroup.getauthordetailsApiCall
                                                    .description(
                                                  containerGetauthordetailsApiResponse
                                                      .jsonBody,
                                                ) !=
                                                null &&
                                            EbookGroup.getauthordetailsApiCall
                                                    .description(
                                                  containerGetauthordetailsApiResponse
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
                                                      .getauthordetailsApiCall
                                                      .description(
                                                    containerGetauthordetailsApiResponse
                                                        .jsonBody,
                                                  ),
                                                  maxLength: 150,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if ((widget.authorId ?? '').isEmpty)
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 16.0, 16.0, 8.0),
                                            child: Text(FFLocalizations.of(context).getVariableText(enText: 'Personal information', bnText: 'ব্যক্তিগত তথ্য'),
                                              textAlign: TextAlign.start,
                                              maxLines: 1,
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
                                        if ((widget.authorId ?? '').isEmpty)
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
                                                  mainAxisSize:
                                                      MainAxisSize.max,
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
                                                                    .getauthordetailsApiCall
                                                                    .facebookurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                null ||
                                                            EbookGroup
                                                                    .getauthordetailsApiCall
                                                                    .facebookurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                '')) {
                                                          await launchURL(EbookGroup
                                                              .getauthordetailsApiCall
                                                              .facebookurl(
                                                            containerGetauthordetailsApiResponse
                                                                .jsonBody,
                                                          )!);
                                                        }
                                                      },
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0.0),
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
                                                                    .getauthordetailsApiCall
                                                                    .instagramurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                null ||
                                                            EbookGroup
                                                                    .getauthordetailsApiCall
                                                                    .instagramurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                '')) {
                                                          await launchURL(EbookGroup
                                                              .getauthordetailsApiCall
                                                              .instagramurl(
                                                            containerGetauthordetailsApiResponse
                                                                .jsonBody,
                                                          )!);
                                                        }
                                                      },
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0.0),
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
                                                                    .getauthordetailsApiCall
                                                                    .youtubeurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                null ||
                                                            EbookGroup
                                                                    .getauthordetailsApiCall
                                                                    .youtubeurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                '')) {
                                                          await launchURL(EbookGroup
                                                              .getauthordetailsApiCall
                                                              .youtubeurl(
                                                            containerGetauthordetailsApiResponse
                                                                .jsonBody,
                                                          )!);
                                                        }
                                                      },
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0.0),
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
                                                                    .getauthordetailsApiCall
                                                                    .websiteurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                null ||
                                                            EbookGroup
                                                                    .getauthordetailsApiCall
                                                                    .websiteurl(
                                                                  containerGetauthordetailsApiResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                '')) {
                                                          await launchURL(EbookGroup
                                                              .getauthordetailsApiCall
                                                              .websiteurl(
                                                            containerGetauthordetailsApiResponse
                                                                .jsonBody,
                                                          )!);
                                                        }
                                                      },
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0.0),
                                                        child: SvgPicture.asset(
                                                          'assets/images/link(1).svg',
                                                          width: 36.0,
                                                          height: 36.0,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 16.0)),
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
                                                child: _books.isEmpty && _isLoading
                                                    ? AboutAuthorSecShimmerWidget()
                                                    : Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (_books.isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          16.0,
                                                                          0.0,
                                                                          16.0,
                                                                          16.0),
                                                              child: Text(FFLocalizations.of(context).getVariableText(enText: 'Popular books', bnText: 'জনপ্রিয় বইসমূহ'),
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
                                                          if (_books.isNotEmpty)
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
                                                                  final bookDetailsList = _books;

                                                                  final screenWidth =
                                                                      MediaQuery.sizeOf(
                                                                              context)
                                                                          .width;
                                                                  final crossAxisCount =
                                                                      screenWidth <
                                                                              810.0
                                                                          ? 3
                                                                          : screenWidth <
                                                                                  1280.0
                                                                              ? 4
                                                                              : 6;

                                                                  return GridView
                                                                      .builder(
                                                                    shrinkWrap:
                                                                        true,
                                                                    physics:
                                                                        NeverScrollableScrollPhysics(),
                                                                    gridDelegate:
                                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                                      crossAxisCount:
                                                                          crossAxisCount,
                                                                      crossAxisSpacing:
                                                                         8.0,
                                                                      mainAxisSpacing:
                                                                          8.0,
                                                                      mainAxisExtent:
                                                                          235.0,
                                                                    ),
                                                                    itemCount:
                                                                        bookDetailsList
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            bookDetailsListIndex) {
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
                                                                            'Keyu5q_${getJsonField(
                                                                              bookDetailsListItem,
                                                                              r'''$.name''',
                                                                            ).toString()}',
                                                                          ),
                                                                          imageHeight: 155,
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
                                                                          id: getJsonField(
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
                                                                          isPurchased: _model
                                                                              .purchasedBookIds
                                                                              .contains(
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
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          if (_isLoading && _books.isNotEmpty)
                                                            Center(
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(12.0),
                                                                child: SizedBox(
                                                                  width: 32.0,
                                                                  height: 32.0,
                                                                  child: CircularProgressIndicator(
                                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                                      FlutterFlowTheme.of(context).primary,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
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

  Widget _buildStatItem(BuildContext context, {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'SF Pro Display',
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'SF Pro Display',
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 12.0,
              ),
        ),
      ],
    );
  }
}
