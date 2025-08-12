import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'delete_account_instruction_page_model.dart';
export 'delete_account_instruction_page_model.dart';

class DeleteAccountInstructionPageWidget extends StatefulWidget {
  const DeleteAccountInstructionPageWidget({super.key});

  static String routeName = 'DeleteAccountInstructionPage';
  static String routePath = '/deleteAccountInstructionPage';

  @override
  State<DeleteAccountInstructionPageWidget> createState() =>
      _DeleteAccountInstructionPageWidgetState();
}

class _DeleteAccountInstructionPageWidgetState
    extends State<DeleteAccountInstructionPageWidget>
    with TickerProviderStateMixin {
  late DeleteAccountInstructionPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeleteAccountInstructionPageModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 800.0.ms,
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
                  title: 'Delete account',
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected == true) {
                      return Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: FutureBuilder<ApiCallResponse>(
                          future: (_model.apiRequestCompleter ??=
                                  Completer<ApiCallResponse>()
                                    ..complete(EbookGroup.getpagesApiCall.call(
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
                            final listViewGetpagesApiResponse = snapshot.data!;

                            return RefreshIndicator(
                              key: Key('RefreshIndicator_8678twea'),
                              color: FlutterFlowTheme.of(context).primary,
                              onRefresh: () async {
                                safeSetState(
                                    () => _model.apiRequestCompleter = null);
                                await _model.waitForApiRequestCompleted();
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
                                  custom_widgets.HtmlConverter(
                                    width: double.infinity,
                                    height: 50.0,
                                    text: EbookGroup.getpagesApiCall
                                        .deleteaccountinstruction(
                                      listViewGetpagesApiResponse.jsonBody,
                                    )!,
                                  ).animateOnPageLoad(animationsMap[
                                      'containerOnPageLoadAnimation']!),
                                  if (FFAppState().isLogin == true)
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          80.0, 12.0, 80.0, 0.0),
                                      child: FFButtonWidget(
                                        onPressed: () async {
                                          _model.deleteFunction =
                                              await EbookGroup.deleteuserApiCall
                                                  .call(
                                            userId: FFAppState().userId,
                                            token: FFAppState().token,
                                          );

                                          if (EbookGroup.deleteuserApiCall
                                                  .success(
                                                (_model.deleteFunction
                                                        ?.jsonBody ??
                                                    ''),
                                              ) ==
                                              2) {
                                            await actions.showCustomToastBottom(
                                              EbookGroup.deleteuserApiCall
                                                  .message(
                                                (_model.deleteFunction
                                                        ?.jsonBody ??
                                                    ''),
                                              )!,
                                            );
                                          } else {
                                            if (EbookGroup.deleteuserApiCall
                                                    .success(
                                                  (_model.deleteFunction
                                                          ?.jsonBody ??
                                                      ''),
                                                ) ==
                                                1) {
                                              FFAppState().isLogin = false;
                                              FFAppState()
                                                  .homePageLiveReadBook = '';
                                              FFAppState().searchList = [];
                                              FFAppState().userId = '';
                                              FFAppState().userDetail = null;
                                              FFAppState().token = '';
                                              FFAppState().update(() {});
                                              FFAppState()
                                                  .clearGetFavouriteBookCacheCache();

                                              context.goNamed(
                                                  HomePageWidget.routeName);
                                            } else {
                                              await actions
                                                  .showCustomToastBottom(
                                                EbookGroup.deleteuserApiCall
                                                    .message(
                                                  (_model.deleteFunction
                                                          ?.jsonBody ??
                                                      ''),
                                                )!,
                                              );
                                            }
                                          }

                                          safeSetState(() {});
                                        },
                                        text: 'Yes',
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 56.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  24.0, 0.0, 24.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                fontFamily: 'SF Pro Display',
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
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
