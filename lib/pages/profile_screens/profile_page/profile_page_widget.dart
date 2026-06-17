import 'dart:developer';
import '/main.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/single_appbar/single_appbar_widget.dart';
import '/pages/dialogs/log_out_dialog/log_out_dialog_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import '/pages/profile_screens/wallet_page/wallet_page_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'profile_page_model.dart';
import '/flutter_flow/internationalization.dart';
export 'profile_page_model.dart';

class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({super.key});

  static String routeName = 'ProfilePage';
  static String routePath = '/profilePage';

  @override
  State<ProfilePageWidget> createState() => _ProfilePageWidgetState();
}

class _ProfilePageWidgetState extends State<ProfilePageWidget>
    with TickerProviderStateMixin {
  late ProfilePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfilePageModel());

    animationsMap.addAll({
      'circleImageOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 50.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 80.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 150.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 250.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation5': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation6': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 350.0.ms,
            duration: 600.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin == true) {
        await _refreshUserDetailFromProfileApi();
      }
      if (mounted) {
        safeSetState(() {});
      }
    });
  }

  /// Keeps header (avatar, name, email) in sync with `GET /profile` after edits.
  Future<void> _refreshUserDetailFromProfileApi() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      return;
    }
    final response = await EbookGroup.getprofileApiCall.call(
      token: FFAppState().token,
    );
    if (!mounted || !response.succeeded) {
      return;
    }
    final fresh = EbookGroup.getprofileApiCall.userDetail(response.jsonBody);
    final existing = FFAppState().userDetail;
    if (fresh is Map) {
      FFAppState().userDetail = <String, dynamic>{
        if (existing is Map) ...Map<String, dynamic>.from(existing),
        ...Map<String, dynamic>.from(fresh),
      };
      FFAppState().update(() {});
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
            children: [
              wrapWithModel(
                model: _model.singleAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: SingleAppbarWidget(
                  title: FFLocalizations.of(context).getText('profile_title'),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          4.0,
                          0,
                          24.0,
                        ),
                        scrollDirection: Axis.vertical,
                        children: [
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    width: 100.0,
                                    height: 100.0,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: CachedNetworkImage(
                                      key: ValueKey<String>(
                                        '${getJsonField(FFAppState().userDetail, r'''$.image''').toString()}_${getJsonField(FFAppState().userDetail, r'''$.firstname''').toString()}_${getJsonField(FFAppState().userDetail, r'''$.lastname''').toString()}',
                                      ),
                                      fadeInDuration:
                                          Duration(milliseconds: 200),
                                      fadeOutDuration:
                                          Duration(milliseconds: 200),
                                      imageUrl:
                                          '${FFAppConstants.imageUrl}${getJsonField(
                                        FFAppState().userDetail,
                                        r'''$.image''',
                                      ).toString()}',
                                      cacheKey:
                                          '${getJsonField(FFAppState().userDetail, r'''$.image''').toString()}',
                                      fit: BoxFit.cover,
                                      errorWidget:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                        'assets/images/error_image.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ).animateOnPageLoad(animationsMap[
                                      'circleImageOnPageLoadAnimation']!),
                                  Text(
                                    valueOrDefault<String>(
                                      '${getJsonField(
                                        FFAppState().userDetail,
                                        r'''$.firstname''',
                                      ).toString()} ${getJsonField(
                                        FFAppState().userDetail,
                                        r'''$.lastname''',
                                        ).toString()}',
                                        FFLocalizations.of(context).getText('name_default'),
                                      ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 18.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          lineHeight: 1.5,
                                        ),
                                  ).animateOnPageLoad(animationsMap[
                                      'textOnPageLoadAnimation1']!),
                                  
                                  // Text(
                                  //   getJsonField(
                                  //     FFAppState().userDetail,
                                  //     r'''$.email''',
                                  //   ).toString(),
                                  //   textAlign: TextAlign.center,
                                  //   style: FlutterFlowTheme.of(context)
                                  //       .bodyMedium
                                  //       .override(
                                  //         fontFamily: 'SF Pro Display',
                                  //         color: FlutterFlowTheme.of(context)
                                  //             .black40,
                                  //         fontSize: 17.0,
                                  //         letterSpacing: 0.0,
                                  //         lineHeight: 1.5,
                                  //       ),
                                  // ).animateOnPageLoad(animationsMap[
                                  //     'textOnPageLoadAnimation2']!),
                                  
                                  if (getJsonField(
                                            FFAppState().userDetail,
                                            r'''$.referral_code''',
                                          ) !=
                                          null &&
                                      getJsonField(
                                            FFAppState().userDetail,
                                            r'''$.referral_code''',
                                          )
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                    InkWell(
                                      onTap: () async {
                                        final code = getJsonField(
                                          FFAppState().userDetail,
                                          r'''$.referral_code''',
                                        ).toString();
                                        await Clipboard.setData(
                                            ClipboardData(text: code));
                                        await actions.showCustomToastBottom(
                                            'Referral code copied');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Referral code: ${getJsonField(
                                            FFAppState().userDetail,
                                            r'''$.referral_code''',
                                          ).toString()}',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall,
                                        ),
                                      ),
                                    ),
                                ].divide(SizedBox(height: 4.0)),
                              ),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (FFAppState().isLogin == true) {
                                    await context.pushNamed(
                                      MyProfilePageWidget.routeName,
                                    );
                                    if (mounted) {
                                      await _refreshUserDetailFromProfileApi();
                                      safeSetState(() {});
                                    }
                                  } else {
                                    context
                                        .pushNamed(SignInPageWidget.routeName);
                                  }
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: SvgPicture.asset(
                                              'assets/images/pmp_ic.svg',
                                              colorFilter: ColorFilter.mode(
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.contain,
                                              alignment: Alignment(0.0, 0.0),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context).getText('my_profile'),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(FlutterFlowTheme.of(context).primaryText, BlendMode.srcIn),
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation1']!),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context
                                      .pushNamed(FavouritePageWidget.routeName);
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: SvgPicture.asset(
                                              'assets/images/pmf.svg',
                                              colorFilter: ColorFilter.mode(
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.contain,
                                              alignment: Alignment(0.0, 0.0),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Wishlist',
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(FlutterFlowTheme.of(context).primaryText, BlendMode.srcIn),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation2']!),
                            ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context
                                    .pushNamed(BestAuthorPageWidget.routeName);
                              },
                              child: Container(
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
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 8.0, 16.0, 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .lightGrey,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            'Author List',
                                            style:
                                                FlutterFlowTheme.of(context)
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
                                      ),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: SvgPicture.asset(
                                          'assets/images/arrow_right_ic.svg',
                                          width: 20.0,
                                          height: 20.0,
                                          colorFilter: ColorFilter.mode(
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                            BlendMode.srcIn,
                                          ),
                                          alignment: Alignment(0.0, 0.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'containerOnPageLoadAnimation2']!),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(
                                    BestNarratorPageWidget.routeName);
                              },
                              child: Container(
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
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 8.0, 16.0, 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .lightGrey,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.record_voice_over_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            'Narrator List',
                                            style:
                                                FlutterFlowTheme.of(context)
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
                                      ),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: SvgPicture.asset(
                                          'assets/images/arrow_right_ic.svg',
                                          width: 20.0,
                                          height: 20.0,
                                          colorFilter: ColorFilter.mode(
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                            BlendMode.srcIn,
                                          ),
                                          alignment: Alignment(0.0, 0.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'containerOnPageLoadAnimation3']!),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(
                                    BestPublisherPageWidget.routeName);
                              },
                              child: Container(
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
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 8.0, 16.0, 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .lightGrey,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.domain_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            'Publisher List',
                                            style:
                                                FlutterFlowTheme.of(context)
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
                                      ),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: SvgPicture.asset(
                                          'assets/images/arrow_right_ic.svg',
                                          width: 20.0,
                                          height: 20.0,
                                          colorFilter: ColorFilter.mode(
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                            BlendMode.srcIn,
                                          ),
                                          alignment: Alignment(0.0, 0.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'containerOnPageLoadAnimation4']!),
                          ),
                          
                          //implement here purchase books features
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  log(FFAppState().token);
                                  context.pushNamed(
                                      PurchaseHistoryPageWidget.routeName);
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: Icon(Icons.my_library_books_outlined),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context).getText('my_books'),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(FlutterFlowTheme.of(context).primaryText, BlendMode.srcIn),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation3']!),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(OrdersPageWidget.routeName);
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: const Icon(
                                            Icons.shopping_bag_outlined,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'My Orders',
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                BlendMode.srcIn),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation3']!),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context
                                      .pushNamed(DownloadPageWidget.routeName);
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: SvgPicture.asset(
                                              'assets/images/download.svg',
                                              colorFilter: ColorFilter.mode(
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.contain,
                                              alignment: Alignment(0.0, 0.0),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context).getText('download'),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation3']!),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                      SubscriptionPageWidget.routeName);
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: SvgPicture.asset(
                                              'assets/images/premium.svg',
                                              colorFilter: ColorFilter.mode(
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.contain,
                                              alignment: Alignment(0.0, 0.0),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context).getText('subscription'),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation4']!),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const WalletPageWidget(),
                                    ),
                                  );
                                  safeSetState(() {});
                                },
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Icon(
                                            Icons.stars_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Coins & Rewards',
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation4']!),
                            ),
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _showReferAndEarnBottomSheet(context);
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 16.0,
                                        color: FlutterFlowTheme.of(context)
                                            .shadowColor,
                                        offset: const Offset(
                                          0.0,
                                          4.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              const AlignmentDirectional(0.0, 0.0),
                                          child: Icon(
                                            Icons.card_giftcard_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Refer & Earn',
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: const Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation4']!),
                            ),
                          
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: Container(
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
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    8.0, 8.0, 16.0, 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Container(
                                      width: 48.0,
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .lightGrey,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment:
                                          AlignmentDirectional(0.0, 0.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: Icon(
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Icons.dark_mode
                                              : Icons.light_mode,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                16.0, 0.0, 0.0, 0.0),
                                        child: Text(
                                          FFLocalizations.of(context).getText('dark_mode'),
                                          style: FlutterFlowTheme.of(context)
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
                                    ),
                                    Switch.adaptive(
                                      value: Theme.of(context).brightness ==
                                          Brightness.dark,
                                      onChanged: (value) {
                                        final mode = value
                                            ? ThemeMode.dark
                                            : ThemeMode.light;
                                        MyApp.of(context)
                                            .setThemeMode(mode);
                                      },
                                      activeColor: FlutterFlowTheme.of(context)
                                          .primary,
                                      activeTrackColor:
                                          FlutterFlowTheme.of(context)
                                              .accent1,
                                    ),
                                  ],
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'containerOnPageLoadAnimation5']!),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(SettingsPageWidget.routeName);
                              },
                              child: Container(
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
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 8.0, 16.0, 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .lightGrey,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/pSetting.svg',
                                            colorFilter: ColorFilter.mode(
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText('settings'),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 17.0,
                                                  letterSpacing: 0.0,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                        ),
                                      ),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: SvgPicture.asset(
                                          'assets/images/arrow_right_ic.svg',
                                          width: 20.0,
                                          height: 20.0,
                                          colorFilter: ColorFilter.mode(
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                            BlendMode.srcIn,
                                          ),
                                          fit: BoxFit.contain,
                                          alignment: Alignment(0.0, 0.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'containerOnPageLoadAnimation5']!),
                          ),

                          // Padding(
                          //   padding: EdgeInsetsDirectional.fromSTEB(
                          //       16.0, 0.0, 16.0, 16.0),
                          //   child: InkWell(
                          //     splashColor: Colors.transparent,
                          //     focusColor: Colors.transparent,
                          //     hoverColor: Colors.transparent,
                          //     highlightColor: Colors.transparent,
                          //     onTap: () async {
                          //       await actions.showCustomToastBottom(
                          //         FFLocalizations.of(context)
                          //             .getText('coming_soon'),
                          //       );
                          //     },
                          //     child: Container(
                          //       width: double.infinity,
                          //       decoration: BoxDecoration(
                          //         color: FlutterFlowTheme.of(context)
                          //             .secondaryBackground,
                          //         boxShadow: [
                          //           BoxShadow(
                          //             blurRadius: 16.0,
                          //             color: FlutterFlowTheme.of(context)
                          //                 .shadowColor,
                          //             offset: Offset(
                          //               0.0,
                          //               4.0,
                          //             ),
                          //           )
                          //         ],
                          //         borderRadius: BorderRadius.circular(12.0),
                          //       ),
                          //       child: Padding(
                          //         padding: EdgeInsetsDirectional.fromSTEB(
                          //             8.0, 8.0, 16.0, 8.0),
                          //         child: Row(
                          //           mainAxisSize: MainAxisSize.max,
                          //           children: [
                          //             Container(
                          //               width: 48.0,
                          //               height: 48.0,
                          //               decoration: BoxDecoration(
                          //                 color: FlutterFlowTheme.of(context)
                          //                     .lightGrey,
                          //                 shape: BoxShape.circle,
                          //               ),
                          //               alignment:
                          //                   AlignmentDirectional(0.0, 0.0),
                          //               child: Icon(
                          //                 Icons.help_outline_rounded,
                          //                 color: FlutterFlowTheme.of(context)
                          //                     .primaryText,
                          //                 size: 24.0,
                          //               ),
                          //             ),
                          //             Expanded(
                          //               child: Padding(
                          //                 padding:
                          //                     EdgeInsetsDirectional.fromSTEB(
                          //                         16.0, 0.0, 0.0, 0.0),
                          //                 child: Text(
                          //                   'Help & Support',
                          //                   style:
                          //                       FlutterFlowTheme.of(context)
                          //                           .bodyMedium
                          //                           .override(
                          //                             fontFamily:
                          //                                 'SF Pro Display',
                          //                             fontSize: 17.0,
                          //                             letterSpacing: 0.0,
                          //                             lineHeight: 1.5,
                          //                           ),
                          //                 ),
                          //               ),
                          //             ),
                          //             ClipRRect(
                          //               borderRadius:
                          //                   BorderRadius.circular(0.0),
                          //               child: SvgPicture.asset(
                          //                 'assets/images/arrow_right_ic.svg',
                          //                 width: 20.0,
                          //                 height: 20.0,
                          //                 colorFilter: ColorFilter.mode(
                          //                   FlutterFlowTheme.of(context)
                          //                       .primaryText,
                          //                   BlendMode.srcIn,
                          //                 ),
                          //                 alignment: Alignment(0.0, 0.0),
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ).animateOnPageLoad(animationsMap[
                          //       'containerOnPageLoadAnimation5']!),
                          // ),
                          
                          SizedBox(height: 16),
                          Builder(
                            builder: (context) => Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (FFAppState().isLogin == true) {
                                    await showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        return Dialog(
                                          elevation: 0,
                                          insetPadding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          alignment: AlignmentDirectional(
                                                  0.0, 0.0)
                                              .resolve(
                                                  Directionality.of(dialogContext)),
                                          child: GestureDetector(
                                            onTap: () {
                                              FocusScope.of(dialogContext)
                                                  .unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: LogOutDialogWidget(
                                              onTapLogout: () async {
                                                if (FFAppState().tokenFcm.isNotEmpty) {
                                                  await EbookGroup.unregisterNotificationTokenApiCall.call(
                                                    tokenFcm: FFAppState().tokenFcm,
                                                    token: FFAppState().token,
                                                  );
                                                }
                                                _model.signOutApi =
                                                    await EbookGroup
                                                        .signoutApiCall
                                                        .call(
                                                  userId: FFAppState().userId,
                                                  deviceId:
                                                      FFAppState().deviceId,
                                                  token: FFAppState().token,
                                                );

                                                if (_model.signOutApi?.statusCode == 401) {
                                                  Navigator.pop(dialogContext);
                                                  FFAppState().isLogin =
                                                      false;
                                                  FFAppState().token = '';
                                                  FFAppState().refreshToken =
                                                      '';
                                                  FFAppState().favChange =
                                                      false;
                                                  FFAppState().bookId = '';
                                                  FFAppState()
                                                      .homePageLiveReadBook = '';
                                                  FFAppState()
                                                      .homePageCurrentPdfIndex = 1;
                                                  FFAppState().searchList =
                                                      [];
                                                  FFAppState().userId = '';
                                                  FFAppState().userDetail =
                                                      null;
                                                  FFAppState().update(() {});
                                                  FFAppState()
                                                      .clearGetFavouriteBookCacheCache();
                                                  await actions
                                                      .showCustomToastBottom(
                                                    EbookGroup.signoutApiCall
                                                            .message(
                                                          (_model.signOutApi
                                                                  ?.jsonBody ??
                                                              ''),
                                                        ) ??
                                                        'Session expired. Please login again.',
                                                  );
                                                  if (context.mounted) {
                                                    context.pushNamed(
                                                        SignInPageWidget
                                                            .routeName);
                                                  }
                                                  return;
                                                }

                                                if (EbookGroup.signoutApiCall
                                                        .success(
                                                      (_model.signOutApi
                                                              ?.jsonBody ??
                                                          ''),
                                                    ) ==
                                                    2) {
                                                  await actions
                                                      .showCustomToastBottom(
                                                    EbookGroup.signoutApiCall
                                                        .message(
                                                      (_model.signOutApi
                                                              ?.jsonBody ??
                                                          ''),
                                                    )!,
                                                  );
                                                } else {
                                                  if (EbookGroup.signoutApiCall
                                                          .success(
                                                        (_model.signOutApi
                                                                ?.jsonBody ??
                                                            ''),
                                                      ) ==
                                                      1) {
                                                    Navigator.pop(dialogContext);
                                                    FFAppState().isLogin =
                                                        false;
                                                    FFAppState().token = '';
                                                    FFAppState().refreshToken =
                                                        '';
                                                    FFAppState().favChange =
                                                        false;
                                                    FFAppState().bookId = '';
                                                    FFAppState()
                                                        .homePageLiveReadBook = '';
                                                    FFAppState()
                                                        .homePageCurrentPdfIndex = 1;
                                                    FFAppState().searchList =
                                                        [];
                                                    FFAppState().userId = '';
                                                    FFAppState().userDetail =
                                                        null;
                                                    FFAppState().update(() {});
                                                    FFAppState()
                                                        .clearGetFavouriteBookCacheCache();
                                                    await actions
                                                        .showCustomToastBottom(
                                                      EbookGroup.signoutApiCall
                                                          .message(
                                                        (_model.signOutApi
                                                                ?.jsonBody ??
                                                            ''),
                                                      )!,
                                                    );
                                                  } else {
                                                    await actions
                                                        .showCustomToastBottom(
                                                      EbookGroup.signoutApiCall
                                                          .message(
                                                        (_model.signOutApi
                                                                ?.jsonBody ??
                                                            ''),
                                                      )!,
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    context
                                        .pushNamed(SignInPageWidget.routeName);
                                  }
                                  safeSetState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 16.0,
                                        color: Color(0x14000000),
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
                                        8.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(0.0),
                                            child: SvgPicture.asset(
                                              'assets/images/pLogout.svg',
                                              colorFilter: ColorFilter.mode(
                                                FlutterFlowTheme.of(context)
                                                    .primaryText,
                                                BlendMode.srcIn,
                                              ),
                                              fit: BoxFit.contain,
                                              alignment: Alignment(0.0, 0.0),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFAppState().isLogin == true
                                                  ? FFLocalizations.of(context).getText('log_out')
                                                  : FFLocalizations.of(context).getText('sign_in'),
                                              style:
                                                  FlutterFlowTheme.of(context)
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
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          child: SvgPicture.asset(
                                            'assets/images/arrow_right_ic.svg',
                                            width: 20.0,
                                            height: 20.0,
                                            colorFilter: ColorFilter.mode(
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              BlendMode.srcIn,
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: Alignment(0.0, 0.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation6']!),
                            ),
                          ),
                         
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 16.0, 20.0, 12.0),
                            child: Text(
                              'We\'re on social media',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ).animateOnPageLoad(animationsMap[
                                'textOnPageLoadAnimation1']!),
                          ),
                          _buildSocialItem(
                            context,
                            'Like Facebook Page',
                            'assets/images/facebook_ic.png',
                            'https://www.facebook.com/boiarobd',
                            isImage: true,
                          ).animateOnPageLoad(animationsMap[
                              'containerOnPageLoadAnimation5']!),
                          _buildSocialItem(
                            context,
                            'Join Facebook Community',
                            Icons.groups_rounded,
                            'https://www.facebook.com/groups/boiaro.pathok.adda',
                            iconColor: Color(0xFF1877F2),
                          ).animateOnPageLoad(animationsMap[
                              'containerOnPageLoadAnimation5']!),
                          _buildSocialItem(
                            context,
                            'Subscribe Youtube Channel',
                            'assets/images/youtube.svg',
                            'https://www.youtube.com/@boiaro',
                          ).animateOnPageLoad(animationsMap[
                              'containerOnPageLoadAnimation5']!),
                        ],
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

  Widget _buildSocialItem(
    BuildContext context,
    String label,
    dynamic icon,
    String url, {
    bool isImage = false,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
      child: InkWell(
        onTap: () async {
          await launchURL(url);
        },
        child: Container(
          width: double.infinity,
          height: 60.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: [
              BoxShadow(
                blurRadius: 12.0,
                color: FlutterFlowTheme.of(context).shadowColor,
                offset: Offset(0.0, 4.0),
              )
            ],
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).lightGrey,
                    shape: BoxShape.circle,
                  ),
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: icon is IconData
                      ? Icon(icon, color: iconColor ?? FlutterFlowTheme.of(context).primary, size: 24.0)
                      : (isImage
                          ? Image.asset(icon, width: 28.0, height: 28.0, fit: BoxFit.contain)
                          : SvgPicture.asset(icon, width: 28.0, height: 28.0, fit: BoxFit.contain)),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                    child: Text(
                      label,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReferAndEarnBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32.0),
                  topRight: Radius.circular(32.0),
                ),
              ),
              child: Stack(
                alignment: AlignmentDirectional(1.0, -1.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              width: 70.0,
                              height: 5.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(100.0),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Refer & Earn',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1.0,
                          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                        ),
                        Expanded(
                          child: FutureBuilder<ApiCallResponse>(
                            future: EbookGroup.getReferralInfoCall.call(
                              token: FFAppState().token,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError ||
                                  snapshot.data == null ||
                                  !snapshot.data!.succeeded) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: FlutterFlowTheme.of(context).error,
                                        size: 40.0,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load referral details',
                                        style: FlutterFlowTheme.of(context).bodyMedium,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final data = snapshot.data!.jsonBody;
                              final String refCode = getJsonField(data, r'$.referral_code')?.toString() ?? '';
                              final int totalReferrals = castToType<int>(getJsonField(data, r'$.total_referrals')) ?? 0;
                              final int totalEarned = castToType<int>(getJsonField(data, r'$.total_earned')) ?? 0;
                              final int signupReward = castToType<int>(getJsonField(data, r'$.signup_reward_coins')) ?? 10;
                              final int referredBonus = castToType<int>(getJsonField(data, r'$.referred_bonus_coins')) ?? 5;

                              return ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                children: [
                                  Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.card_giftcard_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
                                        size: 44,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      'Invite your friends & earn coins!',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRefStatCard(
                                          context,
                                          'Total Referrals',
                                          totalReferrals.toString(),
                                          Icons.people_alt_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildRefStatCard(
                                          context,
                                          'Coins Earned',
                                          '$totalEarned Coins',
                                          Icons.monetization_on_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'YOUR REFERRAL CODE',
                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: 'SF Pro Display',
                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                letterSpacing: 1.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context).primaryBackground,
                                            borderRadius: BorderRadius.circular(12.0),
                                            border: Border.all(
                                              color: FlutterFlowTheme.of(context).alternate,
                                              style: BorderStyle.solid,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: SelectableText(
                                            refCode,
                                            style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 22.0,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2.0,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await Clipboard.setData(ClipboardData(text: refCode));
                                            await actions.showCustomToastBottom('Referral code copied!');
                                          },
                                          icon: const Icon(Icons.copy_rounded, size: 18),
                                          label: const Text('Copy Code'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FlutterFlowTheme.of(context).primary,
                                            foregroundColor: FlutterFlowTheme.of(context).primaryBackground,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'How it works',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(
                                    context,
                                    '1',
                                    'Share your code with friends',
                                    'Send them your unique referral code.',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(
                                    context,
                                    '2',
                                    'They sign up & get coins',
                                    'Your friend receives $signupReward coins immediately upon signup.',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(
                                    context,
                                    '3',
                                    'You earn rewards',
                                    'You receive $referredBonus coins once they register using your code.',
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 16.0, 0.0),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).lightGrey,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 22.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 12.0,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String stepNumber, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'SF Pro Display',
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12.0,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
