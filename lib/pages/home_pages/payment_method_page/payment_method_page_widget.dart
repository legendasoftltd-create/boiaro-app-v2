import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/dialogs/payment_success_dialog/payment_success_dialog_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'payment_method_page_model.dart';
export 'payment_method_page_model.dart';

class PaymentMethodPageWidget extends StatefulWidget {
  const PaymentMethodPageWidget({
    super.key,
    required this.subscriptionJson,
  });

  final dynamic subscriptionJson;

  static String routeName = 'PaymentMethodPage';
  static String routePath = '/paymentMethodPage';

  @override
  State<PaymentMethodPageWidget> createState() =>
      _PaymentMethodPageWidgetState();
}

class _PaymentMethodPageWidgetState extends State<PaymentMethodPageWidget>
    with TickerProviderStateMixin {
  late PaymentMethodPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentMethodPageModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 120.0.ms,
            duration: 400.0.ms,
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
            delay: 120.0.ms,
            duration: 400.0.ms,
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
            delay: 120.0.ms,
            duration: 400.0.ms,
            begin: Offset(100.0, 0.0),
            end: Offset(0.0, 0.0),
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
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: 'Payment method',
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
                        future: EbookGroup.currencyApiCall.call(),
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
                          final containerCurrencyApiResponse = snapshot.data!;

                          return Container(
                            decoration: BoxDecoration(),
                            child: FutureBuilder<ApiCallResponse>(
                              future: EbookGroup.paymentGatewayApiCall.call(
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
                                          FlutterFlowTheme.of(context).primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final containerPaymentGatewayApiResponse =
                                    snapshot.data!;

                                return Container(
                                  decoration: BoxDecoration(),
                                  child: Builder(
                                    builder: (context) {
                                      if (EbookGroup.paymentGatewayApiCall
                                              .success(
                                            containerPaymentGatewayApiResponse
                                                .jsonBody,
                                          ) ==
                                          2) {
                                        return Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            child: Text(
                                              valueOrDefault<String>(
                                                EbookGroup.paymentGatewayApiCall
                                                    .message(
                                                  containerPaymentGatewayApiResponse
                                                      .jsonBody,
                                                ),
                                                'Message',
                                              ),
                                              textAlign: TextAlign.center,
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
                                        );
                                      } else {
                                        return Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 0.0, 16.0, 0.0),
                                                child: ListView(
                                                  padding: EdgeInsets.fromLTRB(
                                                    0,
                                                    16.0,
                                                    0,
                                                    16.0,
                                                  ),
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  19.0),
                                                      child: Text(
                                                        'Payment method',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 18.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                    ),
                                                    if (EbookGroup
                                                            .paymentGatewayApiCall
                                                            .stripeEnable(
                                                          containerPaymentGatewayApiResponse
                                                              .jsonBody,
                                                        ) ==
                                                        1)
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    0.0,
                                                                    16.0),
                                                        child: InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            _model.selectpayment =
                                                                0;
                                                            safeSetState(() {});
                                                            _model.planmode =
                                                                'stripe';
                                                            safeSetState(() {});
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
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
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            0.0),
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/stripe_ic.png',
                                                                      width:
                                                                          34.0,
                                                                      height:
                                                                          34.0,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          16.0,
                                                                          0.0,
                                                                          16.0,
                                                                          0.0),
                                                                      child:
                                                                          Text(
                                                                        'Stripe',
                                                                        maxLines:
                                                                            1,
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              fontSize: 17.0,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.w600,
                                                                              lineHeight: 1.5,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Builder(
                                                                    builder:
                                                                        (context) {
                                                                      if (_model
                                                                              .selectpayment ==
                                                                          0) {
                                                                        return ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(0.0),
                                                                          child:
                                                                              SvgPicture.asset(
                                                                            'assets/images/Radiofill_button.svg',
                                                                            width:
                                                                                24.0,
                                                                            height:
                                                                                24.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        return ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(0.0),
                                                                          child:
                                                                              SvgPicture.asset(
                                                                            'assets/images/Radio_button.svg',
                                                                            width:
                                                                                24.0,
                                                                            height:
                                                                                24.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ).animateOnPageLoad(
                                                            animationsMap[
                                                                'containerOnPageLoadAnimation1']!),
                                                      ),
                                                    if (EbookGroup
                                                            .paymentGatewayApiCall
                                                            .razorpayEnable(
                                                          containerPaymentGatewayApiResponse
                                                              .jsonBody,
                                                        ) ==
                                                        1)
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    0.0,
                                                                    16.0),
                                                        child: InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            _model.selectpayment =
                                                                1;
                                                            safeSetState(() {});
                                                            _model.planmode =
                                                                'razorpay';
                                                            safeSetState(() {});
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
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
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            0.0),
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/razor_pay.png',
                                                                      width:
                                                                          34.0,
                                                                      height:
                                                                          34.0,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          16.0,
                                                                          0.0,
                                                                          16.0,
                                                                          0.0),
                                                                      child:
                                                                          Text(
                                                                        'Razorpay',
                                                                        maxLines:
                                                                            1,
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              fontSize: 17.0,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.w600,
                                                                              lineHeight: 1.5,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Builder(
                                                                    builder:
                                                                        (context) {
                                                                      if (_model
                                                                              .selectpayment ==
                                                                          1) {
                                                                        return ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(0.0),
                                                                          child:
                                                                              SvgPicture.asset(
                                                                            'assets/images/Radiofill_button.svg',
                                                                            width:
                                                                                24.0,
                                                                            height:
                                                                                24.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        return ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(0.0),
                                                                          child:
                                                                              SvgPicture.asset(
                                                                            'assets/images/Radio_button.svg',
                                                                            width:
                                                                                24.0,
                                                                            height:
                                                                                24.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ).animateOnPageLoad(
                                                            animationsMap[
                                                                'containerOnPageLoadAnimation2']!),
                                                      ),
                                                    if (EbookGroup
                                                            .paymentGatewayApiCall
                                                            .paypalEnable(
                                                          containerPaymentGatewayApiResponse
                                                              .jsonBody,
                                                        ) ==
                                                        1)
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
                                                          _model.selectpayment =
                                                              2;
                                                          safeSetState(() {});
                                                          _model.planmode =
                                                              'paypal';
                                                          safeSetState(() {});
                                                        },
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                blurRadius:
                                                                    16.0,
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
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    16.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              0.0),
                                                                  child: Image
                                                                      .asset(
                                                                    'assets/images/paypal.png',
                                                                    width: 34.0,
                                                                    height:
                                                                        34.0,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                    child: Text(
                                                                      'Paypal',
                                                                      maxLines:
                                                                          1,
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
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            lineHeight:
                                                                                1.5,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Builder(
                                                                  builder:
                                                                      (context) {
                                                                    if (_model
                                                                            .selectpayment ==
                                                                        2) {
                                                                      return ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0.0),
                                                                        child: SvgPicture
                                                                            .asset(
                                                                          'assets/images/Radiofill_button.svg',
                                                                          width:
                                                                              24.0,
                                                                          height:
                                                                              24.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      return ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0.0),
                                                                        child: SvgPicture
                                                                            .asset(
                                                                          'assets/images/Radio_button.svg',
                                                                          width:
                                                                              24.0,
                                                                          height:
                                                                              24.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ).animateOnPageLoad(
                                                          animationsMap[
                                                              'containerOnPageLoadAnimation3']!),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Builder(
                                              builder: (context) => Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 12.0, 16.0, 20.0),
                                                child: FFButtonWidget(
                                                  onPressed: () async {
                                                    _model.getuserR =
                                                        await EbookGroup
                                                            .getuserApiCall
                                                            .call(
                                                      userId:
                                                          FFAppState().userId,
                                                      token: FFAppState().token,
                                                    );

                                                    if (_model.selectpayment ==
                                                        0) {
                                                      await actions.initStripe(
                                                        EbookGroup
                                                            .paymentGatewayApiCall
                                                            .stripepublishablekey(
                                                          containerPaymentGatewayApiResponse
                                                              .jsonBody,
                                                        )!,
                                                      );
                                                      await actions
                                                          .stripeCustom(
                                                        context,
                                                        getJsonField(
                                                          widget
                                                              .subscriptionJson,
                                                          r'''$.price''',
                                                        ).toString(),
                                                        EbookGroup
                                                            .currencyApiCall
                                                            .currency(
                                                          containerCurrencyApiResponse
                                                              .jsonBody,
                                                        )!,
                                                        () async {
                                                          _model.subscriptionR =
                                                              await EbookGroup
                                                                  .usersubscriptionApiCall
                                                                  .call(
                                                            userId: FFAppState()
                                                                .userId,
                                                            subscriptionplanId:
                                                                getJsonField(
                                                              widget
                                                                  .subscriptionJson,
                                                              r'''$._id''',
                                                            ).toString(),
                                                            paymentmode:
                                                                'stripe',
                                                            transactionId:
                                                                FFAppState()
                                                                    .paypalTransationId,
                                                            paymentstatus:
                                                                'success',
                                                            paymentdate:
                                                                dateTimeFormat(
                                                                    "dd-MM-yyyy",
                                                                    getCurrentTimestamp),
                                                            price: getJsonField(
                                                              widget
                                                                  .subscriptionJson,
                                                              r'''$.price''',
                                                            ).toString(),
                                                            token: FFAppState()
                                                                .token,
                                                          );

                                                          if (EbookGroup
                                                                  .usersubscriptionApiCall
                                                                  .success(
                                                                (_model.subscriptionR
                                                                        ?.jsonBody ??
                                                                    ''),
                                                              ) ==
                                                              1) {
                                                            await showDialog(
                                                              context: context,
                                                              builder:
                                                                  (dialogContext) {
                                                                return Dialog(
                                                                  elevation: 0,
                                                                  insetPadding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  alignment: AlignmentDirectional(
                                                                          0.0,
                                                                          0.0)
                                                                      .resolve(
                                                                          Directionality.of(
                                                                              context)),
                                                                  child:
                                                                      GestureDetector(
                                                                    onTap: () {
                                                                      FocusScope.of(
                                                                              dialogContext)
                                                                          .unfocus();
                                                                      FocusManager
                                                                          .instance
                                                                          .primaryFocus
                                                                          ?.unfocus();
                                                                    },
                                                                    child:
                                                                        PaymentSuccessDialogWidget(
                                                                      onTapHome:
                                                                          () async {
                                                                        Navigator.pop(
                                                                            context);

                                                                        context.goNamed(
                                                                            HomePageWidget.routeName);
                                                                      },
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          } else {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  EbookGroup
                                                                      .usersubscriptionApiCall
                                                                      .message(
                                                                    (_model.subscriptionR
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
                                                                        4000),
                                                                backgroundColor:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondary,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        () async {
                                                          context.goNamed(
                                                              HomePageWidget
                                                                  .routeName);
                                                        },
                                                        EbookGroup
                                                            .paymentGatewayApiCall
                                                            .stripesecretkey(
                                                          containerPaymentGatewayApiResponse
                                                              .jsonBody,
                                                        )!,
                                                      );
                                                    } else {
                                                      if (_model
                                                              .selectpayment ==
                                                          1) {
                                                        await actions
                                                            .razorpayCustom(
                                                          context,
                                                          EbookGroup
                                                              .paymentGatewayApiCall
                                                              .razorpaykeysecret(
                                                            containerPaymentGatewayApiResponse
                                                                .jsonBody,
                                                          )!,
                                                          getJsonField(
                                                            widget
                                                                .subscriptionJson,
                                                            r'''$.price''',
                                                          ).toString(),
                                                          '${EbookGroup.getuserApiCall.firstname(
                                                            (_model.getuserR
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )} ${EbookGroup.getuserApiCall.lastname(
                                                            (_model.getuserR
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )}',
                                                          'For buy premium plan',
                                                          EbookGroup
                                                              .getuserApiCall
                                                              .phone(
                                                            (_model.getuserR
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )!,
                                                          EbookGroup
                                                              .getuserApiCall
                                                              .email(
                                                            (_model.getuserR
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )!,
                                                          () async {
                                                            _model.subscriptionrazorR =
                                                                await EbookGroup
                                                                    .usersubscriptionApiCall
                                                                    .call(
                                                              userId:
                                                                  FFAppState()
                                                                      .userId,
                                                              subscriptionplanId:
                                                                  getJsonField(
                                                                widget
                                                                    .subscriptionJson,
                                                                r'''$._id''',
                                                              ).toString(),
                                                              paymentmode:
                                                                  'razorpay',
                                                              transactionId:
                                                                  FFAppState()
                                                                      .paypalTransationId,
                                                              paymentstatus:
                                                                  'success',
                                                              paymentdate:
                                                                  dateTimeFormat(
                                                                      "dd-MM-yyyy",
                                                                      getCurrentTimestamp),
                                                              price:
                                                                  getJsonField(
                                                                widget
                                                                    .subscriptionJson,
                                                                r'''$.price''',
                                                              ).toString(),
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                            );

                                                            if (EbookGroup
                                                                    .usersubscriptionApiCall
                                                                    .success(
                                                                  (_model.subscriptionrazorR
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                ) ==
                                                                1) {
                                                              await showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (dialogContext) {
                                                                  return Dialog(
                                                                    elevation:
                                                                        0,
                                                                    insetPadding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    alignment: AlignmentDirectional(
                                                                            0.0,
                                                                            0.0)
                                                                        .resolve(
                                                                            Directionality.of(context)),
                                                                    child:
                                                                        GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        FocusScope.of(dialogContext)
                                                                            .unfocus();
                                                                        FocusManager
                                                                            .instance
                                                                            .primaryFocus
                                                                            ?.unfocus();
                                                                      },
                                                                      child:
                                                                          PaymentSuccessDialogWidget(
                                                                        onTapHome:
                                                                            () async {
                                                                          Navigator.pop(
                                                                              context);

                                                                          context
                                                                              .goNamed(HomePageWidget.routeName);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    EbookGroup
                                                                        .usersubscriptionApiCall
                                                                        .message(
                                                                      (_model.subscriptionrazorR
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
                                                                          4000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          () async {
                                                            context.goNamed(
                                                                HomePageWidget
                                                                    .routeName);
                                                          },
                                                          EbookGroup
                                                              .currencyApiCall
                                                              .currency(
                                                            containerCurrencyApiResponse
                                                                .jsonBody,
                                                          )!,
                                                        );
                                                      } else {
                                                        await actions
                                                            .paypalCustom(
                                                          context,
                                                          EbookGroup
                                                              .paymentGatewayApiCall
                                                              .paypalpublickey(
                                                            containerPaymentGatewayApiResponse
                                                                .jsonBody,
                                                          )!,
                                                          EbookGroup
                                                              .paymentGatewayApiCall
                                                              .paypalprivatekey(
                                                            containerPaymentGatewayApiResponse
                                                                .jsonBody,
                                                          )!,
                                                          getJsonField(
                                                            widget
                                                                .subscriptionJson,
                                                            r'''$.price''',
                                                          ).toString(),
                                                          EbookGroup
                                                              .currencyApiCall
                                                              .currency(
                                                            containerCurrencyApiResponse
                                                                .jsonBody,
                                                          )!,
                                                          () async {
                                                            if (FFAppState()
                                                                    .paymentSuccessCheck ==
                                                                true) {
                                                              _model.subscriptionpayR =
                                                                  await EbookGroup
                                                                      .usersubscriptionApiCall
                                                                      .call(
                                                                userId:
                                                                    FFAppState()
                                                                        .userId,
                                                                subscriptionplanId:
                                                                    getJsonField(
                                                                  widget
                                                                      .subscriptionJson,
                                                                  r'''$._id''',
                                                                ).toString(),
                                                                paymentmode:
                                                                    'paypal',
                                                                transactionId:
                                                                    FFAppState()
                                                                        .paypalTransationId,
                                                                paymentstatus:
                                                                    'success',
                                                                paymentdate:
                                                                    dateTimeFormat(
                                                                        "dd-MM-yyyy",
                                                                        getCurrentTimestamp),
                                                                price:
                                                                    getJsonField(
                                                                  widget
                                                                      .subscriptionJson,
                                                                  r'''$.price''',
                                                                ).toString(),
                                                                token:
                                                                    FFAppState()
                                                                        .token,
                                                              );

                                                              if (EbookGroup
                                                                      .usersubscriptionApiCall
                                                                      .success(
                                                                    (_model.subscriptionpayR
                                                                            ?.jsonBody ??
                                                                        ''),
                                                                  ) ==
                                                                  1) {
                                                                await showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (dialogContext) {
                                                                    return Dialog(
                                                                      elevation:
                                                                          0,
                                                                      insetPadding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .transparent,
                                                                      alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0)
                                                                          .resolve(
                                                                              Directionality.of(context)),
                                                                      child:
                                                                          GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          FocusScope.of(dialogContext)
                                                                              .unfocus();
                                                                          FocusManager
                                                                              .instance
                                                                              .primaryFocus
                                                                              ?.unfocus();
                                                                        },
                                                                        child:
                                                                            PaymentSuccessDialogWidget(
                                                                          onTapHome:
                                                                              () async {
                                                                            Navigator.pop(context);

                                                                            context.goNamed(HomePageWidget.routeName);
                                                                          },
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              } else {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content:
                                                                        Text(
                                                                      EbookGroup
                                                                          .usersubscriptionApiCall
                                                                          .message(
                                                                        (_model.subscriptionR?.jsonBody ??
                                                                            ''),
                                                                      )!,
                                                                      style:
                                                                          TextStyle(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                      ),
                                                                    ),
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            4000),
                                                                    backgroundColor:
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary,
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                          () async {
                                                            context.goNamed(
                                                                HomePageWidget
                                                                    .routeName);
                                                          },
                                                          () async {
                                                            context.goNamed(
                                                                HomePageWidget
                                                                    .routeName);
                                                          },
                                                        );
                                                      }
                                                    }

                                                    safeSetState(() {});
                                                  },
                                                  text: 'Buy now',
                                                  options: FFButtonOptions(
                                                    width: double.infinity,
                                                    height: 56.0,
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(24.0, 0.0,
                                                                24.0, 0.0),
                                                    iconPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: Colors.white,
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          lineHeight: 1.2,
                                                        ),
                                                    elevation: 0.0,
                                                    borderSide: BorderSide(
                                                      color: Colors.transparent,
                                                      width: 0.0,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
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
    );
  }
}
