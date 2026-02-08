import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';

class AdRewardDialog extends StatelessWidget {
  final VoidCallback onWatchAd;

  const AdRewardDialog({Key? key, required this.onWatchAd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: FlutterFlowTheme.of(context).primary,
                size: 64,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeInOut),
            SizedBox(height: 24),
            // Title
            Text(
              'Free Reading Access',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            // Description
            Text(
              'To keep this book free for everyone, please watch a short video. It helps us support local authors and maintain the library!',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'SF Pro Display',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    lineHeight: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            // Actions
            FFButtonWidget(
              onPressed: () {
                Navigator.pop(context);
                onWatchAd();
              },
              text: 'Watch Video & Read',
              options: FFButtonOptions(
                width: double.infinity,
                height: 54,
                padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                color: FlutterFlowTheme.of(context).primary,
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'SF Pro Display',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                elevation: 3,
                borderSide: BorderSide(
                  color: Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ).animate().slideY(begin: 0.1, duration: 300.ms),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }
}
