import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/pages/gamification/full_leaderboard_page.dart';

class HomeLeaderboardWidget extends StatefulWidget {
  const HomeLeaderboardWidget({super.key});

  @override
  State<HomeLeaderboardWidget> createState() => _HomeLeaderboardWidgetState();
}

class _HomeLeaderboardWidgetState extends State<HomeLeaderboardWidget> {
  bool _loading = false;
  List<dynamic> _leaderboard = [];
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _fetchHomeLeaderboard();
  }

  Future<void> _fetchHomeLeaderboard() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // By default fetch weekly reading leaderboard for Home page
      final res = await EbookGroup.getHomeLeaderboardCall.call(
        period: 'weekly',
        metric: 'reading',
      );
      if (res.statusCode == 200 && res.jsonBody != null) {
        final data = getJsonField(res.jsonBody, r'''$.leaderboard''') ??
            getJsonField(res.jsonBody, r'''$.data''') ??
            res.jsonBody;
        if (data is List) {
          setState(() {
            _leaderboard = data;
            _isHidden = false;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _formatMetricValue(dynamic value, bool isBn) {
    if (value == null) return '0';
    final totalSecs = (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0;
    final mins = (totalSecs / 60).round();
    if (mins < 60) {
      return isBn ? '$mins মি.' : '${mins}m';
    }
    final hrs = (mins / 60).floor();
    final rm = mins % 60;
    return isBn ? '$hrs ঘ. $rm মি.' : '${hrs}h ${rm}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

    final theme = FlutterFlowTheme.of(context);
    final isBn = FFLocalizations.of(context).locale.languageCode == 'bn';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row: Title & View All (Matches Home Page _buildSectionHeader exactly)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn ? 'সাপ্তাহিক লিডারবোর্ড' : 'Weekly Leaderboard',
                  maxLines: 1,
                  style: theme.bodyMedium.override(
                    fontFamily: 'SF Pro Display',
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                    lineHeight: 1.5,
                  ),
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FullLeaderboardPageWidget(
                        initialPeriod: 'weekly',
                        initialMetric: 'reading',
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      FFLocalizations.of(context).getText('view_all'),
                      style: theme.bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.0,
                        color: Colors.white,
                        lineHeight: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Top-10 Leaderboard Cards (Author/Narrator horizontal scroll style)
          if (_leaderboard.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                isBn ? 'কোনো ডাটা পাওয়া যায়নি' : 'No leaderboard data available',
                style: TextStyle(color: theme.secondaryText, fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 124,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _leaderboard.length > 10 ? 10 : _leaderboard.length,
                itemBuilder: (context, index) {
                  final item = _leaderboard[index];
                  final rank = item['rank'] ?? (index + 1);
                  final name = item['display_name'] ?? (isBn ? 'পাঠক' : 'User');
                  final total = item['total'];
                  final avatarUrl = item['avatar_url'];

                  return Container(
                    width: 98,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: rank == 1
                            ? Colors.amber.withValues(alpha: 0.6)
                            : rank == 2
                                ? Colors.grey.withValues(alpha: 0.5)
                                : rank == 3
                                    ? Colors.brown.withValues(alpha: 0.4)
                                    : theme.alternate.withValues(alpha: 0.3),
                        width: rank <= 3 ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar with Rank Badge overlay
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.primary.withValues(alpha: 0.15),
                              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: (avatarUrl == null || avatarUrl.isEmpty)
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  rank == 1
                                      ? '🥇'
                                      : rank == 2
                                          ? '🥈'
                                          : rank == 3
                                              ? '🥉'
                                              : '#$rank',
                                  style: TextStyle(
                                    fontSize: rank <= 3 ? 13 : 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Display Name
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Score Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatMetricValue(total, isBn),
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
