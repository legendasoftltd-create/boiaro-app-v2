import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'splash_page_model.dart';
export 'splash_page_model.dart';

class SplashPageWidget extends StatefulWidget {
  const SplashPageWidget({super.key});

  static String routeName = 'SplashPage';
  static String routePath = '/splashPage';

  @override
  State<SplashPageWidget> createState() => _SplashPageWidgetState();
}

class _SplashPageWidgetState extends State<SplashPageWidget>
    with TickerProviderStateMixin {
  late SplashPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      await actions.getDeviceId();
      await actions.getCountryCodeLocal();
      if (FFAppState().isIntro == true) {
        context.goNamed(HomePageWidget.routeName);
      } else {
        context.goNamed(OnboardingPageWidget.routeName);
      }
    });

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 50.0.ms,
            duration: 200.0.ms,
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
        body:Image.asset('assets/images/splash.jpg',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
        ),
        //  SafeArea(
        //   top: true,
        //   child: Container(
        //     width: double.infinity,
        //     height: double.infinity,
        //     decoration: BoxDecoration(
        //       color: FlutterFlowTheme.of(context).primaryBackground,
        //     ),
        //     child: Padding(
        //       padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        //       child: Column(
        //         mainAxisSize: MainAxisSize.max,
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         children: [
        //           Padding(
        //             padding:
        //                 EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
        //             child: Image.asset('assets/images/logo.png',
        //               width: 160.0,
        //               height: 120.0,
        //               fit: BoxFit.contain,
        //             ),
        //           ),
        //           // Padding(
        //           //   padding:
        //           //       EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
        //           //   child: Lottie.asset(
        //           //     'assets/jsons/Animation_-_1714827570006.json',
        //           //     width: 102.0,
        //           //     height: 102.0,
        //           //     fit: BoxFit.cover,
        //           //     animate: true,
        //           //   ),
        //           // ),
        //           // Text(
        //           //   'Boi Aro',
        //           //   textAlign: TextAlign.center,
        //           //   style: FlutterFlowTheme.of(context).bodyMedium.override(
        //           //         fontFamily: 'SF Pro Display',
        //           //         fontSize: 28.0,
        //           //         letterSpacing: 0.0,
        //           //         fontWeight: FontWeight.bold,
        //           //         lineHeight: 1.5,
        //           //       ),
        //           // ).animateOnPageLoad(
        //           //     animationsMap['textOnPageLoadAnimation']!),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ),
    );
  }
}
