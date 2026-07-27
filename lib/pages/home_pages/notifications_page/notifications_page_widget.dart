import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/pages/empty_components/no_notification_yet/no_notification_yet_widget.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'notifications_page_model.dart';
export 'notifications_page_model.dart';

class NotificationsPageWidget extends StatefulWidget {
  const NotificationsPageWidget({super.key});

  static String routeName = 'NotificationsPage';
  static String routePath = '/notificationsPage';

  @override
  State<NotificationsPageWidget> createState() =>
      _NotificationsPageWidgetState();
}

class _NotificationsPageWidgetState extends State<NotificationsPageWidget>
    with TickerProviderStateMixin {
  late NotificationsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};
  List<String> _unreadIds = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationsPageModel());
    _model.apiRequestCompleter = null;

    animationsMap.addAll({
      'listViewOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.customCenterAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: CustomCenterAppbarWidget(
                  title: FFLocalizations.of(context).getVariableText(enText: 'Notifications', bnText: 'নোটিফিকেশন'),
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                  customAction: _unreadIds.isNotEmpty
                      ? InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await EbookGroup.readNotificationsApiCall.call(
                              ids: _unreadIds,
                              token: FFAppState().token,
                            );
                            FFAppState().unreadNotificationCount = 0;
                            safeSetState(() {
                              _unreadIds = [];
                              _model.apiRequestCompleter = null;
                            });
                          },
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).lightGrey,
                              shape: BoxShape.circle,
                            ),
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Icon(
                              Icons.done_all,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 20.0,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (FFAppState().connected) {
                      return FutureBuilder<ApiCallResponse>(
                        future: (_model.apiRequestCompleter ??= Completer<
                                ApiCallResponse>()
                              ..complete(EbookGroup.getnotificationApiCall.call(
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
                          final containerGetnotificationApiResponse =
                              snapshot.data!;

                          return Container(
                            decoration: BoxDecoration(),
                            child: Builder(
                              builder: (context) {
                                if (EbookGroup.getnotificationApiCall.success(
                                      containerGetnotificationApiResponse
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
                                          EbookGroup.getnotificationApiCall
                                              .message(
                                            containerGetnotificationApiResponse
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
                                }

                                return Builder(
                                    builder: (context) {
                                       final notificationList =
                                           EbookGroup.getnotificationApiCall
                                                   .notificationDetails(
                                                     containerGetnotificationApiResponse
                                                         .jsonBody,
                                                   )
                                                   ?.toList() ??
                                               [];
                                       
                                       final List<String> currentUnreadIds = notificationList
                                           .where((e) => e is Map && e['id'] != null && e['is_read'] == false)
                                           .map((e) => (e as Map)['id'].toString())
                                           .where((id) => id.isNotEmpty)
                                           .toList();

                                       if (!listEquals(_unreadIds, currentUnreadIds)) {
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                           if (mounted) {
                                             setState(() {
                                               _unreadIds = currentUnreadIds;
                                             });
                                           }
                                         });
                                       }

                                       final int apiUnreadCount = EbookGroup.getnotificationApiCall
                                           .unreadCount(containerGetnotificationApiResponse.jsonBody);
                                       if (FFAppState().unreadNotificationCount != apiUnreadCount) {
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                           FFAppState().unreadNotificationCount = apiUnreadCount;
                                         });
                                       }

                                       if (notificationList.isEmpty) {
                                        return Center(
                                          child: NoNotificationYetWidget(),
                                        );
                                      }

                                      return RefreshIndicator(
                                        key: Key('RefreshIndicator_3yfuzeyw'),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        onRefresh: () async {
                                          safeSetState(() => _model
                                              .apiRequestCompleter = null);
                                          await _model
                                              .waitForApiRequestCompleted();
                                        },
                                        child: ListView.separated(
                                          padding: EdgeInsets.fromLTRB(
                                            0,
                                            16.0,
                                            0,
                                            16.0,
                                          ),
                                          scrollDirection: Axis.vertical,
                                          itemCount: notificationList.length,
                                          separatorBuilder: (_, __) =>
                                              SizedBox(height: 16.0),
                                          itemBuilder:
                                              (context, notificationListIndex) {
                                            final notificationListItem =
                                                notificationList[
                                                    notificationListIndex];
                                            final isRead = getJsonField(
                                                  notificationListItem,
                                                  r'''$.is_read''',
                                                ) ==
                                                true;
                                            return Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () async {
                                                  final titleText = getJsonField(
                                                    notificationListItem,
                                                    r'''$.title''',
                                                  ).toString();
                                                  final descriptionText = getJsonField(
                                                    notificationListItem,
                                                    r'''$.description''',
                                                  ).toString();
                                                  final dateText = getJsonField(
                                                    notificationListItem,
                                                    r'''$.date''',
                                                  ).toString();

                                                  if (!isRead) {
                                                    final String notificationId = getJsonField(
                                                      notificationListItem,
                                                      r'''$.id''',
                                                    ).toString();
                                                    if (notificationId.isNotEmpty) {
                                                      EbookGroup.readNotificationsApiCall.call(
                                                        ids: [notificationId],
                                                        token: FFAppState().token,
                                                      );
                                                      if (FFAppState().unreadNotificationCount > 0) {
                                                        FFAppState().unreadNotificationCount =
                                                            FFAppState().unreadNotificationCount - 1;
                                                      }
                                                      safeSetState(() {
                                                        _model.apiRequestCompleter = null;
                                                      });
                                                    }
                                                  }

                                                  await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16.0),
                                                        ),
                                                        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                        title: Text(
                                                          titleText,
                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                fontFamily: 'SF Pro Display',
                                                                fontSize: 20.0,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                        ),
                                                        content: SingleChildScrollView(
                                                          child: ListBody(
                                                            children: [
                                                              Text(
                                                                descriptionText,
                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                      fontFamily: 'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                      fontSize: 16.0,
                                                                      lineHeight: 1.5,
                                                                    ),
                                                              ),
                                                              const SizedBox(height: 16.0),
                                                              Text(
                                                                dateText,
                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                      fontFamily: 'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                                      fontSize: 13.0,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            child: Text(
                                                              FFLocalizations.of(context).getVariableText(
                                                                enText: 'Close',
                                                                bnText: 'বন্ধ করুন',
                                                              ),
                                                              style: TextStyle(
                                                                color: FlutterFlowTheme.of(context).primary,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: isRead
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .primary
                                                            .withOpacity(0.08),
                                                    border: isRead
                                                        ? null
                                                        : Border.all(
                                                            color: FlutterFlowTheme.of(context)
                                                                .primary
                                                                .withOpacity(0.3),
                                                            width: 1.0,
                                                          ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        blurRadius: 16.0,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .shadowColor,
                                                        offset: Offset(
                                                          0.0,
                                                          4.0,
                                                        ),
                                                      )
                                                    ],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                  ),
                                                  child: Padding(
                                                    padding: EdgeInsetsDirectional
                                                        .fromSTEB(16.0, 16.0,
                                                            14.0, 19.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: 40.0,
                                                          height: 40.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                blurRadius: 16.0,
                                                                color: FlutterFlowTheme
                                                                        .of(context)
                                                                    .shadowColor,
                                                                offset: Offset(
                                                                  0.0,
                                                                  4.0,
                                                                ),
                                                              )
                                                            ],
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        0.0),
                                                            child:
                                                                SvgPicture.asset(
                                                              'assets/images/notification.svg',
                                                              width: 24.0,
                                                              height: 24.0,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  getJsonField(
                                                                    notificationListItem,
                                                                    r'''$.title''',
                                                                  ).toString(),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
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
                                                                                .bold,
                                                                        lineHeight:
                                                                            1.5,
                                                                      ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              0.0,
                                                                              8.0,
                                                                              0.0,
                                                                              14.0),
                                                                  child: Text(
                                                                    getJsonField(
                                                                      notificationListItem,
                                                                      r'''$.description''',
                                                                    ).toString(),
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'SF Pro Display',
                                                                          color: FlutterFlowTheme.of(context)
                                                                              .secondaryText,
                                                                          fontSize:
                                                                              17.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  getJsonField(
                                                                    notificationListItem,
                                                                    r'''$.date''',
                                                                  ).toString(),
                                                                  maxLines: 1,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'SF Pro Display',
                                                                        fontSize:
                                                                            15.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .normal,
                                                                        lineHeight:
                                                                            1.5,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        if (!isRead)
                                                          Padding(
                                                            padding: EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 0.0, 0.0),
                                                            child: Container(
                                                              width: 8.0,
                                                              height: 8.0,
                                                              decoration: BoxDecoration(
                                                                color: FlutterFlowTheme.of(context).primary,
                                                                shape: BoxShape.circle,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ).animateOnPageLoad(animationsMap[
                                          'listViewOnPageLoadAnimation']!);
                                    },
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
