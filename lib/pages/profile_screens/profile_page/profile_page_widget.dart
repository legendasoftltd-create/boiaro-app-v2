import '/main.dart';

import '/backend/api_requests/api_calls.dart';
import '/services/revenue_cat_service.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import 'dart:io';
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

  Future<List<ApiCallResponse>>? _dashboardStatsFuture;

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
        _loadDashboardStats();
      }
      if (mounted) {
        safeSetState(() {});
      }
    });
  }

  void _loadDashboardStats() {
    if (FFAppState().isLogin == true && FFAppState().token.trim().isNotEmpty) {
      _dashboardStatsFuture = Future.wait([
        EbookGroup.getGamificationSummaryCall.call(token: FFAppState().token),
        EbookGroup.usersubscriptionvalidityApiCall.call(token: FFAppState().token),
      ]);
    }
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
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          4.0,
                          0,
                          24.0,
                        ),
                        scrollDirection: Axis.vertical,
                        children: [
                          // 1. Header (User Profile Card or Welcome Guest Card)
                          if (FFAppState().isLogin == true)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                                    FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.15),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10.0,
                                    color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.04),
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
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 64.0,
                                          height: 64.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: FlutterFlowTheme.of(context).primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(32.0),
                                            child: CachedNetworkImage(
                                              key: ValueKey<String>(
                                                '${getJsonField(FFAppState().userDetail, r'''$.image''').toString()}_${getJsonField(FFAppState().userDetail, r'''$.firstname''').toString()}_${getJsonField(FFAppState().userDetail, r'''$.lastname''').toString()}',
                                              ),
                                              fadeInDuration: const Duration(milliseconds: 200),
                                              fadeOutDuration: const Duration(milliseconds: 200),
                                              imageUrl: '${FFAppConstants.imageUrl}${getJsonField(
                                                FFAppState().userDetail,
                                                r'''$.image''',
                                              ).toString()}',
                                              cacheKey: '${getJsonField(FFAppState().userDetail, r'''$.image''').toString()}',
                                              fit: BoxFit.cover,
                                              errorWidget: (context, error, stackTrace) => Image.asset(
                                                'assets/images/error_image.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ).animateOnPageLoad(animationsMap['circleImageOnPageLoadAnimation']!),
                                        const SizedBox(width: 14.0),
                                        // User Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
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
                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                      fontFamily: 'SF Pro Display',
                                                      fontSize: 18.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ).animateOnPageLoad(animationsMap['textOnPageLoadAnimation1']!),
                                              if (getJsonField(FFAppState().userDetail, r'''$.email''') != null &&
                                                  getJsonField(FFAppState().userDetail, r'''$.email''').toString().trim().isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text(
                                                    getJsonField(FFAppState().userDetail, r'''$.email''').toString(),
                                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                                          fontFamily: 'SF Pro Display',
                                                          color: FlutterFlowTheme.of(context).secondaryText,
                                                          fontSize: 13.0,
                                                        ),
                                                  ),
                                                ),
                                              // Referral Tag
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
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6.0),
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final code = getJsonField(
                                                        FFAppState().userDetail,
                                                        r'''$.referral_code''',
                                                      ).toString();
                                                      await Clipboard.setData(ClipboardData(text: code));
                                                      await actions.showCustomToastBottom(
                                                          FFLocalizations.of(context).getVariableText(enText: 'Referral code copied', bnText: 'রেফারেল কোড কপি হয়েছে'));
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                                                        borderRadius: BorderRadius.circular(100.0),
                                                        border: Border.all(
                                                          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.copy_rounded,
                                                            size: 10.0,
                                                            color: FlutterFlowTheme.of(context).primary,
                                                          ),
                                                          const SizedBox(width: 4.0),
                                                          Text(
                                                            '${FFLocalizations.of(context).getVariableText(enText: 'Referral', bnText: 'রেফারেল')}: ${getJsonField(
                                                              FFAppState().userDetail,
                                                              r'''$.referral_code''',
                                                            ).toString()}',
                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                  fontSize: 11.0,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    FutureBuilder<List<ApiCallResponse>>(
                                      future: _dashboardStatsFuture ??= (FFAppState().isLogin && FFAppState().token.trim().isNotEmpty
                                          ? Future.wait([
                                              EbookGroup.getGamificationSummaryCall.call(token: FFAppState().token),
                                              EbookGroup.usersubscriptionvalidityApiCall.call(token: FFAppState().token),
                                            ])
                                          : null),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 12.0),
                                            child: Center(
                                              child: SizedBox(
                                                width: 16.0,
                                                height: 16.0,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  color: FlutterFlowTheme.of(context).primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        int coinBalance = 0;
                                        int totalPoints = 0;
                                        String subPlanName = FFLocalizations.of(context).getVariableText(enText: 'Free Tier', bnText: 'ফ্রি প্ল্যান');
                                        int daysLeft = 0;

                                        if (snapshot.hasData) {
                                          final summaryRes = snapshot.data![0];
                                          final validityRes = snapshot.data![1];

                                          if (summaryRes.succeeded) {
                                            coinBalance = getJsonField(summaryRes.jsonBody, r'''$.wallet.balance''') ??
                                                getJsonField(summaryRes.jsonBody, r'''$.data.wallet.balance''') ?? 0;
                                            totalPoints = getJsonField(summaryRes.jsonBody, r'''$.total_points''') ??
                                                getJsonField(summaryRes.jsonBody, r'''$.data.total_points''') ?? 0;
                                          }

                                          if (validityRes.succeeded) {
                                            final hasActiveSub = EbookGroup.usersubscriptionvalidityApiCall.success(validityRes.jsonBody) == 1;
                                            if (hasActiveSub) {
                                              subPlanName = EbookGroup.usersubscriptionvalidityApiCall.name(validityRes.jsonBody) ?? 'Premium';
                                              daysLeft = EbookGroup.usersubscriptionvalidityApiCall.daysLeft(validityRes.jsonBody) ?? 0;
                                            }
                                          }
                                        }

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                                              child: Divider(
                                                height: 1.0,
                                                thickness: 1.0,
                                                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                                              ),
                                            ),
                                            IntrinsicHeight(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  // Subscription
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () => context.pushNamed(SubscriptionPageWidget.routeName),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.workspace_premium_rounded,
                                                            color: Colors.amber[700],
                                                            size: 20.0,
                                                          ),
                                                          const SizedBox(height: 4.0),
                                                          Text(
                                                            subPlanName,
                                                            textAlign: TextAlign.center,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13.0,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 2.0),
                                                          Text(
                                                            daysLeft > 0
                                                                ? FFLocalizations.of(context).getVariableText(
                                                                    enText: '$daysLeft days left',
                                                                    bnText: '$daysLeft দিন বাকি')
                                                                : FFLocalizations.of(context).getVariableText(
                                                                    enText: 'Subscribe Now',
                                                                    bnText: 'সাবস্ক্রাইব করুন'),
                                                            textAlign: TextAlign.center,
                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                  fontSize: 10.0,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  VerticalDivider(
                                                    width: 1.0,
                                                    thickness: 1.0,
                                                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                                                  ),
                                                  // Coins
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () async {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => const WalletPageWidget(),
                                                          ),
                                                        );
                                                        safeSetState(() {});
                                                      },
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.monetization_on_rounded,
                                                            color: Colors.orange[600],
                                                            size: 20.0,
                                                          ),
                                                          const SizedBox(height: 4.0),
                                                          Text(
                                                            '$coinBalance',
                                                            textAlign: TextAlign.center,
                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13.0,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 2.0),
                                                          Text(
                                                            FFLocalizations.of(context).getVariableText(
                                                                enText: 'Coins Available',
                                                                bnText: 'কয়েন আছে'),
                                                            textAlign: TextAlign.center,
                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                  fontSize: 10.0,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  VerticalDivider(
                                                    width: 1.0,
                                                    thickness: 1.0,
                                                    color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                                                  ),
                                                  // Reward Points
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () async {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => const WalletPageWidget(),
                                                          ),
                                                        );
                                                        safeSetState(() {});
                                                      },
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.stars_rounded,
                                                            color: Colors.blue[600],
                                                            size: 20.0,
                                                          ),
                                                          const SizedBox(height: 4.0),
                                                          Text(
                                                            '$totalPoints',
                                                            textAlign: TextAlign.center,
                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13.0,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 2.0),
                                                          Text(
                                                            FFLocalizations.of(context).getVariableText(
                                                                enText: 'Points Earned',
                                                                bnText: 'পয়েন্ট অর্জিত'),
                                                            textAlign: TextAlign.center,
                                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                  fontSize: 10.0,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                                    FlutterFlowTheme.of(context).secondaryBackground,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10.0,
                                    color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.04),
                                    offset: const Offset(0.0, 4.0),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Left Icon
                                    Container(
                                      width: 48.0,
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
                                        size: 24.0,
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    // Middle details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getVariableText(enText: 'Welcome to BoiAro', bnText: 'বইআড়ো-তে স্বাগতম'),
                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            FFLocalizations.of(context).getVariableText(
                                                enText: 'Sign in to access your library',
                                                bnText: 'আপনার লাইব্রেরি অ্যাক্সেস করতে সাইন ইন করুন'),
                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                  fontFamily: 'SF Pro Display',
                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                  fontSize: 12.0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    // Right Login Button
                                    ElevatedButton(
                                      onPressed: () async {
                                        context.pushNamed(SignInPageWidget.routeName);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FlutterFlowTheme.of(context).primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                      ),
                                      child: Text(
                                        FFLocalizations.of(context).getText('sign_in'),
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'SF Pro Display',
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation1']!),

                          // 2. Quick Library Grid (2x2)
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 12.0,
                                mainAxisSpacing: 12.0,
                                childAspectRatio: 2.0,
                                children: [
                                  _buildQuickGridItem(
                                    context,
                                    FFLocalizations.of(context).getText('my_books'),
                                    FFLocalizations.of(context).getVariableText(enText: 'Purchases', bnText: 'ক্রয়কৃত বই'),
                                    Icons.my_library_books_rounded,
                                    () => context.pushNamed(PurchaseHistoryPageWidget.routeName),
                                  ),
                                  _buildQuickGridItem(
                                    context,
                                    FFLocalizations.of(context).getText('download'),
                                    FFLocalizations.of(context).getVariableText(enText: 'Offline read', bnText: 'অফলাইন রিড'),
                                    Icons.download_for_offline_rounded,
                                    () => context.pushNamed(DownloadPageWidget.routeName),
                                  ),
                                  _buildQuickGridItem(
                                    context,
                                    FFLocalizations.of(context).getVariableText(enText: 'Wishlist', bnText: 'উইশলিস্ট'),
                                    FFLocalizations.of(context).getVariableText(enText: 'Favorites', bnText: 'পছন্দসমূহ'),
                                    Icons.favorite_rounded,
                                    () => context.pushNamed(FavouritePageWidget.routeName),
                                  ),
                                  _buildQuickGridItem(
                                    context,
                                    FFLocalizations.of(context).getVariableText(enText: 'Coins & Rewards', bnText: 'কয়েন ও পুরস্কার'),
                                    FFLocalizations.of(context).getVariableText(enText: 'Earn & Unlock', bnText: 'কয়েন ও পুরস্কার'),
                                    Icons.stars_rounded,
                                    () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const WalletPageWidget(),
                                        ),
                                      );
                                      safeSetState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation2']!),

                          // 3. Preferences Card (Theme & Language Segmented Picker)
                          _buildGroupCard(
                            context,
                            title: FFLocalizations.of(context).getVariableText(enText: 'PREFERENCES', bnText: 'পছন্দসমূহ'),
                            children: [
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getText('language'),
                                icon: Icon(
                                  Icons.language_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 20,
                                ),
                                onTap: () {}, // Handled by inline toggle
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).lightGrey,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (FFLocalizations.of(context).locale.languageCode != 'en') {
                                            MyApp.of(context).setLocale('en');
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FFLocalizations.of(context).locale.languageCode == 'en'
                                                ? FlutterFlowTheme.of(context).primary
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                          child: Text(
                                            'English',
                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: FFLocalizations.of(context).locale.languageCode == 'en'
                                                      ? Colors.white
                                                      : FlutterFlowTheme.of(context).secondaryText,
                                                ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (FFLocalizations.of(context).locale.languageCode != 'bn') {
                                            MyApp.of(context).setLocale('bn');
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FFLocalizations.of(context).locale.languageCode == 'bn'
                                                ? FlutterFlowTheme.of(context).primary
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                          child: Text(
                                            'বাংলা',
                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: FFLocalizations.of(context).locale.languageCode == 'bn'
                                                      ? Colors.white
                                                      : FlutterFlowTheme.of(context).secondaryText,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                showDivider: true,
                              ),
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getText('dark_mode'),
                                icon: Icon(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 20,
                                ),
                                onTap: () {
                                  final mode = Theme.of(context).brightness == Brightness.dark
                                      ? ThemeMode.light
                                      : ThemeMode.dark;
                                  MyApp.of(context).setThemeMode(mode);
                                },
                                trailing: Switch.adaptive(
                                  value: Theme.of(context).brightness == Brightness.dark,
                                  onChanged: (value) {
                                    final mode = value ? ThemeMode.dark : ThemeMode.light;
                                    MyApp.of(context).setThemeMode(mode);
                                  },
                                  activeColor: FlutterFlowTheme.of(context).primary,
                                  activeTrackColor: FlutterFlowTheme.of(context).accent1,
                                ),
                                showDivider: false,
                              ),
                            ],
                          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation3']!),

                          // 4. Account Services Card (Only shown if logged in)
                          if (FFAppState().isLogin == true)
                            _buildGroupCard(
                              context,
                              title: FFLocalizations.of(context).getVariableText(enText: 'ACCOUNT & SERVICES', bnText: 'অ্যাকাউন্ট এবং সেবা সমূহ'),
                              children: [
                                _buildRowItem(
                                  context,
                                  label: FFLocalizations.of(context).getText('my_profile'),
                                  icon: SvgPicture.asset(
                                    'assets/images/pmp_ic.svg',
                                    colorFilter: ColorFilter.mode(
                                      FlutterFlowTheme.of(context).primaryText,
                                      BlendMode.srcIn,
                                    ),
                                    width: 20,
                                    height: 20,
                                  ),
                                  onTap: () async {
                                    await context.pushNamed(MyProfilePageWidget.routeName);
                                    await _refreshUserDetailFromProfileApi();
                                    safeSetState(() {});
                                  },
                                  showDivider: true,
                                ),
                                _buildRowItem(
                                  context,
                                  label: FFLocalizations.of(context).getVariableText(enText: 'My Orders', bnText: 'আমার অর্ডার'),
                                  icon: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    size: 20,
                                  ),
                                  onTap: () => context.pushNamed(OrdersPageWidget.routeName),
                                  showDivider: !Platform.isIOS,
                                ),
                                if (!Platform.isIOS)
                                  _buildRowItem(
                                    context,
                                    label: FFLocalizations.of(context).getText('subscription'),
                                    icon: SvgPicture.asset(
                                      'assets/images/premium.svg',
                                      colorFilter: ColorFilter.mode(
                                        FlutterFlowTheme.of(context).primaryText,
                                        BlendMode.srcIn,
                                      ),
                                      width: 20,
                                      height: 20,
                                    ),
                                    onTap: () => context.pushNamed(SubscriptionPageWidget.routeName),
                                    showDivider: true,
                                  ),
                                _buildRowItem(
                                  context,
                                  label: FFLocalizations.of(context).getVariableText(enText: 'Refer & Earn', bnText: 'রেফার করুন ও আয় করুন'),
                                  icon: Icon(
                                    Icons.card_giftcard_rounded,
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    size: 20,
                                  ),
                                  onTap: () => _showReferAndEarnBottomSheet(context),
                                  showDivider: false,
                                ),
                              ],
                            ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation4']!),

                          // 5. Explore Creators Card
                          _buildGroupCard(
                            context,
                            title: FFLocalizations.of(context).getVariableText(enText: 'EXPLORE CREATORS', bnText: 'সেরা স্রষ্টা ও পার্টনারস'),
                            children: [
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getVariableText(enText: 'Author List', bnText: 'লেখক তালিকা'),
                                icon: Icon(
                                  Icons.person_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 20,
                                ),
                                onTap: () => context.pushNamed(BestAuthorPageWidget.routeName),
                                showDivider: true,
                              ),
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getVariableText(enText: 'Narrator List', bnText: 'ভয়েস আর্টিস্ট তালিকা'),
                                icon: Icon(
                                  Icons.record_voice_over_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 20,
                                ),
                                onTap: () => context.pushNamed(BestNarratorPageWidget.routeName),
                                showDivider: true,
                              ),
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getVariableText(enText: 'Publisher List', bnText: 'প্রকাশক তালিকা'),
                                icon: Icon(
                                  Icons.domain_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 20,
                                ),
                                onTap: () => context.pushNamed(BestPublisherPageWidget.routeName),
                                showDivider: false,
                              ),
                            ],
                          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation4']!),

                          // 6. Support & Settings Card
                          _buildGroupCard(
                            context,
                            title: FFLocalizations.of(context).getVariableText(enText: 'SUPPORT & SETTINGS', bnText: 'সহায়তা এবং সেটিংস'),
                            children: [
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getText('settings'),
                                icon: SvgPicture.asset(
                                  'assets/images/pSetting.svg',
                                  colorFilter: ColorFilter.mode(
                                    FlutterFlowTheme.of(context).primaryText,
                                    BlendMode.srcIn,
                                  ),
                                  width: 20,
                                  height: 20,
                                ),
                                onTap: () => context.pushNamed(SettingsPageWidget.routeName),
                                showDivider: true,
                              ),
                              _buildRowItem(
                                context,
                                label: FFLocalizations.of(context).getVariableText(enText: 'Help & Support', bnText: 'হেল্প এন্ড সাপোর্ট'),
                                icon: Icon(
                                  Icons.support_agent_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 20,
                                ),
                                onTap: () {
                                  if (FFAppState().isLogin == true) {
                                    context.pushNamed(SupportTicketsListPageWidget.routeName);
                                  } else {
                                    context.pushNamed(SignInPageWidget.routeName);
                                  }
                                },
                                showDivider: false,
                              ),
                            ],
                          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation5']!),

                          // 7. Social Footer Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                            child: Column(
                              children: [
                                Text(
                                  FFLocalizations.of(context).getVariableText(
                                    enText: "We're on social media",
                                    bnText: 'আমরা সোশ্যাল মিডিয়ায় আছি',
                                  ),
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                      ),
                                ),
                                const SizedBox(height: 12.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSocialIcon(
                                      context,
                                      'assets/images/facebook_ic.png',
                                      'https://www.facebook.com/boiarobd',
                                      isImage: true,
                                    ),
                                    const SizedBox(width: 20.0),
                                    _buildSocialIcon(
                                      context,
                                      Icons.groups_rounded,
                                      'https://www.facebook.com/groups/boiaro.pathok.adda',
                                      iconColor: const Color(0xFF1877F2),
                                    ),
                                    const SizedBox(width: 20.0),
                                    _buildSocialIcon(
                                      context,
                                      'assets/images/youtube.svg',
                                      'https://www.youtube.com/@boiaro',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation5']!),

                          // 8. Logout Button (Only visible if logged in)
                          if (FFAppState().isLogin == true)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: InkWell(
                                onTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment: AlignmentDirectional(0.0, 0.0)
                                            .resolve(Directionality.of(dialogContext)),
                                        child: GestureDetector(
                                          onTap: () {
                                            FocusScope.of(dialogContext).unfocus();
                                            FocusManager.instance.primaryFocus?.unfocus();
                                          },
                                          child: LogOutDialogWidget(
                                            onTapLogout: () async {
                                              if (FFAppState().tokenFcm.isNotEmpty) {
                                                await EbookGroup.unregisterNotificationTokenApiCall.call(
                                                  tokenFcm: FFAppState().tokenFcm,
                                                  token: FFAppState().token,
                                                );
                                              }
                                              _model.signOutApi = await EbookGroup.signoutApiCall.call(
                                                userId: FFAppState().userId,
                                                deviceId: FFAppState().deviceId,
                                                token: FFAppState().token,
                                              );

                                              if (_model.signOutApi?.statusCode == 401) {
                                                Navigator.pop(dialogContext);
                                                FFAppState().isLogin = false;
                                                FFAppState().token = '';
                                                FFAppState().refreshToken = '';
                                                FFAppState().favChange = false;
                                                FFAppState().bookId = '';
                                                FFAppState().homePageLiveReadBook = '';
                                                FFAppState().homePageCurrentPdfIndex = 1;
                                                FFAppState().searchList = [];
                                                FFAppState().userId = '';
                                                FFAppState().userDetail = null;
                                                FFAppState().update(() {});
                                                await RevenueCatService.logOut();
                                                FFAppState().clearGetFavouriteBookCacheCache();
                                                await actions.showCustomToastBottom(
                                                  EbookGroup.signoutApiCall.message(
                                                        (_model.signOutApi?.jsonBody ?? ''),
                                                      ) ??
                                                      'Session expired. Please login again.',
                                                );
                                                if (context.mounted) {
                                                  context.pushNamed(SignInPageWidget.routeName);
                                                }
                                                return;
                                              }

                                              if (EbookGroup.signoutApiCall.success(
                                                    (_model.signOutApi?.jsonBody ?? ''),
                                                  ) ==
                                                  2) {
                                                await actions.showCustomToastBottom(
                                                  EbookGroup.signoutApiCall.message(
                                                    (_model.signOutApi?.jsonBody ?? ''),
                                                  )!,
                                                );
                                              } else {
                                                if (EbookGroup.signoutApiCall.success(
                                                      (_model.signOutApi?.jsonBody ?? ''),
                                                    ) ==
                                                    1) {
                                                  Navigator.pop(dialogContext);
                                                  FFAppState().isLogin = false;
                                                  FFAppState().token = '';
                                                  FFAppState().refreshToken = '';
                                                  FFAppState().favChange = false;
                                                  FFAppState().bookId = '';
                                                  FFAppState().homePageLiveReadBook = '';
                                                  FFAppState().homePageCurrentPdfIndex = 1;
                                                  FFAppState().searchList = [];
                                                  FFAppState().userId = '';
                                                  FFAppState().userDetail = null;
                                                  FFAppState().update(() {});
                                                  await RevenueCatService.logOut();
                                                  FFAppState().clearGetFavouriteBookCacheCache();
                                                  await actions.showCustomToastBottom(
                                                    EbookGroup.signoutApiCall.message(
                                                      (_model.signOutApi?.jsonBody ?? ''),
                                                    )!,
                                                  );
                                                } else {
                                                  await actions.showCustomToastBottom(
                                                    EbookGroup.signoutApiCall.message(
                                                      (_model.signOutApi?.jsonBody ?? ''),
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
                                  safeSetState(() {});
                                },
                                borderRadius: BorderRadius.circular(16.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context).error.withOpacity(0.3),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: FlutterFlowTheme.of(context).error,
                                        size: 20.0,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        FFLocalizations.of(context).getText('log_out'),
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                              color: FlutterFlowTheme.of(context).error,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation6']!),
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

  Widget _buildQuickGridItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8.0,
              color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.03),
              offset: const Offset(0.0, 2.0),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: FlutterFlowTheme.of(context).primary,
                size: 18.0,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'SF Pro Display',
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 10.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, {required List<Widget> children, String? title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.0,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12.0,
                  color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.03),
                  offset: const Offset(0.0, 4.0),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(
    BuildContext context, {
    required String label,
    required Widget icon,
    required VoidCallback onTap,
    Widget? trailing,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).lightGrey,
                    shape: BoxShape.circle,
                  ),
                  alignment: const Alignment(0.0, 0.0),
                  child: icon,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    label,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 20.0,
                    ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1.0,
              thickness: 1.0,
              indent: 68.0,
              endIndent: 16.0,
              color: FlutterFlowTheme.of(context).alternate.withOpacity(0.4),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(
    BuildContext context,
    dynamic icon,
    String url, {
    bool isImage = false,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: () async {
        await launchURL(url);
      },
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        width: 48.0,
        height: 48.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8.0,
              color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.04),
              offset: const Offset(0.0, 2.0),
            )
          ],
        ),
        alignment: Alignment.center,
        child: icon is IconData
            ? Icon(
                icon,
                color: iconColor ?? FlutterFlowTheme.of(context).primary,
                size: 24.0,
              )
            : (isImage
                ? Image.asset(
                    icon,
                    width: 24.0,
                    height: 24.0,
                    fit: BoxFit.contain,
                  )
                : SvgPicture.asset(
                    icon,
                    width: 24.0,
                    height: 24.0,
                    fit: BoxFit.contain,
                  )),
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
                          FFLocalizations.of(context).getVariableText(enText: 'Refer & Earn', bnText: 'রেফার করুন ও আয় করুন'),
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
                                        FFLocalizations.of(context).getVariableText(enText: 'Failed to load referral details', bnText: 'রেফারেল তথ্য লোড করতে ব্যর্থ হয়েছে'),
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
                                      FFLocalizations.of(context).getVariableText(enText: 'Invite your friends & earn coins!', bnText: 'বন্ধুদের আমন্ত্রণ দিন এবং কয়েন আয় করুন!'),
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
                                          FFLocalizations.of(context).getVariableText(enText: 'Total Referrals', bnText: 'মোট রেফারেল'),
                                          totalReferrals.toString(),
                                          Icons.people_alt_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildRefStatCard(
                                          context,
                                          FFLocalizations.of(context).getVariableText(enText: 'Coins Earned', bnText: 'অর্জিত কয়েন'),
                                          '$totalEarned ${FFLocalizations.of(context).getVariableText(enText: 'Coins', bnText: 'কয়েন')}',
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
                                          FFLocalizations.of(context).getVariableText(enText: 'YOUR REFERRAL CODE', bnText: 'আপনার রেফারেল কোড'),
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
                                            await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Referral code copied!', bnText: 'রেফারেল কোড কপি হয়েছে!'));
                                          },
                                          icon: const Icon(Icons.copy_rounded, size: 18),
                                          label: Text(FFLocalizations.of(context).getVariableText(enText: 'Copy Code', bnText: 'কোড কপি করুন')),
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
                                    FFLocalizations.of(context).getVariableText(enText: 'How it works', bnText: 'এটি কীভাবে কাজ করে'),
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
                                    FFLocalizations.of(context).getVariableText(enText: 'Share your code with friends', bnText: 'বন্ধুদের সাথে কোড শেয়ার করুন'),
                                    FFLocalizations.of(context).getVariableText(enText: 'Send them your unique referral code.', bnText: 'তাদের আপনার অনন্য রেফারেল কোড পাঠান।'),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(
                                    context,
                                    '2',
                                    FFLocalizations.of(context).getVariableText(enText: 'They sign up & get coins', bnText: 'তারা সাইন আপ করে কয়েন পান'),
                                    FFLocalizations.of(context).getVariableText(enText: 'Your friend receives $referredBonus coins immediately upon signup.', bnText: 'আপনার বন্ধু সাইন আপ করার সাথে সাথে $referredBonus কয়েন পাবেন।'),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(
                                    context,
                                    '3',
                                    FFLocalizations.of(context).getVariableText(enText: 'You earn rewards', bnText: 'আপনি পুরস্কার আয় করুন'),
                                    FFLocalizations.of(context).getVariableText(enText: 'You receive $signupReward coins once they register using your code.', bnText: 'তারা আপনার কোড দিয়ে নিবন্ধন করলে আপনি $signupReward কয়েন পাবেন।'),
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
