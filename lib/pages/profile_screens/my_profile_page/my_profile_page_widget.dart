import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'my_profile_page_model.dart';
export 'my_profile_page_model.dart';

class MyProfilePageWidget extends StatefulWidget {
  const MyProfilePageWidget({super.key});

  static String routeName = 'MyProfilePage';
  static String routePath = '/myProfilePage';

  @override
  State<MyProfilePageWidget> createState() => _MyProfilePageWidgetState();
}

class _MyProfilePageWidgetState extends State<MyProfilePageWidget> {
  late MyProfilePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingProfile = false;
  String? _profileError;

  String _profileValue(String key) {
    final detail = FFAppState().userDetail;
    if (detail is! Map) {
      return '';
    }
    return detail[key]?.toString() ?? '';
  }

  String _profileImageUrl() {
    final raw = _profileValue('avatar_url').isNotEmpty
        ? _profileValue('avatar_url')
        : _profileValue('image');
    if (raw.isEmpty) {
      return '';
    }
    return raw.startsWith('http') ? raw : '${FFAppConstants.imageUrl}$raw';
  }

  Future<void> _loadProfile() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      return;
    }

    safeSetState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    final response = await EbookGroup.getprofileApiCall.call(
      token: FFAppState().token,
    );
    if (!mounted) {
      return;
    }

    if (response.succeeded) {
      final fresh = EbookGroup.getprofileApiCall.userDetail(response.jsonBody);
      final existing = FFAppState().userDetail;
      if (fresh is Map) {
        FFAppState().userDetail = <String, dynamic>{
          if (existing is Map) ...Map<String, dynamic>.from(existing),
          ...Map<String, dynamic>.from(fresh),
        };
        FFAppState().update(() {});
      }
      safeSetState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    safeSetState(() {
      _isLoadingProfile = false;
      _profileError = EbookGroup.getprofileApiCall.message(response.jsonBody) ??
          'Failed to load profile';
    });
  }

  Widget _infoCard({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).lightGrey,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 14.0, 16.0, 13.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 15.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      lineHeight: 1.5,
                    ),
              ),
              child,
            ].divide(const SizedBox(height: 6.0)),
          ),
        ),
      ),
    );
  }

  Widget _valueText(BuildContext context, String value, {int? maxLines}) {
    return Text(
      value,
      maxLines: maxLines,
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'SF Pro Display',
            fontSize: 17.0,
            letterSpacing: 0.0,
            lineHeight: 1.5,
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyProfilePageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfile();
      if (mounted) {
        safeSetState(() {});
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final displayName = _profileValue('display_name').isNotEmpty
        ? _profileValue('display_name')
        : _profileValue('username');
    final fullName = _profileValue('full_name').isNotEmpty
        ? _profileValue('full_name')
        : [_profileValue('firstname'), _profileValue('lastname')]
            .where((value) => value.isNotEmpty)
            .join(' ');
    final bio = _profileValue('bio');
    final preferredLanguage = _profileValue('preferred_language').toUpperCase();
    final email = _profileValue('email');
    final referralCode = _profileValue('referral_code');
    final createdAt = _profileValue('created_at');
    final joinedOn = createdAt.isNotEmpty
        ? dateTimeFormat('yMMMd', DateTime.tryParse(createdAt))
        : '';

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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 21.0, 16.0, 18.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.safePop();
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGrey,
                            shape: BoxShape.circle,
                          ),
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Align(
                            alignment: const AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/arrow_back_appbar_ic.svg',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.contain,
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'My profile',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 24.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    lineHeight: 1.5,
                                  ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          FFAppState().countryCodeEdit = (String var1) {
                            return var1.replaceAll('+', '');
                          }(_profileValue('country_code'));
                          FFAppState().phone = _profileValue('phone');
                          safeSetState(() {});

                          context.pushNamed(EditProfilePageWidget.routeName);
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGrey,
                            shape: BoxShape.circle,
                          ),
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Align(
                            alignment: const AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/edit_ic.svg',
                                width: 20.0,
                                height: 20.0,
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                    FlutterFlowTheme.of(context).primaryText,
                                    BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingProfile)
                const LinearProgressIndicator(minHeight: 2.0),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 24.0, 0, 16.0),
                  scrollDirection: Axis.vertical,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100.0,
                          height: 100.0,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: CachedNetworkImage(
                            fadeInDuration: const Duration(milliseconds: 200),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            imageUrl: _profileImageUrl(),
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/images/error_image.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _infoCard(
                      context: context,
                      label: 'Display name',
                      child: _valueText(context, displayName, maxLines: 1),
                    ),
                    _infoCard(
                      context: context,
                      label: 'Email',
                      child: _valueText(context, email, maxLines: 2),
                    ),
                    if (_profileValue('phone').isNotEmpty)
                      _infoCard(
                        context: context,
                        label: 'Phone number',
                        child: _valueText(
                            context, _profileValue('phone'), maxLines: 1),
                      ),
                    _infoCard(
                      context: context,
                      label: 'Bio',
                      child: _valueText(context, bio),
                    ),
                    _infoCard(
                      context: context,
                      label: 'Preferred language',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _valueText(context, preferredLanguage, maxLines: 1),
                          // if (referralCode.isNotEmpty)
                            // Text(
                            //   'Referral code: $referralCode',
                            //   style: FlutterFlowTheme.of(context)
                            //       .bodyMedium
                            //       .override(
                            //         fontFamily: 'SF Pro Display',
                            //         color: FlutterFlowTheme.of(context)
                            //             .secondaryText,
                            //         fontSize: 15.0,
                            //         letterSpacing: 0.0,
                            //         lineHeight: 1.5,
                            //       ),
                            // ),
                          // if (joinedOn.isNotEmpty)
                          //   Text(
                          //     'Joined: $joinedOn',
                          //     style: FlutterFlowTheme.of(context)
                          //         .bodyMedium
                          //         .override(
                          //           fontFamily: 'SF Pro Display',
                          //           color: FlutterFlowTheme.of(context)
                          //               .secondaryText,
                          //           fontSize: 15.0,
                          //           letterSpacing: 0.0,
                          //           lineHeight: 1.5,
                          //         ),
                          //   ),
                        ].divide(const SizedBox(height: 4.0)),
                      ),
                    ),
                    if (_profileError != null && _profileError!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 16.0, 16.0, 0.0),
                        child: Text(
                          _profileError!,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context).error,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
