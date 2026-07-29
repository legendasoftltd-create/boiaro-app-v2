import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';

class FullLeaderboardPageWidget extends StatefulWidget {
  final String initialPeriod;
  final String initialMetric;

  const FullLeaderboardPageWidget({
    super.key,
    this.initialPeriod = 'weekly',
    this.initialMetric = 'reading',
  });

  @override
  State<FullLeaderboardPageWidget> createState() => _FullLeaderboardPageWidgetState();
}

class _FullLeaderboardPageWidgetState extends State<FullLeaderboardPageWidget> {
  late String _selectedPeriod;
  late String _selectedMetric;
  bool _loading = false;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _selectedMetric = widget.initialMetric;
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
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
    final theme = FlutterFlowTheme.of(context);
    final isBn = FFLocalizations.of(context).locale.languageCode == 'bn';

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(79),
        child: SafeArea(
          child: CustomCenterAppbarWidget(
            title: isBn ? 'লিডারবোর্ড' : 'Leaderboard',
            backIcon: false,
            addIcon: false,
            onTapAdd: () async {},
            onBackPressed: () async {
              context.safePop();
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Period Tabs (Today / Weekly / Monthly)
            Container(
              color: theme.secondaryBackground,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildPeriodTab('daily', isBn ? 'আজকে' : 'Today')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPeriodTab('weekly', isBn ? 'এই সপ্তাহ' : 'Weekly')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPeriodTab('monthly', isBn ? 'এই মাস' : 'Monthly')),
                ],
              ),
            ),

            // Metric Tabs (Reading / Listening / Coins)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildMetricTab('reading', isBn ? '📖 পাঠ' : 'Reading')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricTab('listening', isBn ? '🎧 শ্রবণ' : 'Listening')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricTab('coins', isBn ? '🪙 কয়েন' : 'Coins')),
                ],
              ),
            ),

            const Divider(height: 1),

            // Leaderboard List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchLeaderboard,
                      child: _leaderboard.isEmpty
                          ? Center(
                              child: Text(
                                isBn ? 'কোনো ডাটা পাওয়া যায়নি' : 'No leaderboard data found',
                                style: TextStyle(color: theme.secondaryText),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _leaderboard.length,
                              itemBuilder: (context, index) {
                                final item = _leaderboard[index];
                                final rank = item['rank'] ?? (index + 1);
                                final name = item['display_name'] ?? (isBn ? 'পাঠক' : 'User');
                                final total = item['total'];
                                final avatarUrl = item['avatar_url'];
                                final isTop3 = rank <= 3;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.secondaryBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isTop3
                                          ? Colors.amber.withValues(alpha: 0.5)
                                          : theme.alternate.withValues(alpha: 0.3),
                                      width: isTop3 ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 34,
                                        child: Text(
                                          rank == 1
                                              ? '🥇'
                                              : rank == 2
                                                  ? '🥈'
                                                  : rank == 3
                                                      ? '🥉'
                                                      : '#$rank',
                                          style: TextStyle(
                                            fontSize: isTop3 ? 22 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: theme.secondaryText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 18,
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
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.bodyMedium.override(
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _formatMetricValue(total, _selectedMetric, isBn),
                                          style: TextStyle(
                                            color: theme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedPeriod = period);
        _fetchLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.secondaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTab(String metric, String label) {
    final isSelected = _selectedMetric == metric;
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedMetric = metric);
        _fetchLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withValues(alpha: 0.15) : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.primary : theme.alternate.withValues(alpha: 0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.primary : theme.secondaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
