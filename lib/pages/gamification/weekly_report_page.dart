import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/services/share_helper.dart';

class WeeklyReportPageWidget extends StatefulWidget {
  const WeeklyReportPageWidget({super.key});

  @override
  State<WeeklyReportPageWidget> createState() => _WeeklyReportPageWidgetState();
}

class _WeeklyReportPageWidgetState extends State<WeeklyReportPageWidget> {
  bool _loading = true;
  bool _sharing = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchWeeklyReport();
  }

  Future<void> _fetchWeeklyReport() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getWeeklyReportCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        setState(() {
          _reportData = res.jsonBody;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _handleShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    await ShareHelper.shareWeeklyReportCard();
    setState(() => _sharing = false);
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0 মিনিট';
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins মিনিট';
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    if (remainingMins == 0) return '$hours ঘণ্টা';
    return '$hours ঘণ্টা $remainingMins মিনিট';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isBn = FFLocalizations.of(context).locale.languageCode == 'bn';

    final totalSeconds = (_reportData?['totalSeconds'] is num) ? (_reportData!['totalSeconds'] as num).toInt() : 0;
    final bookCount = (_reportData?['bookCount'] is num) ? (_reportData!['bookCount'] as num).toInt() : 0;
    final lastWeekSeconds = (_reportData?['lastWeekSeconds'] is num) ? (_reportData!['lastWeekSeconds'] as num).toInt() : 0;
    final weekOverWeekPercent = _reportData?['weekOverWeekPercent'];
    final books = (_reportData?['books'] is List) ? (_reportData!['books'] as List) : [];

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(79),
        child: SafeArea(
          child: CustomCenterAppbarWidget(
            title: isBn ? 'সাপ্তাহিক রিপোর্ট' : 'Weekly Report',
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
              onRefresh: _fetchWeeklyReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primary,
                            theme.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isBn ? '📊 এই সপ্তাহের পাঠ সারসংক্ষেপ' : '📊 Weekly Summary',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.auto_graph, color: Colors.white70, size: 28),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatTime(totalSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isBn ? 'মোট বই স্পর্শ করেছেন: $bookCount টি' : 'Books active this week: $bookCount',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (weekOverWeekPercent != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (weekOverWeekPercent is num && weekOverWeekPercent >= 0) ? Icons.trending_up : Icons.trending_down,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (weekOverWeekPercent is num && weekOverWeekPercent >= 0)
                                        ? 'গত সপ্তাহের চেয়ে +$weekOverWeekPercent% বেশি!'
                                        : 'গত সপ্তাহের চেয়ে $weekOverWeekPercent%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Key Metrics Cards Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.alternate),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('⏱️ সময়', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(totalSeconds),
                                  style: theme.titleMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.alternate),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('⏮️ গত সপ্তাহ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(lastWeekSeconds),
                                  style: theme.titleMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Books Read This Week
                    Text(
                      isBn ? 'পঠিত বইসমূহ' : 'Books Read',
                      style: theme.titleMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (books.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isBn ? 'এই সপ্তাহে কোনো বই পড়া হয়নি' : 'No books read this week yet',
                          style: TextStyle(color: theme.secondaryText),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: books.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final b = books[index];
                          final title = b['title'] ?? 'Book';
                          final coverUrl = b['cover_url'] ?? '';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.alternate),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: coverUrl.isNotEmpty
                                      ? Image.network(
                                          coverUrl,
                                          width: 45,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 40),
                                        )
                                      : const Icon(Icons.book, size: 40),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: theme.bodyLarge.override(
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),

                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _sharing ? null : _handleShare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _sharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.share, color: Colors.white),
                        label: Text(
                          isBn ? 'সাপ্তাহিক রিপোর্ট শেয়ার করুন 📲' : 'Share Weekly Card 📲',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
