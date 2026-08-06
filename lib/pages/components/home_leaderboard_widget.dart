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

  String _selectedPeriod = 'weekly';
  String _selectedMetric = 'reading';

  @override
  void initState() {
    super.initState();
    _fetchHomeLeaderboard();
  }

  Future<void> _fetchHomeLeaderboard() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await EbookGroup.getHomeLeaderboardCall.call(
        period: _selectedPeriod,
        metric: _selectedMetric,
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

  String _formatMetricValue(dynamic value, String metric, bool isBn) {
    if (value == null) return '0';
    if (metric == 'coins') {
      return isBn ? '$value কয়েন' : '$value Coins';
    }
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row: Title with Trophy & View All
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'লিডারবোর্ড' : 'Leaderboard',
                      style: theme.bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        lineHeight: 1.4,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullLeaderboardPageWidget(
                        initialPeriod: _selectedPeriod,
                        initialMetric: _selectedMetric,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      FFLocalizations.of(context).getText('view_all'),
                      style: theme.bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.0,
                        color: Colors.white,
                        lineHeight: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Single Horizontal Compact Filters Strip (Minimal Space)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Metric Chips
                _buildCompactChip(
                  icon: Icons.menu_book_rounded,
                  label: isBn ? 'পাঠ' : 'Reading',
                  isSelected: _selectedMetric == 'reading',
                  onTap: () {
                    if (_selectedMetric != 'reading') {
                      setState(() => _selectedMetric = 'reading');
                      _fetchHomeLeaderboard();
                    }
                  },
                ),
                const SizedBox(width: 4),
                _buildCompactChip(
                  icon: Icons.headphones_rounded,
                  label: isBn ? 'শ্রবণ' : 'Listening',
                  isSelected: _selectedMetric == 'listening',
                  onTap: () {
                    if (_selectedMetric != 'listening') {
                      setState(() => _selectedMetric = 'listening');
                      _fetchHomeLeaderboard();
                    }
                  },
                ),
                const SizedBox(width: 4),
                _buildCompactChip(
                  icon: Icons.monetization_on_rounded,
                  iconColor: Colors.amber,
                  label: isBn ? 'কয়েন' : 'Coins',
                  isSelected: _selectedMetric == 'coins',
                  onTap: () {
                    if (_selectedMetric != 'coins') {
                      setState(() => _selectedMetric = 'coins');
                      _fetchHomeLeaderboard();
                    }
                  },
                ),

                // Separator Divider
                Container(
                  height: 14,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: theme.alternate.withValues(alpha: 0.6),
                ),

                // Period Chips
                _buildCompactChip(
                  label: isBn ? 'আজ' : 'Daily',
                  isSelected: _selectedPeriod == 'daily',
                  onTap: () {
                    if (_selectedPeriod != 'daily') {
                      setState(() => _selectedPeriod = 'daily');
                      _fetchHomeLeaderboard();
                    }
                  },
                ),
                const SizedBox(width: 4),
                _buildCompactChip(
                  label: isBn ? 'সপ্তাহ' : 'Weekly',
                  isSelected: _selectedPeriod == 'weekly',
                  onTap: () {
                    if (_selectedPeriod != 'weekly') {
                      setState(() => _selectedPeriod = 'weekly');
                      _fetchHomeLeaderboard();
                    }
                  },
                ),
                const SizedBox(width: 4),
                _buildCompactChip(
                  label: isBn ? 'মাস' : 'Monthly',
                  isSelected: _selectedPeriod == 'monthly',
                  onTap: () {
                    if (_selectedPeriod != 'monthly') {
                      setState(() => _selectedPeriod = 'monthly');
                      _fetchHomeLeaderboard();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Top-10 Leaderboard Cards
          if (_loading)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  isBn ? 'কোনো ডাটা পাওয়া যায়নি' : 'No leaderboard data available',
                  style: TextStyle(color: theme.secondaryText, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 122,
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
                    width: 96,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: rank == 1
                            ? Colors.amber.withValues(alpha: 0.7)
                            : rank == 2
                                ? Colors.grey.withValues(alpha: 0.6)
                                : rank == 3
                                    ? Colors.brown.withValues(alpha: 0.5)
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
                              radius: 20,
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
                                        fontSize: 13,
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
                                    fontSize: rank <= 3 ? 12 : 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

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
                        const SizedBox(height: 3),

                        // Score Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatMetricValue(total, _selectedMetric, isBn),
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
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

  Widget _buildCompactChip({
    IconData? icon,
    Color? iconColor,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.primary : theme.alternate.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 11,
                color: isSelected ? Colors.white : (iconColor ?? theme.secondaryText),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
