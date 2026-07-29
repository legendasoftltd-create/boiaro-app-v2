import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/custom_code/actions/index.dart' as actions;

class SpinWheelDialog extends StatefulWidget {
  const SpinWheelDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final token = FFAppState().token;
    if (token.isEmpty) {
      await actions.showCustomToastBottom('লগইন করুন স্পিন করতে');
      return;
    }

    try {
      final res = await EbookGroup.getSpinWheelStatusCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        final body = res.jsonBody as Map<String, dynamic>;
        if (body['available'] == false) {
          if (context.mounted) {
            await actions.showCustomToastBottom('স্পিন হুইল বর্তমানে উপলব্ধ নয়');
          }
          return;
        }

        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => const SpinWheelDialog(),
          );
        }
        return;
      }
    } catch (_) {}

    if (context.mounted) {
      await actions.showCustomToastBottom('স্পিন হুইল লোড করতে সমস্যা হয়েছে');
    }
  }

  @override
  State<SpinWheelDialog> createState() => _SpinWheelDialogState();
}

class _SpinWheelDialogState extends State<SpinWheelDialog>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _spinning = false;
  bool _canSpin = true;
  int _spinsToday = 0;
  int _spinsPerDay = 2;
  List<dynamic> _segments = [];

  late AnimationController _animController;
  late Animation<double> _animation;
  double _startRotation = 0;
  double _endRotation = 0;

  final List<Color> _sliceColors = [
    const Color(0xFFFF5722),
    const Color(0xFF9C27B0),
    const Color(0xFF2196F3),
    const Color(0xFF4CAF50),
    const Color(0xFFFFC107),
    const Color(0xFFE91E63),
    const Color(0xFF00BCD4),
    const Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fetchStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getSpinWheelStatusCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        final body = res.jsonBody as Map<String, dynamic>;
        setState(() {
          _canSpin = body['canSpin'] == true;
          _spinsToday = (body['spinsToday'] is num) ? (body['spinsToday'] as num).toInt() : 0;
          _spinsPerDay = (body['spinsPerDay'] is num) ? (body['spinsPerDay'] as num).toInt() : 2;
          final segs = body['segments'];
          if (segs is List) _segments = segs;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _spin() async {
    if (_spinning || !_canSpin || _segments.isEmpty) return;
    setState(() => _spinning = true);

    try {
      final token = FFAppState().token;
      final res = await EbookGroup.spinWheelSpinCall.call(token: token);
      final body = res.jsonBody;

      if (res.statusCode == 200 && body is Map<String, dynamic>) {
        if (body['success'] == true) {
          final targetIndex = (body['segmentIndex'] is num) ? (body['segmentIndex'] as num).toInt() : 0;
          final segment = body['segment'];
          final rewardText = segment is Map ? (segment['label'] ?? 'Reward') : 'Reward';
          final coinReward = segment is Map && segment['coin_reward'] is num ? (segment['coin_reward'] as num).toInt() : 0;

          // Compute rotation so targetIndex lands under top pointer (270 deg or -90 deg)
          final count = _segments.length;
          final sliceAngle = (2 * pi) / count;
          // Center of target slice
          final sliceCenterAngle = targetIndex * sliceAngle + (sliceAngle / 2);

          // Pointer is at top (-pi / 2 rad)
          // Final angle mod 2pi should align sliceCenterAngle under top pointer
          final targetAngleOnWheel = (1.5 * pi) - sliceCenterAngle;

          // Add 5 full rotations (10 * pi) for dramatic effect
          final extraRotations = 5 * 2 * pi;
          _startRotation = _endRotation % (2 * pi);
          _endRotation = _startRotation + extraRotations + (targetAngleOnWheel - (_startRotation % (2 * pi)));
          if (_endRotation < _startRotation + extraRotations) {
            _endRotation += 2 * pi;
          }

          _animController.reset();
          _animController.forward().then((_) async {
            setState(() {
              _spinning = false;
              _spinsToday += 1;
              if (_spinsToday >= _spinsPerDay) _canSpin = false;
            });

            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('🎉 অভিনন্দন!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('আপনি পেয়েছেন: $rewardText', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (coinReward > 0) ...[
                      const SizedBox(height: 10),
                      Text('🪙 +$coinReward Coins Added!', style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('ঠিক আছে'),
                  ),
                ],
              ),
            );
          });
          return;
        } else {
          final reason = body['reason'];
          if (reason == 'daily_limit_reached') {
            setState(() => _canSpin = false);
            await actions.showCustomToastBottom('আজকের স্পিন লিমিট শেষ!');
          } else {
            await actions.showCustomToastBottom('স্পিন করতে ব্যর্থ হয়েছে');
          }
        }
      } else {
        await actions.showCustomToastBottom('স্পিন সার্ভার প্রতিক্রিয়া দিতে ব্যর্থ হয়েছে');
      }
    } catch (e) {
      await actions.showCustomToastBottom('Error: $e');
    }
    setState(() => _spinning = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isBn = FFLocalizations.of(context).locale.languageCode == 'bn';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primary.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _loading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🎡 ', style: TextStyle(fontSize: 24)),
                          Text(
                            isBn ? 'স্পিন এন্ড উইন' : 'Spin & Win',
                            style: theme.titleMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: theme.secondaryText),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? 'আজকের স্পিন: $_spinsToday / $_spinsPerDay'
                        : 'Spins today: $_spinsToday / $_spinsPerDay',
                    style: TextStyle(
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wheel Container
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final currentRad = _startRotation + (_endRotation - _startRotation) * _animation.value;
                            return Transform.rotate(
                              angle: currentRad,
                              child: CustomPaint(
                                size: const Size(250, 250),
                                painter: WheelPainter(
                                  segments: _segments,
                                  colors: _sliceColors,
                                  textColor: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),

                        // Top Pointer Indicator
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 24),
                          ),
                        ),

                        // Center Spin Button / Hub
                        GestureDetector(
                          onTap: (_spinning || !_canSpin) ? null : _spin,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _canSpin ? theme.primary : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                            ),
                            child: Center(
                              child: Text(
                                _spinning
                                    ? '...'
                                    : (isBn ? 'স্পিন' : 'SPIN'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Spin Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_spinning || !_canSpin) ? null : _spin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canSpin ? theme.primary : Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        !_canSpin
                            ? (isBn ? 'আজকের স্পিন লিমিট শেষ' : 'Daily Limit Reached')
                            : (isBn ? 'এখনই হুইল ঘুরান' : 'Spin the Wheel'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<dynamic> segments;
  final List<Color> colors;
  final Color textColor;

  WheelPainter({
    required this.segments,
    required this.colors,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final count = segments.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / count;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final startAngle = i * sweepAngle;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Border lines
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1.5;
      final x = center.dx + radius * cos(startAngle);
      final y = center.dy + radius * sin(startAngle);
      canvas.drawLine(center, Offset(x, y), linePaint);

      // Render Label Text
      final segment = segments[i];
      final label = segment is Map ? (segment['label']?.toString() ?? '') : '';

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final tx = center.dx + textRadius * cos(textAngle);
      final ty = center.dy + textRadius * sin(textAngle);

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(textAngle + pi / 2);

      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer Rim Border
    final rimPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, rimPaint);
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) => true;
}
