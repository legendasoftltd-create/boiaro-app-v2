import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/custom_code/actions/index.dart' as actions;

class DailyRewardDialog extends StatefulWidget {
  final Map<String, dynamic>? initialStatus;
  final Function()? onClaimed;

  static const String _kLastClaimedDateKey = 'last_daily_reward_claimed_date';

  const DailyRewardDialog({
    super.key,
    this.initialStatus,
    this.onClaimed,
  });

  /// Auto check on home/app open:
  /// 1. Reads local date cache from SharedPreferences. If claimed today -> STOP (no popup, 0 API calls).
  /// 2. If not cached, fetches status via API. If claimed_today == true -> saves to local cache & STOP.
  /// 3. If claimed_today == false -> shows DailyRewardDialog popup!
  static Future<void> checkAndShowOnAppOpen(BuildContext context) async {
    final token = FFAppState().token;
    if (token.isEmpty) return;

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedClaimedDate = prefs.getString(_kLastClaimedDateKey);

      // Fast check: If locally cached as claimed today, skip completely!
      if (cachedClaimedDate == todayStr) {
        return;
      }
    } catch (_) {}

    Map<String, dynamic>? status;
    try {
      final res = await EbookGroup.getDailyRewardStatusCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        status = res.jsonBody;
        final claimedToday = status?['claimed_today'] == true;
        if (claimedToday) {
          // Update local cache so we skip further checks for today
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_kLastClaimedDateKey, todayStr);
          } catch (_) {}
          return;
        }
      }
    } catch (_) {}

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => DailyRewardDialog(
          initialStatus: status,
          onClaimed: () async {
            try {
              final p = await SharedPreferences.getInstance();
              await p.setString(_kLastClaimedDateKey, todayStr);
            } catch (_) {}
          },
        ),
      );
    }
  }

  static Future<void> show(BuildContext context, {Function()? onClaimed}) async {
    final token = FFAppState().token;
    if (token.isEmpty) return;

    Map<String, dynamic>? status;
    try {
      final res = await EbookGroup.getDailyRewardStatusCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        status = res.jsonBody;
      }
    } catch (_) {}

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => DailyRewardDialog(
          initialStatus: status,
          onClaimed: onClaimed,
        ),
      );
    }
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  bool _loading = false;
  bool _claiming = false;
  bool _claimedToday = false;
  int _day = 1;
  List<int> _schedule = [5, 10, 15, 20, 25, 30, 50];
  int _todayReward = 15;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _applyStatus(widget.initialStatus!);
    } else {
      _fetchStatus();
    }
  }

  void _applyStatus(Map<String, dynamic> status) {
    setState(() {
      _claimedToday = status['claimed_today'] == true;
      _day = (status['day'] is num) ? (status['day'] as num).toInt() : 1;
      final sched = status['schedule'];
      if (sched is List) {
        _schedule = sched.map((e) => (e is num) ? e.toInt() : 0).toList();
      }
      if (_schedule.isNotEmpty && _day >= 1 && _day <= _schedule.length) {
        _todayReward = _schedule[_day - 1];
      } else {
        _todayReward = (status['reward'] is num) ? (status['reward'] as num).toInt() : 10;
      }
    });
  }

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getDailyRewardStatusCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        _applyStatus(res.jsonBody);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _claimReward() async {
    if (_claiming || _claimedToday) return;
    setState(() => _claiming = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.claimDailyRewardCall.call(token: token);
      final body = res.jsonBody;

      if (res.statusCode == 200 && body is Map<String, dynamic>) {
        final success = body['success'] == true;
        if (success) {
          final rw = (body['reward'] is num) ? (body['reward'] as num).toInt() : _todayReward;
          await actions.showCustomToastBottom(
            '🎉 $rw কয়েন পুরস্কার পেয়েছেন! (Streak: ${body['current_streak'] ?? _day} দিন)',
          );
          setState(() {
            _claimedToday = true;
          });
          try {
            final todayStr = DateTime.now().toIso8601String().split('T').first;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(DailyRewardDialog._kLastClaimedDateKey, todayStr);
          } catch (_) {}
          if (widget.onClaimed != null) widget.onClaimed!();
        } else {
          final reason = body['reason'];
          if (reason == 'already_claimed') {
            setState(() => _claimedToday = true);
            try {
              final todayStr = DateTime.now().toIso8601String().split('T').first;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(DailyRewardDialog._kLastClaimedDateKey, todayStr);
            } catch (_) {}
            await actions.showCustomToastBottom('আজকের পুরস্কার ইতিমধ্যেই দাবি করা হয়েছে!');
          } else {
            await actions.showCustomToastBottom('পুরস্কার দাবি করতে সমস্যা হয়েছে');
          }
        }
      } else {
        await actions.showCustomToastBottom('পুরস্কার দাবি করতে ব্যর্থ হয়েছে');
      }
    } catch (e) {
      await actions.showCustomToastBottom('Error: $e');
    }
    setState(() => _claiming = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isBn = FFLocalizations.of(context).locale.languageCode == 'bn';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
                  // Top Header with Flame Badge & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🔥', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? 'দৈনিক পুরষ্কার' : 'Daily Reward',
                                style: theme.titleMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                              ),
                              Text(
                                isBn ? 'ধারাবাহিক লগইনে কয়েন জিতুন!' : 'Streak & earn bonus coins!',
                                style: theme.bodySmall.override(
                                  fontFamily: 'SF Pro Display',
                                  color: theme.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: theme.secondaryText, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Days 1-6 Grid (3 columns x 2 rows)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final dayNum = index + 1;
                      final amount = (_schedule.length > index) ? _schedule[index] : (index + 1) * 5;
                      final isPast = dayNum < _day || (dayNum == _day && _claimedToday);
                      final isCurrent = dayNum == _day && !_claimedToday;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.primary
                              : isPast
                                  ? theme.primaryBackground.withValues(alpha: 0.7)
                                  : theme.primaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.amber
                                : isPast
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : theme.alternate,
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: theme.primary.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isBn ? 'দিন $dayNum' : 'Day $dayNum',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : isPast
                                        ? theme.secondaryText
                                        : theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isPast)
                              const Icon(Icons.check_circle_rounded, size: 22, color: Colors.green)
                            else ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    size: 14,
                                    color: isCurrent ? Colors.white : Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+$amount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? Colors.white : Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Day 7 Mega Featured Reward Banner
                  Builder(
                    builder: (context) {
                      const dayNum = 7;
                      final amount = (_schedule.length > 6) ? _schedule[6] : 50;
                      final isPast = dayNum < _day || (dayNum == _day && _claimedToday);
                      final isCurrent = dayNum == _day && !_claimedToday;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF9900), Color(0xFFFF5500)],
                                )
                              : isPast
                                  ? LinearGradient(
                                      colors: [
                                        Colors.green.shade900.withValues(alpha: 0.3),
                                        Colors.green.shade800.withValues(alpha: 0.2),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        theme.primaryBackground,
                                        theme.primaryBackground.withValues(alpha: 0.8),
                                      ],
                                    ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.amber
                                : isPast
                                    ? Colors.green.withValues(alpha: 0.6)
                                    : Colors.amber.withValues(alpha: 0.5),
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('👑', style: TextStyle(fontSize: 22)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isBn ? 'দিন ৭' : 'Day 7',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: (isCurrent || isPast) ? Colors.white : theme.primaryText,
                                      ),
                                    ),
                                    Text(
                                      isBn ? 'গ্র্যান্ড ট্রেজার বোনাস' : 'Grand Treasure Bonus',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: (isCurrent || isPast)
                                            ? Colors.white.withValues(alpha: 0.8)
                                            : theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isPast)
                              const Icon(Icons.check_circle_rounded, size: 26, color: Colors.greenAccent)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      size: 16,
                                      color: Colors.amberAccent,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '+$amount',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // Main Claim Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_claimedToday || _claiming) ? null : _claimReward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _claimedToday ? Colors.grey.shade700 : theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _claimedToday ? 0 : 4,
                      ),
                      child: _claiming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _claimedToday ? Icons.check_circle_rounded : Icons.stars_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _claimedToday
                                      ? (isBn ? 'আজকের পুরষ্কার নেওয়া হয়েছে' : 'Claimed Today')
                                      : (isBn ? 'আজকের +$_todayReward কয়েন সংগ্রহ করুন' : 'Claim +$_todayReward Coins'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
