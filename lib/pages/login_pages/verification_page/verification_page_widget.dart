import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'verification_page_model.dart';
export 'verification_page_model.dart';

class VerificationPageWidget extends StatefulWidget {
  const VerificationPageWidget({
    super.key,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.password,
    required this.phone,
  });

  final String? email;
  final String? firstname;
  final String? lastname;
  final String? username;
  final String? password;
  final String? phone;

  static String routeName = 'VerificationPage';
  static String routePath = '/verificationPage';

  @override
  State<VerificationPageWidget> createState() => _VerificationPageWidgetState();
}

class _VerificationPageWidgetState extends State<VerificationPageWidget> {
  late VerificationPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VerificationPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.timerController.onResetTimer();

      _model.timerController.onStartTimer();
    });

    _model.pinCodeFocusNode ??= FocusNode();

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
                  title: 'Verification',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      12.0,
                      0,
                      12.0,
                    ),
                    scrollDirection: Axis.vertical,
                    children: [
                      Text(
                        'Enter your email for the verification process. we will send 4 digits code to your email.',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 17.0,
                              letterSpacing: 0.0,
                              lineHeight: 1.5,
                            ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 24.0, 0.0, 16.0),
                        child: Text(
                          'Code sent to ${widget.email}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 17.0,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.5,
                                  ),
                        ),
                      ),
                      Form(
                        key: _model.formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 14.0),
                          child: PinCodeTextField(
                            autoDisposeControllers: false,
                            appContext: context,
                            length: 4,
                            textStyle:
                                FlutterFlowTheme.of(context).bodyLarge.override(
                                      fontFamily: 'SF Pro Display',
                                      letterSpacing: 0.0,
                                    ),
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            enableActiveFill: false,
                            autoFocus: false,
                            focusNode: _model.pinCodeFocusNode,
                            enablePinAutofill: false,
                            errorTextSpace: 16.0,
                            showCursor: true,
                            cursorColor: FlutterFlowTheme.of(context).primary,
                            obscureText: false,
                            hintCharacter: '●',
                            keyboardType: TextInputType.number,
                            pinTheme: PinTheme(
                              fieldHeight: 50.0,
                              fieldWidth: 50.0,
                              borderWidth: 1.0,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(12.0),
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                              shape: PinCodeFieldShape.box,
                              activeColor:
                                  FlutterFlowTheme.of(context).primaryText,
                              inactiveColor:
                                  FlutterFlowTheme.of(context).black30,
                              selectedColor:
                                  FlutterFlowTheme.of(context).primary,
                            ),
                            controller: _model.pinCodeController,
                            onChanged: (_) {},
                            autovalidateMode: AutovalidateMode.disabled,
                            validator: _model.pinCodeControllerValidator
                                .asValidator(context),
                          ),
                        ),
                      ),
                      FFButtonWidget(
                        onPressed: () async {
                          if (_model.formKey.currentState == null ||
                              !_model.formKey.currentState!.validate()) {
                            return;
                          }
                          _model.verifyOtpFunction =
                              await EbookGroup.userverificationApiCall.call(
                            email: widget.email,
                            otp: int.tryParse(_model.pinCodeController!.text),
                          );

                          if (EbookGroup.userverificationApiCall.success(
                                (_model.verifyOtpFunction?.jsonBody ?? ''),
                              ) ==
                              2) {
                            await actions.showCustomToastBottom(
                              EbookGroup.userverificationApiCall.message(
                                (_model.verifyOtpFunction?.jsonBody ?? ''),
                              )!,
                            );
                          } else {
                            if (EbookGroup.userverificationApiCall.success(
                                  (_model.verifyOtpFunction?.jsonBody ?? ''),
                                ) ==
                                1) {
                              FFAppState().isLogin = true;
                              FFAppState().token =
                                  EbookGroup.userverificationApiCall.token(
                                (_model.verifyOtpFunction?.jsonBody ?? ''),
                              )!;
                              FFAppState().userDetail = EbookGroup
                                  .userverificationApiCall
                                  .userDetails(
                                (_model.verifyOtpFunction?.jsonBody ?? ''),
                              );
                              FFAppState().userId =
                                  EbookGroup.userverificationApiCall.userId(
                                (_model.verifyOtpFunction?.jsonBody ?? ''),
                              )!;
                              FFAppState().update(() {});
                              if (FFAppState().favChange == true) {
                                _model.getFavourite =
                                    await EbookGroup.getFavouriteBookCall.call(
                                  userId: FFAppState().userId,
                                  token: FFAppState().token,
                                );

                                if (functions.checkFavOrNot(
                                        EbookGroup.getFavouriteBookCall
                                            .favouriteBookDetailsList(
                                              (_model.getFavourite?.jsonBody ??
                                                  ''),
                                            )
                                            ?.toList(),
                                        FFAppState().bookId) ==
                                    true) {
                                  _model.getAllBookDetete = await EbookGroup
                                      .removeFavouritebookCall
                                      .call(
                                    userId: FFAppState().userId,
                                    token: FFAppState().token,
                                    bookId: FFAppState().bookId,
                                  );
                                } else {
                                  _model.getAllBookAdd = await EbookGroup
                                      .addFavouriteBookApiCall
                                      .call(
                                    userId: FFAppState().userId,
                                    token: FFAppState().token,
                                    bookId: FFAppState().bookId,
                                  );
                                }

                                FFAppState().clearGetFavouriteBookCacheCache();
                                FFAppState().favChange = false;
                                FFAppState().bookId = '';
                                FFAppState().update(() {});

                                context.goNamed(HomePageWidget.routeName);
                              } else {
                                FFAppState().clearGetFavouriteBookCacheCache();
                                FFAppState().favChange = false;
                                FFAppState().bookId = '';
                                FFAppState().update(() {});

                                context.goNamed(HomePageWidget.routeName);
                              }
                            } else {
                              await actions.showCustomToastBottom(
                                EbookGroup.userverificationApiCall.message(
                                  (_model.verifyOtpFunction?.jsonBody ?? ''),
                                )!,
                              );
                            }
                          }

                          safeSetState(() {});
                        },
                        text: 'Verify',
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    lineHeight: 1.2,
                                  ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              if (_model.isShow == true) {
                                _model.resendotp =
                                    await EbookGroup.resendOTPApiCall.call(
                                  email: widget.email,
                                );

                                if (EbookGroup.resendOTPApiCall.success(
                                      (_model.resendotp?.jsonBody ?? ''),
                                    ) ==
                                    2) {
                                  await actions.showCustomToastBottom(
                                    EbookGroup.resendOTPApiCall.message(
                                      (_model.resendotp?.jsonBody ?? ''),
                                    )!,
                                  );
                                } else {
                                  _model.timerController.onResetTimer();

                                  _model.timerController.onStartTimer();
                                  _model.isShow = false;
                                  safeSetState(() {});
                                  await actions.showCustomToastBottom(
                                    'OTP Resend!',
                                  );
                                }
                              }

                              safeSetState(() {});
                            },
                            child: RichText(
                              textScaler: MediaQuery.of(context).textScaler,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Don’t receive an code? ',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                  TextSpan(
                                    text: 'Resend now',
                                    style: TextStyle(
                                      color: _model.isShow == true
                                          ? FlutterFlowTheme.of(context)
                                              .primaryText
                                          : FlutterFlowTheme.of(context)
                                              .secondaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      height: 1.5,
                                    ),
                                  )
                                ],
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                        child: FlutterFlowTimer(
                          initialTime: _model.timerInitialTimeMs,
                          getDisplayTime: (value) =>
                              StopWatchTimer.getDisplayTime(
                            value,
                            hours: false,
                            milliSecond: false,
                          ),
                          controller: _model.timerController,
                          updateStateInterval: Duration(milliseconds: 1000),
                          onChanged: (value, displayTime, shouldUpdate) {
                            _model.timerMilliseconds = value;
                            _model.timerValue = displayTime;
                            if (shouldUpdate) safeSetState(() {});
                          },
                          onEnded: () async {
                            _model.isShow = true;
                            safeSetState(() {});
                            _model.timerController.onStopTimer();
                          },
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                fontFamily: 'SF Pro Display',
                                fontSize: 20.0,
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
