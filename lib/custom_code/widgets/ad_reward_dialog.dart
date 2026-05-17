import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../ad_manager.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';

class AdRewardDialog extends StatefulWidget {
  final VoidCallback onWatchAd;
  final String? bookImage;

  const AdRewardDialog({
    Key? key,
    required this.onWatchAd,
    this.bookImage,
  }) : super(key: key);

  @override
  _AdRewardDialogState createState() => _AdRewardDialogState();
}

class _AdRewardDialogState extends State<AdRewardDialog> {
  int _countdown = 4;
  Timer? _timer;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    // Start loading the ad as soon as the dialog appears
    print('AdRewardDialog: Start initial ad load...');
    AdManager.loadRewardedAd();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          _tryShowAd();
        }
      }
    });
  }

  void _tryShowAd() {
    Navigator.pop(context);
    if (AdManager.isAdLoaded) {
      AdManager.showRewardedAd(
        context: context,
        onRewardEarned: () {
          widget.onWatchAd();
        },
        onAdFailed: () {
          widget.onWatchAd(); // fallback if ad fails to show
        },
      );
    } else {
      widget.onWatchAd(); // fallback if ad wasn't loaded but timer finished
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top "Skip Ad" row
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip Ad',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.close,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Illustration / Book Image
                if (widget.bookImage != null && widget.bookImage!.isNotEmpty)
                  Container(
                    height: 180,
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.bookImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.book_rounded,
                          size: 64,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  )
                else
                  Image.network(
                    'https://img.freepik.com/free-vector/hand-drawn-person-reading-book-illustration_23-2148834925.jpg',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.book_rounded,
                        size: 64,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                SizedBox(height: 24),
                // Title (Bangla)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'ফ্রী ই-বুকটি ডাউনলোড করতে ভিডিও এডটি দেখুন',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SolaimanLipi',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: FlutterFlowTheme.of(context).primaryText,
                          lineHeight: 1.4,
                        ),
                  ),
                ),
                SizedBox(height: 32),
                // Action Button
                FFButtonWidget(
                  onPressed: _isLoadingAd ? null : () {
                    if (AdManager.isAdLoaded) {
                      _timer?.cancel();
                      _tryShowAd();
                    } else {
                      setState(() {
                        _isLoadingAd = true;
                      });
                      print('AdRewardDialog: Button clicked, requesting ad...');
                      AdManager.loadRewardedAd();
                      // Wait a bit then check again
                      Timer(Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _isLoadingAd = false;
                          });
                          if (AdManager.isAdLoaded) {
                            _timer?.cancel();
                            _tryShowAd();
                          }
                        }
                      });
                    }
                  },
                  text: _isLoadingAd ? 'Loading Ad...' : 'WATCH AD NOW',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 52,
                    padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                    iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'SF Pro Display',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                    elevation: 0,
                    borderSide: BorderSide(
                      color: Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                SizedBox(height: 12),
                // Countdown text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ad starting in ',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 13,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    Icon(
                      Icons.smart_display_rounded,
                      size: 16,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    Text(
                      ' $_countdown Sec',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: Offset(0.9, 0.9)),
    );
  }
}
