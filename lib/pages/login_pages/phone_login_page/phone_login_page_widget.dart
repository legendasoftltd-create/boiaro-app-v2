import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class PhoneLoginPageWidget extends StatefulWidget {
  const PhoneLoginPageWidget({super.key});

  static String routeName = 'PhoneLoginPage';
  static String routePath = '/phoneLoginPage';

  @override
  State<PhoneLoginPageWidget> createState() => _PhoneLoginPageWidgetState();
}

class _PhoneLoginPageWidgetState extends State<PhoneLoginPageWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _errorMessage;
  String _phoneForVerify = '';

  // Cooldown timer for resend
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
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
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _fullOtp => _otpControllers.map((c) => c.text).join();

  void _startCooldown() {
    _cooldownSeconds = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      safeSetState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      safeSetState(() => _errorMessage = 'Please enter your phone number');
      return;
    }

    safeSetState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    try {
      final response = await EbookGroup.phoneSendOtpApiCall.call(phone: phone);
      if (!mounted) return;

      if (response.succeeded &&
          EbookGroup.phoneSendOtpApiCall.sent(response.jsonBody) == true) {
        safeSetState(() {
          _isOtpSent = true;
          _phoneForVerify = phone;
          _isSendingOtp = false;
        });
        _startCooldown();
        // Focus on first OTP field
        _otpFocusNodes[0].requestFocus();
      } else {
        final msg = EbookGroup.phoneSendOtpApiCall.errorMessage(response.jsonBody) ??
            'Failed to send OTP. Please try again.';
        safeSetState(() {
          _isSendingOtp = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _isSendingOtp = false;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _fullOtp;
    if (otp.length != 6) {
      safeSetState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    safeSetState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    try {
      final response = await EbookGroup.phoneVerifyOtpApiCall.call(
        phone: _phoneForVerify,
        otp: otp,
      );
      if (!mounted) return;

      if (EbookGroup.phoneVerifyOtpApiCall.success(response.jsonBody) == 1) {
        // Login successful
        FFAppState().isLogin = true;
        FFAppState().token =
            EbookGroup.phoneVerifyOtpApiCall.token(response.jsonBody) ?? '';
        FFAppState().refreshToken =
            EbookGroup.phoneVerifyOtpApiCall.refreshToken(response.jsonBody) ?? '';
        FFAppState().userId =
            EbookGroup.phoneVerifyOtpApiCall.userId(response.jsonBody) ?? '';
        FFAppState().userDetail =
            EbookGroup.phoneVerifyOtpApiCall.userDetails(response.jsonBody);
        FFAppState().update(() {});

        if (mounted) {
          context.goNamed('HomePage');
        }
      } else {
        final msg = EbookGroup.phoneVerifyOtpApiCall.message(response.jsonBody) ??
            'Verification failed. Please try again.';
        safeSetState(() {
          _isVerifyingOtp = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _isVerifyingOtp = false;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    // Auto-verify when all 6 digits entered
    if (_fullOtp.length == 6) {
      _verifyOtp();
    }
  }

  void _onOtpKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _otpControllers[index - 1].clear();
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _goBackToPhone() {
    safeSetState(() {
      _isOtpSent = false;
      _errorMessage = null;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
    _phoneFocusNode.requestFocus();
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      height: 56.0,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onOtpKeyDown(index, event),
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).black30,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).primary,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).error,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).error,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'SF Pro Display',
                fontSize: 20.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
          cursorColor: FlutterFlowTheme.of(context).primary,
          onChanged: (value) => _onOtpChanged(index, value),
        ),
      ),
    );
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
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 24.0, 0, 0),
                    scrollDirection: Axis.vertical,
                    children: [
                      // Back button
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                if (_isOtpSent) {
                                  _goBackToPhone();
                                } else {
                                  context.safePop();
                                }
                              },
                              child: Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color:
                                      FlutterFlowTheme.of(context).lightGrey,
                                  shape: BoxShape.circle,
                                ),
                                alignment:
                                    const AlignmentDirectional(0.0, 0.0),
                                child: Align(
                                  alignment:
                                      const AlignmentDirectional(0.0, 0.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0.0),
                                    child: SvgPicture.asset(
                                      'assets/images/arrow_back_appbar_ic.svg',
                                      width: 20.0,
                                      height: 20.0,
                                      fit: BoxFit.contain,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            _isOtpSent ? 'Enter OTP' : 'Phone Login',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 28.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  lineHeight: 1.5,
                                ),
                          ).animateOnPageLoad(
                              animationsMap['textOnPageLoadAnimation']!),
                        ].divide(const SizedBox(height: 8.0)),
                      ),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 8.0, 0.0, 24.0),
                        child: Text(
                          _isOtpSent
                              ? 'We sent a 6-digit verification code to $_phoneForVerify'
                              : 'Enter your phone number to receive a one-time verification code',
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

                      if (!_isOtpSent) ...[
                        // Phone input
                        TextFormField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+]')),
                          ],
                          onFieldSubmitted: (_) => _sendOtp(),
                          decoration: InputDecoration(
                            labelText: 'Phone number',
                            labelStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .primaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                ),
                            hintText: '01XXXXXXXXX',
                            hintStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  lineHeight: 1.5,
                                ),
                            errorStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color:
                                      FlutterFlowTheme.of(context).error,
                                  fontSize: 15.0,
                                  letterSpacing: 0.0,
                                  lineHeight: 1.2,
                                ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    FlutterFlowTheme.of(context).black30,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryText,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    FlutterFlowTheme.of(context).error,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    FlutterFlowTheme.of(context).error,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 13.0, 16.0, 12.0),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                              child: Icon(
                                Icons.phone_outlined,
                                color: FlutterFlowTheme.of(context).secondaryText,
                                size: 22.0,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                fontSize: 17.0,
                                letterSpacing: 0.0,
                                lineHeight: 1.5,
                              ),
                          cursorColor:
                              FlutterFlowTheme.of(context).primary,
                        ),
                        const SizedBox(height: 30.0),
                        // Send OTP button
                        FFButtonWidget(
                          onPressed: _isSendingOtp ? null : () => _sendOtp(),
                          text: _isSendingOtp ? 'Sending...' : 'Send OTP',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            iconPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  lineHeight: 1.2,
                                ),
                            elevation: 0.0,
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                            disabledColor:
                                FlutterFlowTheme.of(context).black20,
                            disabledTextColor:
                                FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                      ],

                      if (_isOtpSent) ...[
                        // OTP input fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            6,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.0),
                                child: _buildOtpField(index),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        // Verify button
                        FFButtonWidget(
                          onPressed:
                              _isVerifyingOtp ? null : () => _verifyOtp(),
                          text: _isVerifyingOtp ? 'Verifying...' : 'Verify & Login',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            iconPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  lineHeight: 1.2,
                                ),
                            elevation: 0.0,
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                            disabledColor:
                                FlutterFlowTheme.of(context).black20,
                            disabledTextColor:
                                FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Resend OTP
                        Center(
                          child: _cooldownSeconds > 0
                              ? Text(
                                  'Resend OTP in ${_cooldownSeconds}s',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 15.0,
                                        letterSpacing: 0.0,
                                      ),
                                )
                              : InkWell(
                                  splashColor: Colors.transparent,
                                  onTap: _isSendingOtp ? null : () => _sendOtp(),
                                  child: Text(
                                    'Resend OTP',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16.0),
                        // Change phone number
                        Center(
                          child: InkWell(
                            splashColor: Colors.transparent,
                            onTap: _goBackToPhone,
                            child: Text(
                              'Change phone number',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 15.0,
                                    letterSpacing: 0.0,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ),
                      ],

                      // Error message
                      if (_errorMessage != null && _errorMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .error
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color:
                                      FlutterFlowTheme.of(context).error,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(
                                                  context)
                                              .error,
                                          fontSize: 14.0,
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
            ],
          ),
        ),
      ),
    );
  }
}
