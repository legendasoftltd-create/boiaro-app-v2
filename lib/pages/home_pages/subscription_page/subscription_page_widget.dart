import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/dialogs/verifiy_email_dialog/verifiy_email_dialog_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'subscription_page_model.dart';
export 'subscription_page_model.dart';

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

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.userisverified = await EbookGroup.userVerifyApiCall.call(
        email: getJsonField(
          FFAppState().userDetail,
          r'''$.email''',
        ).toString().toString(),
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
                  ).toString().toString(),
                ),
              ),
            );
          },
        );
      } else {
        FFAppState().countryCodeEdit = (String var1) {
          return var1.replaceAll('+', '');
        }(getJsonField(
          FFAppState().userDetail,
          r'''$.country_code''',
        ).toString().toString());
        FFAppState().phone = getJsonField(
          FFAppState().userDetail,
          r'''$.phone''',
        ).toString().toString();
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
            end: 1.0,
          ),
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
            end: 1.0,
          ),
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
            child: Container(
              decoration: BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  wrapWithModel(
                    model: _model.customCenterAppbarModel,
                    updateCallback: () => safeSetState(() {}),
                    child: CustomCenterAppbarWidget(
                      title: 'Subscription',
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
                            future: EbookGroup.currencyApiCall.call(
                              token: FFAppState().token,
                            ),
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
                              final containerCurrencyApiResponse =
                                  snapshot.data!;

                              return Container(
                                decoration: BoxDecoration(),
                                child: FutureBuilder<ApiCallResponse>(
                                  future: EbookGroup
                                      .usersubscriptionvalidityApiCall
                                      .call(
                                    userId: FFAppState().userId,
                                    token: FFAppState().token,
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
                                    final containerUsersubscriptionvalidityApiResponse =
                                        snapshot.data!;

                                    return Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(),
                                      child: FutureBuilder<ApiCallResponse>(
                                        future: (_model.apiRequestCompleter ??=
                                                Completer<ApiCallResponse>()
                                                  ..complete(EbookGroup
                                                      .getsubscriptionplanApiCall
                                                      .call()))
                                            .future,
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          final columnGetsubscriptionplanApiResponse =
                                              snapshot.data!;

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: RefreshIndicator(
                                                  key: Key(
                                                      'RefreshIndicator_6lwkwot6'),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  onRefresh: () async {
                                                    safeSetState(() => _model
                                                            .apiRequestCompleter =
                                                        null);
                                                    await _model
                                                        .waitForApiRequestCompleted();
                                                  },
                                                  child: ListView(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                      0,
                                                      16.0,
                                                      0,
                                                      0,
                                                    ),
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    16.0,
                                                                    0.0,
                                                                    16.0,
                                                                    24.0),
                                                        child: Text(
                                                          'Full access to all free and premium content in different plan choose your plan on your requirement.',
                                                          textAlign:
                                                              TextAlign.center,
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
                                                        ).animateOnPageLoad(
                                                            animationsMap[
                                                                'textOnPageLoadAnimation']!),
                                                      ),
                                                      if (EbookGroup
                                                              .usersubscriptionvalidityApiCall
                                                              .success(
                                                            containerUsersubscriptionvalidityApiResponse
                                                                .jsonBody,
                                                          ) ==
                                                          1)
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Builder(
                                                            builder: (context) {
                                                              if (EbookGroup
                                                                      .usersubscriptionvalidityApiCall
                                                                      .success(
                                                                    containerUsersubscriptionvalidityApiResponse
                                                                        .jsonBody,
                                                                  ) ==
                                                                  1) {
                                                                return Builder(
                                                                  builder:
                                                                      (context) {
                                                                    if (EbookGroup
                                                                            .usersubscriptionvalidityApiCall
                                                                            .daysLeft(
                                                                          containerUsersubscriptionvalidityApiResponse
                                                                              .jsonBody,
                                                                        )! >
                                                                        0) {
                                                                      return Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            borderRadius:
                                                                                BorderRadius.circular(12.0),
                                                                          ),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.all(16.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        '${EbookGroup.usersubscriptionvalidityApiCall.name(
                                                                                          containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                        )} plan',
                                                                                        textAlign: TextAlign.start,
                                                                                        maxLines: 1,
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              color: FlutterFlowTheme.of(context).tertiary,
                                                                                              fontSize: 18.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.w600,
                                                                                              lineHeight: 1.5,
                                                                                            ),
                                                                                      ),
                                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          if (EbookGroup.usersubscriptionvalidityApiCall.name(
                                                                                                containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                              ) !=
                                                                                              'Free')
                                                                                            custom_widgets.GetCurrencySymbool(
                                                                                              width: 15.0,
                                                                                              height: 20.0,
                                                                                              isSimbool: EbookGroup.currencyApiCall.currency(
                                                                                                containerCurrencyApiResponse.jsonBody,
                                                                                              ),
                                                                                              color: FlutterFlowTheme.of(context).tertiary,
                                                                                              fontSize: 17.0,
                                                                                            ),
                                                                                          Expanded(
                                                                                            child: Padding(
                                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                                                              child: RichText(
                                                                                                textScaler: MediaQuery.of(context).textScaler,
                                                                                                text: TextSpan(
                                                                                                  children: [
                                                                                                    TextSpan(
                                                                                                      text: EbookGroup.usersubscriptionvalidityApiCall.name(
                                                                                                                containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                                              ) ==
                                                                                                              'Free'
                                                                                                          ? EbookGroup.usersubscriptionvalidityApiCall.name(
                                                                                                              containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                                            )!
                                                                                                          : functions.convertToTwoDigitDecimal(EbookGroup.usersubscriptionvalidityApiCall.price(
                                                                                                              containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                                            )!),
                                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                            fontFamily: 'SF Pro Display',
                                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                                            fontSize: 17.0,
                                                                                                            letterSpacing: 0.0,
                                                                                                            fontWeight: FontWeight.normal,
                                                                                                          ),
                                                                                                    ),
                                                                                                    TextSpan(
                                                                                                      text: '  ( ',
                                                                                                      style: TextStyle(
                                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                                        fontWeight: FontWeight.normal,
                                                                                                        fontSize: 17.0,
                                                                                                      ),
                                                                                                    ),
                                                                                                    TextSpan(
                                                                                                      text: valueOrDefault<String>(
                                                                                                        EbookGroup.usersubscriptionvalidityApiCall.duration(
                                                                                                          containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                                        ),
                                                                                                        '1',
                                                                                                      ),
                                                                                                      style: TextStyle(
                                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                                        fontSize: 17.0,
                                                                                                      ),
                                                                                                    ),
                                                                                                    TextSpan(
                                                                                                      text: ' ',
                                                                                                      style: TextStyle(),
                                                                                                    ),
                                                                                                    TextSpan(
                                                                                                      text: valueOrDefault<String>(
                                                                                                        EbookGroup.usersubscriptionvalidityApiCall.durationinterms(
                                                                                                          containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                                        ),
                                                                                                        'days',
                                                                                                      ),
                                                                                                      style: TextStyle(
                                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                                        fontSize: 17.0,
                                                                                                      ),
                                                                                                    ),
                                                                                                    TextSpan(
                                                                                                      text: ' )',
                                                                                                      style: TextStyle(
                                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                                        fontSize: 17.0,
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                        fontFamily: 'SF Pro Display',
                                                                                                        color: FlutterFlowTheme.of(context).tertiary,
                                                                                                        fontSize: 17.0,
                                                                                                        letterSpacing: 0.0,
                                                                                                      ),
                                                                                                ),
                                                                                                textAlign: TextAlign.start,
                                                                                                maxLines: 1,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ].divide(SizedBox(height: 12.0)),
                                                                                  ),
                                                                                ),
                                                                                Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                                                  children: [
                                                                                    Text(
                                                                                      'Current plan',
                                                                                      textAlign: TextAlign.end,
                                                                                      maxLines: 1,
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                            fontSize: 15.0,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.w500,
                                                                                            lineHeight: 1.5,
                                                                                          ),
                                                                                    ),
                                                                                    Container(
                                                                                      decoration: BoxDecoration(
                                                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                        borderRadius: BorderRadius.circular(8.0),
                                                                                      ),
                                                                                      child: Padding(
                                                                                        padding: EdgeInsets.all(8.0),
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            Text(
                                                                                              'Expires on ${functions.expiresFormate(valueOrDefault<String>(
                                                                                                EbookGroup.usersubscriptionvalidityApiCall.expirationDate(
                                                                                                  containerUsersubscriptionvalidityApiResponse.jsonBody,
                                                                                                ),
                                                                                                '12-07-2024',
                                                                                              ))}',
                                                                                              textAlign: TextAlign.center,
                                                                                              maxLines: 1,
                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                    fontFamily: 'SF Pro Display',
                                                                                                    fontSize: 17.0,
                                                                                                    letterSpacing: 0.0,
                                                                                                    lineHeight: 1.0,
                                                                                                  ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ].divide(SizedBox(height: 4.0)),
                                                                                ),
                                                                              ].divide(SizedBox(width: 4.0)),
                                                                            ),
                                                                          ),
                                                                        ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
                                                                      );
                                                                    } else {
                                                                      return Container(
                                                                        width:
                                                                            0.0,
                                                                        height:
                                                                            0.0,
                                                                        decoration:
                                                                            BoxDecoration(),
                                                                      );
                                                                    }
                                                                  },
                                                                );
                                                              } else {
                                                                return Container(
                                                                  decoration:
                                                                      BoxDecoration(),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      if (EbookGroup
                                                              .usersubscriptionvalidityApiCall
                                                              .success(
                                                            containerUsersubscriptionvalidityApiResponse
                                                                .jsonBody,
                                                          ) ==
                                                          0)
                                                        Builder(
                                                          builder: (context) {
                                                            final planList = EbookGroup
                                                                    .getsubscriptionplanApiCall
                                                                    .subscriptionDetailsList(
                                                                      columnGetsubscriptionplanApiResponse
                                                                          .jsonBody,
                                                                    )
                                                                    ?.toList() ??
                                                                [];

                                                            return Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: List.generate(
                                                                      planList
                                                                          .length,
                                                                      (planListIndex) {
                                                                final planListItem =
                                                                    planList[
                                                                        planListIndex];
                                                                return Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          16.0,
                                                                          0.0,
                                                                          16.0,
                                                                          0.0),
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
                                                                      FFAppState()
                                                                              .subscriptionId =
                                                                          getJsonField(
                                                                        planListItem,
                                                                        r'''$._id''',
                                                                      ).toString();
                                                                      FFAppState()
                                                                          .update(
                                                                              () {});
                                                                      _model.subDetail =
                                                                          planListItem;
                                                                      _model.subsIndex =
                                                                          planListIndex;
                                                                      safeSetState(
                                                                          () {});
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            blurRadius:
                                                                                16.0,
                                                                            color:
                                                                                Color(0x14000014),
                                                                            offset:
                                                                                Offset(
                                                                              0.0,
                                                                              4.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        borderRadius:
                                                                            BorderRadius.circular(12.0),
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(16.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    getJsonField(
                                                                                      planListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          fontSize: 18.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                  Row(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    children: [
                                                                                      custom_widgets.GetCurrencySymbool(
                                                                                        width: 15.0,
                                                                                        height: 20.0,
                                                                                        isSimbool: EbookGroup.currencyApiCall.currency(
                                                                                          containerCurrencyApiResponse.jsonBody,
                                                                                        ),
                                                                                        color: FlutterFlowTheme.of(context).primaryText,
                                                                                        fontSize: 17.0,
                                                                                      ),
                                                                                      Padding(
                                                                                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                                                        child: RichText(
                                                                                          textScaler: MediaQuery.of(context).textScaler,
                                                                                          text: TextSpan(
                                                                                            children: [
                                                                                              TextSpan(
                                                                                                text: '',
                                                                                                style: TextStyle(
                                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                                  fontSize: 17.0,
                                                                                                ),
                                                                                              ),
                                                                                              TextSpan(
                                                                                                text: valueOrDefault<String>(
                                                                                                  functions.convertToTwoDigitDecimal(getJsonField(
                                                                                                    planListItem,
                                                                                                    r'''$.price''',
                                                                                                  ).toString()),
                                                                                                  '15',
                                                                                                ),
                                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                      fontFamily: 'SF Pro Display',
                                                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                                                      fontSize: 17.0,
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FontWeight.normal,
                                                                                                    ),
                                                                                              ),
                                                                                              TextSpan(
                                                                                                text: '  ( ',
                                                                                                style: TextStyle(
                                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                                  fontWeight: FontWeight.normal,
                                                                                                  fontSize: 17.0,
                                                                                                ),
                                                                                              ),
                                                                                              TextSpan(
                                                                                                text: getJsonField(
                                                                                                  planListItem,
                                                                                                  r'''$.duration''',
                                                                                                ).toString(),
                                                                                                style: TextStyle(
                                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                                  fontSize: 17.0,
                                                                                                ),
                                                                                              ),
                                                                                              TextSpan(
                                                                                                text: ' ',
                                                                                                style: TextStyle(),
                                                                                              ),
                                                                                              TextSpan(
                                                                                                text: getJsonField(
                                                                                                  planListItem,
                                                                                                  r'''$.duration_in_terms''',
                                                                                                ).toString(),
                                                                                                style: TextStyle(
                                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                                  fontSize: 17.0,
                                                                                                ),
                                                                                              ),
                                                                                              TextSpan(
                                                                                                text: ' )',
                                                                                                style: TextStyle(
                                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                                  fontSize: 17.0,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  fontSize: 17.0,
                                                                                                  letterSpacing: 0.0,
                                                                                                ),
                                                                                          ),
                                                                                          maxLines: 1,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ].divide(SizedBox(height: 12.0)),
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                                                                              child: Builder(
                                                                                builder: (context) {
                                                                                  if (_model.subsIndex == planListIndex) {
                                                                                    return ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(0.0),
                                                                                      child: SvgPicture.asset(
                                                                                        'assets/images/Radiofill_button.svg',
                                                                                        width: 24.0,
                                                                                        height: 24.0,
                                                                                        fit: BoxFit.cover,
                                                                                      ),
                                                                                    );
                                                                                  } else {
                                                                                    return ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(0.0),
                                                                                      child: SvgPicture.asset(
                                                                                        'assets/images/Radio_button.svg',
                                                                                        width: 24.0,
                                                                                        height: 24.0,
                                                                                        fit: BoxFit.cover,
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
                                                                  ),
                                                                );
                                                              })
                                                                  .divide(SizedBox(
                                                                      height:
                                                                          16.0))
                                                                  .addToEnd(SizedBox(
                                                                      height:
                                                                          16.0)),
                                                            ).animateOnPageLoad(
                                                                animationsMap[
                                                                    'columnOnPageLoadAnimation']!);
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (EbookGroup
                                                      .usersubscriptionvalidityApiCall
                                                      .success(
                                                    containerUsersubscriptionvalidityApiResponse
                                                        .jsonBody,
                                                  ) ==
                                                  0)
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(20.0, 12.0,
                                                          20.0, 24.0),
                                                  child: FFButtonWidget(
                                                    onPressed: () async {
                                                      if (_model.subsIndex !=
                                                          null) {
                                                        if ('0' ==
                                                            getJsonField(
                                                              _model.subDetail,
                                                              r'''$.price''',
                                                            ).toString()) {
                                                          _model.subscriptionFree =
                                                              await EbookGroup
                                                                  .usersubscriptionApiCall
                                                                  .call(
                                                            userId: FFAppState()
                                                                .userId,
                                                            subscriptionplanId:
                                                                FFAppState()
                                                                    .subscriptionId,
                                                            paymentmode:
                                                                'stripe',
                                                            transactionId:
                                                                'Free',
                                                            paymentstatus:
                                                                'success',
                                                            paymentdate:
                                                                dateTimeFormat(
                                                                    "dd-MM-yyyy",
                                                                    getCurrentTimestamp),
                                                            price: getJsonField(
                                                              _model.subDetail,
                                                              r'''$.price''',
                                                            ).toString(),
                                                            token: FFAppState()
                                                                .token,
                                                          );

                                                          await actions
                                                              .showCustomToastBottom(
                                                            EbookGroup
                                                                .usersubscriptionApiCall
                                                                .message(
                                                              (_model.subscriptionFree
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            )!,
                                                          );
                                                          context.safePop();
                                                        } else {
                                                          FFAppState()
                                                                  .subscriptionId =
                                                              getJsonField(
                                                            EbookGroup
                                                                .getsubscriptionplanApiCall
                                                                .subscriptionDetailsList(
                                                                  columnGetsubscriptionplanApiResponse
                                                                      .jsonBody,
                                                                )!
                                                                .firstOrNull,
                                                            r'''$._id''',
                                                          ).toString();
                                                          safeSetState(() {});

                                                          safeSetState(() {});
                                                          _model.subsIndex = 0;
                                                          safeSetState(() {});

                                                          context.pushNamed(
                                                            PaymentMethodPageWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'subscriptionJson':
                                                                  serializeParam(
                                                                _model
                                                                    .subDetail,
                                                                ParamType.JSON,
                                                              ),
                                                            }.withoutNulls,
                                                          );
                                                        }
                                                      } else {
                                                        await actions
                                                            .showCustomToastBottom(
                                                          'Please select plan',
                                                        );
                                                      }

                                                      safeSetState(() {});
                                                    },
                                                    text: 'Continue',
                                                    options: FFButtonOptions(
                                                      width: double.infinity,
                                                      height: 56.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  24.0,
                                                                  0.0,
                                                                  24.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                lineHeight: 1.2,
                                                              ),
                                                      elevation: 0.0,
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    );
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
        ),
      ),
    );
  }
}
