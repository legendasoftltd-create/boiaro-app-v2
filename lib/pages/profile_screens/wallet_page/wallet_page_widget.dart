import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/custom_code/ad_manager.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;

class WalletPageWidget extends StatefulWidget {
  const WalletPageWidget({super.key});

  @override
  State<WalletPageWidget> createState() => _WalletPageWidgetState();
}

class _WalletPageWidgetState extends State<WalletPageWidget> {
  int _remainingAds = 0;
  int _coinsPerAd = 5;

  // Gamification tab and data state
  int _selectedTab = 0;
  bool _loadingLeaderboard = false;
  bool _loadingBadges = false;
  bool _loadingGoals = false;
  bool _loadingPoints = false;
  List<dynamic> _leaderboardData = [];
  List<dynamic> _badgeDefinitions = [];
  List<dynamic> _earnedBadges = [];
  List<dynamic> _goalsData = [];
  List<dynamic> _pointsHistory = [];
  bool _dailyClaimedToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdStatus();
      _fetchPointsHistory(); // Checks daily check-in status
    });
  }

  Future<void> _loadAdStatus() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
    try {
      final res = await EbookGroup.getRewardedAdStatusCall.call(
        token: FFAppState().token,
      );
      if (res.statusCode == 200 && res.jsonBody != null) {
        final remaining = getJsonField(res.jsonBody, r'''$.remaining''') ?? getJsonField(res.jsonBody, r'''$.data.remaining''');
        final coinPerAd = getJsonField(res.jsonBody, r'''$.coin_per_ad''') ?? getJsonField(res.jsonBody, r'''$.data.coin_per_ad''');
        if (mounted) {
          setState(() {
            if (remaining is num) _remainingAds = remaining.toInt();
            if (coinPerAd is num) _coinsPerAd = coinPerAd.toInt();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _claimDaily() async {
    final res = await EbookGroup.walletClaimDailyApiCall.call(
      token: FFAppState().token,
    );
    await actions.showCustomToastBottom(
      EbookGroup.walletClaimDailyApiCall.message(res.jsonBody) ?? 'Done',
    );
    if (mounted) safeSetState(() {});
  }

  Future<void> _claimAd() async {
    final res = await EbookGroup.walletClaimAdApiCall.call(
      token: FFAppState().token,
      placement: 'general',
    );
    await actions.showCustomToastBottom(
      EbookGroup.walletClaimAdApiCall.message(res.jsonBody) ?? 'Done',
    );
    if (mounted) safeSetState(() {});
  }

  Future<void> _handleClaimDaily() async {
    final canShow = await AdManager.canShowAd();
    if (!canShow) {
      await actions.showCustomToastBottom(
          'Please wait 3 minutes between ads or daily limit of 20 ads reached.');
      return;
    }

    if (!AdManager.isAdLoaded) {
      await actions.showCustomToastBottom('Loading Ad... Please wait a second.');
      final loaded = await AdManager.ensureAdLoaded();
      if (!loaded) {
        await actions.showCustomToastBottom('Failed to load ad. Please try again.');
        return;
      }
    }

    AdManager.showRewardedAd(
      context: context,
      onRewardEarned: () async {
        await _claimDaily();
        await _loadAdStatus();
      },
      onAdFailed: () async {
        await actions.showCustomToastBottom('Failed to show ad. Please try again.');
      },
    );
  }

  Future<void> _handleClaimAd() async {
    final canShow = await AdManager.canShowAd();
    if (!canShow) {
      await actions.showCustomToastBottom(
          'Please wait 3 minutes between ads or daily limit of 20 ads reached.');
      return;
    }

    if (!AdManager.isAdLoaded) {
      await actions.showCustomToastBottom('Loading Ad... Please wait a second.');
      final loaded = await AdManager.ensureAdLoaded();
      if (!loaded) {
        await actions.showCustomToastBottom('Failed to load ad. Please try again.');
        return;
      }
    }

    AdManager.showRewardedAd(
      context: context,
      onRewardEarned: () async {
        await _claimAd();
        await _loadAdStatus();
      },
      onAdFailed: () async {
        await actions.showCustomToastBottom('Failed to show ad. Please try again.');
      },
    );
  }

  // Gamification Fetch Methods
  void _onTabChanged(int index) {
    if (index == 1 && _leaderboardData.isEmpty) {
      _fetchLeaderboard();
    } else if (index == 2 && (_badgeDefinitions.isEmpty || _earnedBadges.isEmpty)) {
      _fetchBadges();
    } else if (index == 3 && _goalsData.isEmpty) {
      _fetchGoals();
    } else if (index == 4 && _pointsHistory.isEmpty) {
      _fetchPointsHistory();
    }
  }

  Future<void> _fetchLeaderboard() async {
    if (!FFAppState().isLogin) return;
    setState(() => _loadingLeaderboard = true);
    try {
      final res = await EbookGroup.getLeaderboardCall.call(token: FFAppState().token);
      if (res.statusCode == 200 && res.jsonBody != null) {
        final list = getJsonField(res.jsonBody, r'''$.leaderboard''') ?? getJsonField(res.jsonBody, r'''$.data.leaderboard''');
        if (list is List) {
          setState(() {
            _leaderboardData = list;
          });
        }
      }
    } catch (_) {}
    setState(() => _loadingLeaderboard = false);
  }

  Future<void> _fetchBadges() async {
    if (!FFAppState().isLogin) return;
    setState(() => _loadingBadges = true);
    try {
      final resDef = await EbookGroup.getBadgeDefinitionsCall.call(token: FFAppState().token);
      final resMy = await EbookGroup.getMyBadgesCall.call(token: FFAppState().token);
      if (resDef.statusCode == 200 && resDef.jsonBody != null) {
        final defs = getJsonField(resDef.jsonBody, r'''$.definitions''') ?? getJsonField(resDef.jsonBody, r'''$.data.definitions''');
        if (defs is List) {
          setState(() {
            _badgeDefinitions = defs;
          });
        }
      }
      if (resMy.statusCode == 200 && resMy.jsonBody != null) {
        final my = getJsonField(resMy.jsonBody, r'''$.badges''') ?? getJsonField(resMy.jsonBody, r'''$.data.badges''');
        if (my is List) {
          setState(() {
            _earnedBadges = my;
          });
        }
      }
    } catch (_) {}
    setState(() => _loadingBadges = false);
  }

  Future<void> _fetchGoals() async {
    if (!FFAppState().isLogin) return;
    setState(() => _loadingGoals = true);
    try {
      final res = await EbookGroup.getMyGoalsCall.call(token: FFAppState().token);
      if (res.statusCode == 200 && res.jsonBody != null) {
        final list = getJsonField(res.jsonBody, r'''$.goals''') ?? getJsonField(res.jsonBody, r'''$.data.goals''');
        if (list is List) {
          setState(() {
            _goalsData = list;
          });
        }
      }
    } catch (_) {}
    setState(() => _loadingGoals = false);
  }

  Future<void> _fetchPointsHistory() async {
    if (!FFAppState().isLogin) return;
    setState(() => _loadingPoints = true);
    try {
      final res = await EbookGroup.getPointsHistoryCall.call(limit: 50, token: FFAppState().token);
      if (res.statusCode == 200 && res.jsonBody != null) {
        final list = getJsonField(res.jsonBody, r'''$.history''') ?? getJsonField(res.jsonBody, r'''$.data.history''');
        if (list is List) {
          final today = DateTime.now().toIso8601String().split('T').first;
          final claimedToday = list.any((item) {
            final eventType = getJsonField(item, r'''$.event_type''')?.toString();
            final createdAt = getJsonField(item, r'''$.created_at''')?.toString() ?? '';
            return eventType == 'daily_login' && createdAt.startsWith(today);
          });
          setState(() {
            _pointsHistory = list;
            _dailyClaimedToday = claimedToday;
          });
        }
      }
    } catch (_) {}
    setState(() => _loadingPoints = false);
  }

  Future<void> _claimGamificationDailyReward() async {
    if (!FFAppState().isLogin) return;
    try {
      final res = await EbookGroup.claimDailyRewardCall.call(token: FFAppState().token);
      if (res.statusCode == 200) {
        await actions.showCustomToastBottom('Daily reward claimed successfully!');
        setState(() {
          _dailyClaimedToday = true;
        });
        _fetchPointsHistory();
        if (mounted) safeSetState(() {});
      } else if (res.statusCode == 400) {
        final reason = getJsonField(res.jsonBody, r'''$.reason''');
        if (reason == 'already_claimed') {
          await actions.showCustomToastBottom('Already claimed today!');
          setState(() {
            _dailyClaimedToday = true;
          });
        } else {
          await actions.showCustomToastBottom(
              getJsonField(res.jsonBody, r'''$.message''') ?? 'Could not claim daily reward');
        }
      } else {
        await actions.showCustomToastBottom('Failed to claim daily reward');
      }
    } catch (e) {
      await actions.showCustomToastBottom('Error: $e');
    }
  }

  Future<void> _showAddGoalDialog() async {
    String selectedType = 'reading';
    int targetValue = 30;
    String selectedPeriod = 'daily';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Set New Goal',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Type',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Reading')),
                          selected: selectedType == 'reading',
                          selectedColor: FlutterFlowTheme.of(context).primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'reading' ? Colors.white : FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedType = 'reading');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Listening')),
                          selected: selectedType == 'listening',
                          selectedColor: FlutterFlowTheme.of(context).primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'listening' ? Colors.white : FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedType = 'listening');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Period',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Daily')),
                          selected: selectedPeriod == 'daily',
                          selectedColor: FlutterFlowTheme.of(context).primary,
                          labelStyle: TextStyle(
                            color: selectedPeriod == 'daily' ? Colors.white : FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedPeriod = 'daily');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Weekly')),
                          selected: selectedPeriod == 'weekly',
                          selectedColor: FlutterFlowTheme.of(context).primary,
                          labelStyle: TextStyle(
                            color: selectedPeriod == 'weekly' ? Colors.white : FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedPeriod = 'weekly');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Value',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w600,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                      Text(
                        '$targetValue mins',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.bold,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                      ),
                    ],
                  ),
                  Slider(
                    value: targetValue.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    onChanged: (val) {
                      setDialogState(() => targetValue = val.toInt());
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _addGoal(selectedType, targetValue, selectedPeriod);
                  },
                  child: const Text('Add Goal', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addGoal(String type, int target, String period) async {
    if (!FFAppState().isLogin) return;
    try {
      final res = await EbookGroup.addGoalCall.call(
        goalType: type,
        targetValue: target,
        period: period,
        token: FFAppState().token,
      );
      if (res.statusCode == 200) {
        await actions.showCustomToastBottom('Goal set successfully!');
        _fetchGoals();
      } else {
        await actions.showCustomToastBottom('Failed to set goal');
      }
    } catch (e) {
      await actions.showCustomToastBottom('Error: $e');
    }
  }

  // UI Construction widgets
  Widget _buildTabBar() {
    final tabs = [
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet'},
      {'icon': Icons.leaderboard_rounded, 'label': 'Leaderboard'},
      {'icon': Icons.emoji_events_rounded, 'label': 'Badges'},
      {'icon': Icons.track_changes_rounded, 'label': 'Goals'},
      {'icon': Icons.history_rounded, 'label': 'Points'},
    ];
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          final tab = tabs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : FlutterFlowTheme.of(context).secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : FlutterFlowTheme.of(context).primaryText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: FlutterFlowTheme.of(context).primary,
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTab = index;
                  });
                  _onTabChanged(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: FlutterFlowTheme.of(context).primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daily Login Reward',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Claim points and coins for logging in today!',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'SF Pro Display',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _dailyClaimedToday
                  ? FlutterFlowTheme.of(context).alternate
                  : FlutterFlowTheme.of(context).primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            onPressed: _dailyClaimedToday ? null : _claimGamificationDailyReward,
            child: Text(
              _dailyClaimedToday ? 'Claimed' : 'Claim',
              style: TextStyle(
                color: _dailyClaimedToday ? FlutterFlowTheme.of(context).secondaryText : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_loadingLeaderboard && _leaderboardData.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: FlutterFlowTheme.of(context).primary,
        ),
      );
    }
    if (_leaderboardData.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLeaderboard,
        color: FlutterFlowTheme.of(context).primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'No leaderboard entries found.',
                style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      color: FlutterFlowTheme.of(context).primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboardData.length,
        itemBuilder: (context, index) {
          final row = _leaderboardData[index];
          final rank = getJsonField(row, r'''$.rank''') ?? (index + 1);
          final displayName = getJsonField(row, r'''$.display_name''')?.toString() ?? 'User';
          final points = getJsonField(row, r'''$.total_points''') ?? 0;
          final userId = getJsonField(row, r'''$.user_id''')?.toString() ?? '';
          final isMe = FFAppState().isLogin && userId == FFAppState().userId;

          Widget rankWidget;
          if (rank == 1) {
            rankWidget = const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28);
          } else if (rank == 2) {
            rankWidget = const Icon(Icons.emoji_events_rounded, color: Colors.grey, size: 26);
          } else if (rank == 3) {
            rankWidget = const Icon(Icons.emoji_events_rounded, color: Colors.brown, size: 24);
          } else {
            rankWidget = Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 12,
                ),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.08)
                  : FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                width: isMe ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                rankWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                          color: isMe ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMe ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$points Pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white : FlutterFlowTheme.of(context).primaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesTab() {
    if (_loadingBadges && _badgeDefinitions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: FlutterFlowTheme.of(context).primary,
        ),
      );
    }
    if (_badgeDefinitions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchBadges,
        color: FlutterFlowTheme.of(context).primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'No badge definitions found.',
                style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBadges,
      color: FlutterFlowTheme.of(context).primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _badgeDefinitions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final def = _badgeDefinitions[index];
          final key = getJsonField(def, r'''$.key''')?.toString() ?? '';
          final title = getJsonField(def, r'''$.title''')?.toString() ?? 'Badge';
          final desc = getJsonField(def, r'''$.description''')?.toString() ?? '';
          final reward = getJsonField(def, r'''$.coin_reward''') ?? 0;

          final earnedItem = _earnedBadges.firstWhere(
            (b) => getJsonField(b, r'''$.key''')?.toString() == key,
            orElse: () => null,
          );
          final isEarned = earnedItem != null;
          final earnedAtStr = isEarned ? getJsonField(earnedItem, r'''$.earned_at''')?.toString() : null;
          final earnedDate = earnedAtStr != null ? earnedAtStr.split('T').first : '';

          return Opacity(
            opacity: isEarned ? 1.0 : 0.6,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEarned ? Colors.amber : FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                  width: isEarned ? 2.0 : 1.0,
                ),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isEarned ? Colors.amber.withOpacity(0.15) : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEarned ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                          color: isEarned ? Colors.amber : FlutterFlowTheme.of(context).secondaryText,
                          size: 24,
                        ),
                      ),
                      if (isEarned)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 10,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$reward Coins',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (isEarned && earnedDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Earned $earnedDate',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalsTab() {
    if (_loadingGoals && _goalsData.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: FlutterFlowTheme.of(context).primary,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchGoals,
      color: FlutterFlowTheme.of(context).primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: _showAddGoalDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_task_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Set Reading/Listening Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_goalsData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No active goals. Set a goal above to start tracking!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                ),
              ),
            )
          else
            ..._goalsData.map((goal) {
              final type = getJsonField(goal, r'''$.goal_type''')?.toString() ?? 'reading';
              final target = getJsonField(goal, r'''$.target_value''') ?? 30;
              final current = getJsonField(goal, r'''$.current_value''') ?? 0;
              final period = getJsonField(goal, r'''$.period''')?.toString() ?? 'daily';
              final status = getJsonField(goal, r'''$.status''')?.toString() ?? 'active';
              final progress = (current / target).clamp(0.0, 1.0);
              final isCompleted = status == 'completed' || current >= target;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? Colors.green : FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                    width: isCompleted ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              type == 'listening' ? Icons.headset_rounded : Icons.menu_book_rounded,
                              color: isCompleted ? Colors.green : FlutterFlowTheme.of(context).primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${type.toUpperCase()} GOAL (${period.toUpperCase()})',
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? Colors.green : FlutterFlowTheme.of(context).primaryText,
                                  ),
                            ),
                          ],
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: $current / $target mins',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPointsHistoryTab() {
    if (_loadingPoints && _pointsHistory.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: FlutterFlowTheme.of(context).primary,
        ),
      );
    }
    if (_pointsHistory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPointsHistory,
        color: FlutterFlowTheme.of(context).primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'No points history found.',
                style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPointsHistory,
      color: FlutterFlowTheme.of(context).primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pointsHistory.length,
        itemBuilder: (context, index) {
          final row = _pointsHistory[index];
          final amount = getJsonField(row, r'''$.points''') ?? 0;
          final eventType = getJsonField(row, r'''$.event_type''')?.toString() ?? 'Activity';
          final createdAt = getJsonField(row, r'''$.created_at''')?.toString() ?? '';
          final date = createdAt.isNotEmpty ? createdAt.split('T').first : '';

          String displayTitle = eventType;
          if (eventType == 'chapter_listen') {
            displayTitle = 'Chapter Listened';
          } else if (eventType == 'daily_login') {
            displayTitle = 'Daily Check-In';
          } else if (eventType == 'streak') {
            displayTitle = 'Streak Bonus';
          } else if (eventType == 'reading') {
            displayTitle = 'Reading Activity';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.purple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          date,
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '+$amount Pts',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              CustomCenterAppbarWidget(
                title: 'Coins & Rewards',
                backIcon: false,
                addIcon: false,
                onTapAdd: () async {},
              ),
              Expanded(
                child: FutureBuilder<ApiCallResponse>(
                  future: EbookGroup.getGamificationSummaryCall.call(
                    token: FFAppState().token,
                  ),
                  builder: (context, walletSnap) {
                    if (!walletSnap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      );
                    }
                    final walletResp = walletSnap.data!;
                    final balance = getJsonField(walletResp.jsonBody, r'''$.wallet.balance''') ??
                        getJsonField(walletResp.jsonBody, r'''$.data.wallet.balance''') ?? 0;
                    final totalEarned = getJsonField(walletResp.jsonBody, r'''$.wallet.total_earned''') ??
                        getJsonField(walletResp.jsonBody, r'''$.data.wallet.total_earned''') ?? 0;
                    final totalSpent = getJsonField(walletResp.jsonBody, r'''$.wallet.total_spent''') ??
                        getJsonField(walletResp.jsonBody, r'''$.data.wallet.total_spent''') ?? 0;
                    final streakCurrent = getJsonField(walletResp.jsonBody, r'''$.streak.current''') ??
                        getJsonField(walletResp.jsonBody, r'''$.data.streak.current''') ?? 0;
                    final streakBest = getJsonField(walletResp.jsonBody, r'''$.streak.best''') ??
                        getJsonField(walletResp.jsonBody, r'''$.data.streak.best''') ?? 0;
                    final totalPoints = getJsonField(walletResp.jsonBody, r'''$.total_points''') ??
                        getJsonField(walletResp.jsonBody, r'''$.data.total_points''') ?? 0;

                    return FutureBuilder<ApiCallResponse>(
                      future: EbookGroup.walletTransactionsApiCall.call(
                        token: FFAppState().token,
                        limit: 50,
                      ),
                      builder: (context, txSnap) {
                        final tx = txSnap.data != null
                            ? (EbookGroup.walletTransactionsApiCall
                                        .transactions(txSnap.data!.jsonBody)
                                        ?.toList() ??
                                    <dynamic>[])
                            : <dynamic>[];

                        // Header info and Segmented tabs build
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Column(
                                children: [
                                  // Compact Header Card
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          FlutterFlowTheme.of(context).primary,
                                          FlutterFlowTheme.of(context).secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 10,
                                          color: FlutterFlowTheme.of(context).primary.withOpacity(0.15),
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.monetization_on_rounded,
                                            color: Colors.amberAccent,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Available Coins',
                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                      fontFamily: 'SF Pro Display',
                                                      color: Colors.white.withOpacity(0.8),
                                                    ),
                                              ),
                                              Text(
                                                '$balance',
                                                style: FlutterFlowTheme.of(context).titleLarge.override(
                                                      fontFamily: 'SF Pro Display',
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 36,
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.arrow_upward_rounded, color: Colors.greenAccent, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Earned: $totalEarned',
                                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.arrow_downward_rounded, color: Colors.redAccent, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Spent: $totalSpent',
                                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Daily Streak & Points Card
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 22),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$streakCurrent Days',
                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                          fontFamily: 'SF Pro Display',
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Current Streak (Best: $streakBest)',
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                      fontFamily: 'SF Pro Display',
                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 30,
                                          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.stars_rounded, color: Colors.purple, size: 22),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$totalPoints Pts',
                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                          fontFamily: 'SF Pro Display',
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Gamification Points',
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                      fontFamily: 'SF Pro Display',
                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildTabBar(),
                            Expanded(
                              child: IndexedStack(
                                index: _selectedTab,
                                children: [
                                  // Tab 0: Wallet View
                                  RefreshIndicator(
                                    color: FlutterFlowTheme.of(context).primary,
                                    onRefresh: () async {
                                      _loadAdStatus();
                                      _fetchPointsHistory();
                                      if (mounted) safeSetState(() {});
                                    },
                                    child: ListView(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      children: [
                                        _buildDailyCheckInCard(),
                                        // Compact Action Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: _handleClaimDaily,
                                                borderRadius: BorderRadius.circular(10),
                                                child: Container(
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.task_alt, color: FlutterFlowTheme.of(context).primary, size: 16),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Daily Reward',
                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                              fontFamily: 'SF Pro Display',
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: _handleClaimAd,
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: Container(
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(
                                                          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.play_circle_fill_rounded, color: Colors.orangeAccent, size: 18),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            'Watch Ad (+$_coinsPerAd)',
                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                  fontFamily: 'SF Pro Display',
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (FFAppState().isLogin) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$_remainingAds left today',
                                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                                            fontFamily: 'SF Pro Display',
                                                            color: FlutterFlowTheme.of(context).secondaryText,
                                                            fontSize: 11,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const custom_widgets.AdBannerWidget(
                                          placementKey: 'wallet_page',
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Transaction History',
                                          style: FlutterFlowTheme.of(context).titleMedium.override(
                                                fontFamily: 'SF Pro Display',
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (tx.isEmpty)
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'No transactions yet',
                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                      fontFamily: 'SF Pro Display',
                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ...tx.map((row) {
                                          final amount = getJsonField(row, r'''$.amount''').toString();
                                          final desc = getJsonField(row, r'''$.description''').toString();
                                          final createdAt = getJsonField(row, r'''$.created_at''').toString();
                                          final positive = (int.tryParse(amount) ?? 0) >= 0;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  blurRadius: 2,
                                                  color: FlutterFlowTheme.of(context).shadowColor.withOpacity(0.01),
                                                  offset: const Offset(0, 1),
                                                )
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: positive ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    positive ? Icons.add_rounded : Icons.remove_rounded,
                                                    color: positive ? Colors.green : Colors.redAccent,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        desc.isEmpty ? 'Wallet Transaction' : desc,
                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                              fontFamily: 'SF Pro Display',
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        createdAt.split('T').first,
                                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                                              fontFamily: 'SF Pro Display',
                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '${positive ? "+" : ""}$amount',
                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                        fontFamily: 'SF Pro Display',
                                                        color: positive ? Colors.green : Colors.redAccent,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  // Tab 1: Leaderboard View
                                  _buildLeaderboardTab(),
                                  // Tab 2: Badges View
                                  _buildBadgesTab(),
                                  // Tab 3: Goals View
                                  _buildGoalsTab(),
                                  // Tab 4: Points View
                                  _buildPointsHistoryTab(),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
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
