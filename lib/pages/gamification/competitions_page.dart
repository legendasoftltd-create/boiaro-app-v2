import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';

class CompetitionsPageWidget extends StatefulWidget {
  const CompetitionsPageWidget({super.key});

  @override
  State<CompetitionsPageWidget> createState() => _CompetitionsPageWidgetState();
}

class _CompetitionsPageWidgetState extends State<CompetitionsPageWidget> {
  bool _loading = true;
  List<dynamic> _competitions = [];

  @override
  void initState() {
    super.initState();
    _fetchCompetitions();
  }

  Future<void> _fetchCompetitions() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getCompetitionsCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        final list = res.jsonBody['competitions'];
        if (list is List) {
          setState(() {
            _competitions = list;
          });
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showCompetitionLeaderboard(String competitionId, String title, String metric) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CompetitionLeaderboardSheet(
        competitionId: competitionId,
        title: title,
        metric: metric,
      ),
    );
  }

  String _formatMetricLabel(String metric) {
    switch (metric) {
      case 'reading_time':
        return '📖 পঠন সময়';
      case 'listening_time':
        return '🎧 শ্রবণ সময়';
      case 'purchases':
        return '🛒 মোট ক্রয়';
      case 'referrals':
        return '👥 মোট রেফারাল';
      default:
        return metric;
    }
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
            title: isBn ? 'মেগা প্রতিযোগিতা' : 'Mega Competitions',
            backIcon: false,
            addIcon: false,
            onTapAdd: () async {},
            onBackPressed: () async {
              context.safePop();
            },
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCompetitions,
              child: _competitions.isEmpty
                  ? Center(
                      child: Text(
                        isBn ? 'বর্তমানে কোনো প্রতিযোগিতা নেই' : 'No active competitions found',
                        style: TextStyle(color: theme.secondaryText),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _competitions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final comp = _competitions[index];
                        final id = comp['id']?.toString() ?? '';
                        final title = comp['title']?.toString() ?? 'Competition';
                        final description = comp['description']?.toString() ?? '';
                        final metric = comp['metric']?.toString() ?? 'reading_time';
                        final status = comp['status']?.toString() ?? 'active';
                        final prize1 = comp['prize_coin_top1'] ?? 100;
                        final prize2 = comp['prize_coin_top2'] ?? 50;
                        final prize3 = comp['prize_coin_top3'] ?? 25;

                        final isActive = status == 'active';

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isActive ? theme.primary.withOpacity(0.5) : theme.alternate,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive ? '● লাইভ চলছে' : 'সম্পন্ন',
                                      style: TextStyle(
                                        color: isActive ? Colors.green : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatMetricLabel(metric),
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: theme.titleMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  style: TextStyle(color: theme.secondaryText, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Top 3 Prizes Banner
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildPrizeBadge('🥇 ১ম', '$prize1 🪙'),
                                    _buildPrizeBadge('🥈 ২য়', '$prize2 🪙'),
                                    _buildPrizeBadge('🥉 ৩য়', '$prize3 🪙'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Leaderboard Button
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showCompetitionLeaderboard(id, title, metric),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.leaderboard, color: Colors.white),
                                  label: Text(
                                    isBn ? 'লাইভ লিডারবোর্ড দেখুন 🏆' : 'View Live Leaderboard 🏆',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildPrizeBadge(String place, String prize) {
    return Column(
      children: [
        Text(place, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          prize,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
      ],
    );
  }
}

class CompetitionLeaderboardSheet extends StatefulWidget {
  final String competitionId;
  final String title;
  final String metric;

  const CompetitionLeaderboardSheet({
    super.key,
    required this.competitionId,
    required this.title,
    required this.metric,
  });

  @override
  State<CompetitionLeaderboardSheet> createState() => _CompetitionLeaderboardSheetState();
}

class _CompetitionLeaderboardSheetState extends State<CompetitionLeaderboardSheet> {
  bool _loading = true;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getCompetitionLeaderboardCall.call(
        competitionId: widget.competitionId,
        token: token,
      );
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        final list = res.jsonBody['leaderboard'];
        if (list is List) {
          setState(() {
            _leaderboard = list;
          });
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _formatTotal(dynamic val, String metric) {
    final numVal = (val is num) ? val.toInt() : 0;
    if (metric == 'reading_time' || metric == 'listening_time') {
      final mins = (numVal / 60).round();
      if (mins < 60) return '$mins মি.';
      final hrs = mins ~/ 60;
      final rm = mins % 60;
      return '$hrs ঘ. $rm মি.';
    }
    return '$numVal';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🏆 ${widget.title}',
                  style: theme.titleMedium.override(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: theme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _leaderboard.isEmpty
                    ? const Center(child: Text('এখনও কোনো লিডারবোর্ড তথ্য নেই'))
                    : ListView.separated(
                        itemCount: _leaderboard.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index];
                          final rank = index + 1;
                          final name = user['display_name'] ?? 'User';
                          final total = user['total'];
                          final avatarUrl = user['avatar_url'];

                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    rank == 1
                                        ? '🥇'
                                        : rank == 2
                                            ? '🥈'
                                            : rank == 3
                                                ? '🥉'
                                                : '#$rank',
                                    style: TextStyle(
                                      fontSize: rank <= 3 ? 18 : 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty)
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                              ],
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              _formatTotal(total, widget.metric),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primary,
                                fontSize: 14,
                              ),
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
