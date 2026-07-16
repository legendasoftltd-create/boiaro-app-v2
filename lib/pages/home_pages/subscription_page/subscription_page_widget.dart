import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/dialogs/verifiy_email_dialog/verifiy_email_dialog_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:a_i_ebook_app/services/revenue_cat_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'subscription_page_model.dart';
export 'subscription_page_model.dart';
import 'subscription_payment_screen.dart';

class SubscriptionPageWidget extends StatefulWidget {
  const SubscriptionPageWidget({super.key});

  static String routeName = 'SubscriptionPage';
  static String routePath = '/subscriptionPage';

  @override
  State<SubscriptionPageWidget> createState() => _SubscriptionPageWidgetState();
}

class _SubscriptionPageWidgetState extends State<SubscriptionPageWidget>
    with TickerProviderStateMixin {
  late SubscriptionPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionPageModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.userisverified = await EbookGroup.userVerifyApiCall.call(
        email: getJsonField(
          FFAppState().userDetail,
          r'''$.email''',
        ).toString(),
      );

      if (EbookGroup.userVerifyApiCall.success(
            (_model.userisverified?.jsonBody ?? ''),
          ) ==
          0) {
        await showDialog(
          context: context,
          builder: (dialogContext) {
            return Dialog(
              elevation: 0,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              alignment: AlignmentDirectional(0.0, 0.0)
                  .resolve(Directionality.of(context)),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(dialogContext).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: VerifiyEmailDialogWidget(
                  email: getJsonField(
                    FFAppState().userDetail,
                    r'''$.email''',
                  ).toString(),
                ),
              ),
            );
          },
        );
      } else {
        FFAppState().countryCodeEdit = (String var1) {
          return var1.replaceAll('+', '');
        }(getJsonField(FFAppState().userDetail, r'''$.country_code''')
            .toString());
        FFAppState().phone =
            getJsonField(FFAppState().userDetail, r'''$.phone''').toString();
        FFAppState().update(() {});
      }
    });

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
              curve: Curves.easeInOut,
              delay: 100.0.ms,
              duration: 600.0.ms,
              begin: 0.0,
              end: 1.0),
        ],
      ),
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
              curve: Curves.easeInOut,
              delay: 150.0.ms,
              duration: 600.0.ms,
              begin: 0.0,
              end: 1.0),
        ],
      ),
      'columnOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
              curve: Curves.easeInOut,
              delay: 15.0.ms,
              duration: 600.0.ms,
              begin: 0.0,
              end: 1.0),
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

  // ─── helpers ────────────────────────────────────────────────────────────────

  List<String> _extractFeatures(dynamic planItem) {
    final raw = getJsonField(planItem, r'''$.features''');
    if (raw is! List) return [];
    return raw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }

  Widget _bdtPrice(BuildContext context, String price, String durationDays) {
    final isFree = price == '0';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (!isFree)
          Text(
            '৳',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'SF Pro Display',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
        const SizedBox(width: 2),
        Text(
          isFree ? 'বিনামূল্যে' : price,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                fontFamily: 'SF Pro Display',
                fontSize: 22.0,
                fontWeight: FontWeight.w800,
                color: FlutterFlowTheme.of(context).primaryText,
              ),
        ),
        if (!isFree) ...[
          const SizedBox(width: 4),
          Text(
            '/ $durationDays দিন',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 13.0,
                ),
          ),
        ],
      ],
    );
  }

  Widget _featureRow(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 12,
              color: FlutterFlowTheme.of(context).primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'SF Pro Display',
                    fontSize: 13.0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    lineHeight: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sslcommerzBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDDE2E9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0B7B3E).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF0B7B3E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SSLCommerz দ্বারা সুরক্ষিত পেমেন্ট',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Credit Card, Debit Card ও Mobile Banking সহ সব ধরনের পেমেন্ট গ্রহণযোগ্য',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 11.0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        lineHeight: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Builder(
      builder: (context) => GestureDetector(
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
                    title: 'সাবস্ক্রিপশন',
                    backIcon: false,
                    addIcon: false,
                    onTapAdd: () async {},
                  ),
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    if (FFAppState().connected != true) {
                      return Center(
                        child: Lottie.asset(
                          'assets/jsons/No_Wifi.json',
                          width: 150.0,
                          height: 150.0,
                          fit: BoxFit.contain,
                          animate: true,
                        ),
                      );
                    }

                    return FutureBuilder<ApiCallResponse>(
                      future: EbookGroup.usersubscriptionvalidityApiCall.call(
                        userId: FFAppState().userId,
                        token: FFAppState().token,
                      ),
                      builder: (context, validitySnap) {
                        if (!validitySnap.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  FlutterFlowTheme.of(context).primary),
                            ),
                          );
                        }
                        final validityResp = validitySnap.data!;
                        final hasActiveSub =
                            EbookGroup.usersubscriptionvalidityApiCall.success(
                                      validityResp.jsonBody,
                                    ) ==
                                    1 &&
                                (EbookGroup.usersubscriptionvalidityApiCall
                                            .daysLeft(validityResp.jsonBody) ??
                                        0) >
                                    0;

                        return FutureBuilder<ApiCallResponse>(
                          future: (_model.apiRequestCompleter ??=
                                  Completer<ApiCallResponse>()
                                    ..complete(EbookGroup
                                        .getsubscriptionplanApiCall
                                        .call()))
                              .future,
                          builder: (context, plansSnap) {
                            if (!plansSnap.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      FlutterFlowTheme.of(context).primary),
                                ),
                              );
                            }
                            final plansResp = plansSnap.data!;
                            final planList = EbookGroup
                                    .getsubscriptionplanApiCall
                                    .subscriptionDetailsList(
                                      plansResp.jsonBody,
                                    )
                                    ?.toList() ??
                                [];

                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: RefreshIndicator(
                                    key: const Key(
                                        'RefreshIndicator_subscription'),
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    onRefresh: () async {
                                      safeSetState(() =>
                                          _model.apiRequestCompleter = null);
                                      await _model
                                          .waitForApiRequestCompleted();
                                    },
                                    child: ListView(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 16, 0, 24),
                                      children: [
                                        // ── Header ──────────────────────────
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 0, 16, 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                hasActiveSub
                                                    ? 'আপনার সক্রিয় প্ল্যান'
                                                    : 'আপনার প্ল্যান বেছে নিন',
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleMedium
                                                    .override(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      fontSize: 22.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                hasActiveSub
                                                    ? 'আপনার বর্তমান সাবস্ক্রিপশনের বিবরণ নিচে দেওয়া হয়েছে।'
                                                    : 'সঠিক প্ল্যান বেছে নিয়ে সমস্ত ইবুক ও অডিওবুকে পূর্ণ অ্যাক্সেস পান।',
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      fontSize: 14.0,
                                                      lineHeight: 1.6,
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryText,
                                                    ),
                                              ),
                                            ],
                                          ).animateOnPageLoad(animationsMap[
                                              'textOnPageLoadAnimation']!),
                                        ),

                                        // ── Active plan card ────────────────
                                        if (hasActiveSub)
                                          _buildActivePlanCard(
                                              context, validityResp),

                                        // ── Plan selection (no active sub) ──
                                        if (!hasActiveSub) ...[
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 12),
                                            child: Text(
                                              'উপলব্ধ প্ল্যানসমূহ',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    fontFamily: 'SF Pro Display',
                                                    fontSize: 17.0,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          ...List.generate(planList.length,
                                              (i) {
                                            return _buildPlanCard(
                                                context, planList[i], i);
                                          }).addToEnd(
                                              const SizedBox(height: 4)),
                                          if (Theme.of(context).platform != TargetPlatform.iOS && Theme.of(context).platform != TargetPlatform.android)
                                            _sslcommerzBadge(context),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Continue button ──────────────────────────
                                if (!hasActiveSub)
                                  _buildContinueButton(
                                      context, plansResp),
                              ],
                            ).animateOnPageLoad(animationsMap[
                                'columnOnPageLoadAnimation']!);
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Active plan card ───────────────────────────────────────────────────────

  Widget _buildActivePlanCard(BuildContext context, ApiCallResponse resp) {
    final name =
        EbookGroup.usersubscriptionvalidityApiCall.name(resp.jsonBody) ?? '';
    final price =
        EbookGroup.usersubscriptionvalidityApiCall.price(resp.jsonBody);
    final description =
        EbookGroup.usersubscriptionvalidityApiCall.description(resp.jsonBody) ??
            '';
    final features =
        EbookGroup.usersubscriptionvalidityApiCall.features(resp.jsonBody) ??
            const <String>[];
    final daysLeft =
        EbookGroup.usersubscriptionvalidityApiCall.daysLeft(resp.jsonBody) ??
            0;
    final amountPaid =
        EbookGroup.usersubscriptionvalidityApiCall.amountPaid(resp.jsonBody) ??
            '';
    final couponCode =
        EbookGroup.usersubscriptionvalidityApiCall.couponCode(resp.jsonBody) ??
            '';
    final discountAmount =
        EbookGroup.usersubscriptionvalidityApiCall.discountAmount(resp.jsonBody) ??
            '';
    final expiryDate = valueOrDefault<String>(
      EbookGroup.usersubscriptionvalidityApiCall
          .expirationDate(resp.jsonBody),
      '',
    );
    final isFree = price == null || price == 'Free' || price == '0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FlutterFlowTheme.of(context).primary,
              FlutterFlowTheme.of(context).primary.withValues(alpha: 0.80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name প্ল্যান',
                      style: FlutterFlowTheme.of(context)
                          .titleMedium
                          .override(
                            fontFamily: 'SF Pro Display',
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'সক্রিয়',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isFree)
                    Text(
                      '৳',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(width: 2),
                  Text(
                    isFree
                        ? 'বিনামূল্যে'
                        : price.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      expiryDate.isNotEmpty
                          ? 'মেয়াদ শেষ: $expiryDate'
                          : '',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$daysLeft দিন বাকি',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (amountPaid.isNotEmpty || couponCode.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (amountPaid.isNotEmpty)
                      _activeMetaChip('Paid: ৳$amountPaid'),
                    if (couponCode.isNotEmpty)
                      _activeMetaChip('Coupon: $couponCode'),
                    if (discountAmount.isNotEmpty &&
                        discountAmount != '0' &&
                        discountAmount != '0.0')
                      _activeMetaChip('Discount: ৳$discountAmount'),
                  ],
                ),
              ],
              if (features.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...features.take(4).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _handleCancelSubscription(context),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
                  label: Text(
                    FFLocalizations.of(context).getVariableText(
                      enText: 'Cancel Subscription',
                      bnText: 'সাবস্ক্রিপশন বাতিল করুন',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
    );
  }

  Widget _activeMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Plan selection card ────────────────────────────────────────────────────

  Widget _buildPlanCard(
      BuildContext context, dynamic planItem, int index) {
    final isSelected = _model.subsIndex == index;
    final planName =
        getJsonField(planItem, r'''$.name''')?.toString() ?? '';
    final description =
        getJsonField(planItem, r'''$.description''')?.toString() ?? '';
    final planPrice =
        getJsonField(planItem, r'''$.price''')?.toString() ?? '0';
    final durationDays =
        getJsonField(planItem, r'''$.duration_days''')?.toString() ?? '30';
    final isFeatured =
        getJsonField(planItem, r'''$.is_featured''') == true;
    final features = _extractFeatures(planItem);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () {
          FFAppState().subscriptionId =
              getJsonField(planItem, r'''$._id''')?.toString() ??
                  getJsonField(planItem, r'''$.id''')?.toString() ??
                  '';
          FFAppState().update(() {});
          _model.subDetail = planItem;
          _model.subsIndex = index;
          safeSetState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.06)
                : FlutterFlowTheme.of(context).secondaryBackground,
            border: Border.all(
              color: isSelected
                  ? FlutterFlowTheme.of(context).primary
                  : const Color(0xFFDDE2E9),
              width: isSelected ? 2.0 : 1.2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge + radio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                planName,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (isFeatured) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade600,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '⭐ জনপ্রিয়',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              description,
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 12.0,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).secondaryText,
                      size: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Price row
                _bdtPrice(context, planPrice, durationDays),

                // Features
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: FlutterFlowTheme.of(context)
                        .primaryText
                        .withValues(alpha: 0.06),
                  ),
                  ...features.map((f) => _featureRow(context, f)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Continue button ────────────────────────────────────────────────────────

  Widget _buildContinueButton(BuildContext context, ApiCallResponse plansResp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: FFButtonWidget(
        onPressed: () async {
          if (_model.subsIndex == null) {
            await actions.showCustomToastBottom('অনুগ্রহ করে একটি প্ল্যান বেছে নিন');
            return;
          }
          final price =
              getJsonField(_model.subDetail, r'''$.price''')?.toString() ?? '1';

          if (price == '0') {
            // Free plan
            _model.subscriptionFree =
                await EbookGroup.usersubscriptionApiCall.call(
              userId: FFAppState().userId,
              subscriptionplanId: FFAppState().subscriptionId,
              paymentmode: 'free',
              transactionId: 'Free',
              paymentstatus: 'success',
              paymentdate:
                  dateTimeFormat("dd-MM-yyyy", getCurrentTimestamp),
              price: price,
              token: FFAppState().token,
            );
            await actions.showCustomToastBottom(
              EbookGroup.usersubscriptionApiCall.message(
                (_model.subscriptionFree?.jsonBody ?? ''),
              )!,
            );
            context.safePop();
          } else {
            final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
            final isAndroid = Theme.of(context).platform == TargetPlatform.android;
            String? paymentChoice;

            if (isIOS) {
              paymentChoice = 'google_play'; // iOS uses IAP path
            } else if (isAndroid) {
              // Show bottom sheet to choose between Google Play and Local Payment
              paymentChoice = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) {
                  final sheetTheme = FlutterFlowTheme.of(context);
                  return Padding(
                    padding: MediaQuery.viewInsetsOf(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      decoration: BoxDecoration(
                        color: sheetTheme.secondaryBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24.0),
                          topRight: Radius.circular(24.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, -4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: sheetTheme.alternate,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'পেমেন্ট পদ্ধতি নির্বাচন করুন',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: sheetTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'সাবক্রিপশন সম্পন্ন করতে নিচের যেকোনো একটি পদ্ধতি বেছে নিন',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 13,
                              color: sheetTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Option 1: Google Play IAP (Recommended)
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop('google_play'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: sheetTheme.primaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: sheetTheme.primary.withOpacity(0.5), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: sheetTheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.payment_rounded, color: sheetTheme.primary, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Google Play Billing',
                                              style: TextStyle(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: sheetTheme.primaryText,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: sheetTheme.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Recommended',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'গুগল পে বা কার্ড ব্যবহার করে পেমেন্ট করুন',
                                          style: TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 12,
                                            color: sheetTheme.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Option 2: Local Payment (SSLCommerz)
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop('local_payment'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: sheetTheme.primaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: sheetTheme.primaryText.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B7B3E).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0B7B3E), size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Local Payment (বিকাশ, রকেট, কার্ড)',
                                          style: TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: sheetTheme.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'যদি কার্ড বা গুগল প্লে ব্যালেন্স না থাকে',
                                          style: TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 12,
                                            color: sheetTheme.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop('cancel'),
                            child: Text(
                              'বাতিল করুন',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                color: sheetTheme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              paymentChoice = 'local_payment';
            }

            if (paymentChoice == 'google_play') {
              // Purchases through RevenueCat IAP (iOS or Android)
              final planId =
                  getJsonField(_model.subDetail, r'''$._id''')?.toString() ??
                      getJsonField(_model.subDetail, r'''$.id''')?.toString() ??
                      '';
              final planName =
                  getJsonField(_model.subDetail, r'''$.name''')?.toString() ?? '';
              final durationDays =
                  getJsonField(_model.subDetail, r'''$.duration_days''')?.toString() ?? '30';

              // Determine product identifier
              String productIdentifier = 'com.boiaro.app.monthly';
              if (durationDays == '365' || planName.toLowerCase().contains('year')) {
                productIdentifier = 'com.boiaro.app.yearly';
              } else if (durationDays == '180' || planName.toLowerCase().contains('half')) {
                productIdentifier = 'com.boiaro.app.halfyearly';
              }

              // Sync user login state to RevenueCat
              if (FFAppState().userId.isNotEmpty) {
                await RevenueCatService.logIn(FFAppState().userId);
              }

              // Show a progress indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator()),
              );

              final purchaseResult = await RevenueCatService.purchasePlan(productIdentifier);
              
              // Pop the loading indicator
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }

              if (purchaseResult['success'] == true) {
                final txnId = purchaseResult['transactionId'] ?? 'rc_${DateTime.now().millisecondsSinceEpoch}';
                
                // Call backend API to record subscription
                _model.subscriptionFree = await EbookGroup.usersubscriptionApiCall.call(
                  userId: FFAppState().userId,
                  subscriptionplanId: planId,
                  paymentmode: 'appstore',
                  transactionId: txnId,
                  paymentstatus: 'success',
                  paymentdate: dateTimeFormat("dd-MM-yyyy", getCurrentTimestamp),
                  price: price,
                  token: FFAppState().token,
                );

                await actions.showCustomToastBottom('সাবস্ক্রিপশন সফলভাবে সক্রিয় হয়েছে!');
                context.safePop();
              } else {
                final errMsg = purchaseResult['errorMessage'] ?? 'পেমেন্ট ব্যর্থ হয়েছে।';
                await actions.showCustomToastBottom(errMsg);
              }
            } else if (paymentChoice == 'local_payment') {
              // Paid plan → SSLCommerz via PaymentMethodPage
              FFAppState().subscriptionId =
                  getJsonField(_model.subDetail, r'''$._id''')?.toString() ??
                      getJsonField(_model.subDetail, r'''$.id''')?.toString() ??
                      '';
              safeSetState(() {});
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionPaymentScreen(
                    subscriptionJson: _model.subDetail,
                  ),
                ),
              );
            }
          }
          safeSetState(() {});
        },
        text: (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android)
            ? 'সাবস্ক্রাইব করুন'
            : ((getJsonField(_model.subDetail, r'''$.price''')?.toString() ??
                        '1') ==
                    '0'
                ? 'ফ্রি প্ল্যান চালু করুন'
                : 'SSLCommerz দিয়ে পেমেন্ট করুন'),
        icon: const Icon(Icons.lock_outline_rounded, size: 18),
        options: FFButtonOptions(
          width: double.infinity,
          height: 54.0,
          color: FlutterFlowTheme.of(context).primary,
          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'SF Pro Display',
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.w700,
              ),
          elevation: 0,
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Future<void> _handleCancelSubscription(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Cancel Subscription?',
            bnText: 'সাবস্ক্রিপশন বাতিল করবেন?',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          FFLocalizations.of(context).getVariableText(
            enText: 'Are you sure you want to cancel your current subscription? You will still retain access until the end of your billing cycle.',
            bnText: 'আপনি কি নিশ্চিত যে আপনার বর্তমান সাবস্ক্রিপশন বাতিল করতে চান? আপনার বিলিং চক্রের শেষ পর্যন্ত অ্যাক্সেস বজায় থাকবে।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              FFLocalizations.of(context).getVariableText(
                enText: 'No',
                bnText: 'না',
              ),
              style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
            child: Text(
              FFLocalizations.of(context).getVariableText(
                enText: 'Yes, Cancel',
                bnText: 'হ্যাঁ, বাতিল করুন',
              ),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final res = await EbookGroup.cancelSubscriptionApiCall.call(
        token: FFAppState().token,
      );

      // Pop progress dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (res.succeeded) {
        final msg = EbookGroup.cancelSubscriptionApiCall.message(res.jsonBody) ?? 
            FFLocalizations.of(context).getVariableText(
              enText: 'Subscription cancelled successfully.',
              bnText: 'সাবস্ক্রিপশন সফলভাবে বাতিল করা হয়েছে।',
            );
        await actions.showCustomToastBottom(msg);
        safeSetState(() {});
      } else {
        final err = getJsonField(res.jsonBody, r'''$.error''')?.toString() ?? 
            FFLocalizations.of(context).getVariableText(
              enText: 'Failed to cancel subscription.',
              bnText: 'সাবস্ক্রিপশন বাতিল করতে ব্যর্থ হয়েছে।',
            );
        await actions.showCustomToastBottom(err);
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      await actions.showCustomToastBottom(
        FFLocalizations.of(context).getVariableText(
          enText: 'An error occurred. Please try again.',
          bnText: 'একটি সমস্যা হয়েছে। দয়া করে আবার চেষ্টা করুন।',
        ),
      );
    }
  }
}
