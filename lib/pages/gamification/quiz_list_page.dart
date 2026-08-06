import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'quiz_play_page.dart';

class QuizListPageWidget extends StatefulWidget {
  const QuizListPageWidget({super.key});

  @override
  State<QuizListPageWidget> createState() => _QuizListPageWidgetState();
}

class _QuizListPageWidgetState extends State<QuizListPageWidget> {
  bool _loading = true;
  List<dynamic> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getQuizzesCall.call(token: token);
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        final list = res.jsonBody['quizzes'];
        if (list is List) {
          setState(() {
            _quizzes = list;
          });
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
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
            title: isBn ? 'কুইজ এবং ট্রাইভিয়া' : 'Quizzes & Trivia',
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
              onRefresh: _fetchQuizzes,
              child: _quizzes.isEmpty
                  ? Center(
                      child: Text(
                        isBn ? 'বর্তমানে কোনো কুইজ উপলব্ধ নেই' : 'No quizzes available right now',
                        style: TextStyle(color: theme.secondaryText),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _quizzes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        final id = quiz['id']?.toString() ?? '';
                        final title = quiz['title']?.toString() ?? 'Quiz';
                        final description = quiz['description']?.toString() ?? '';
                        final reward = quiz['coin_reward'] ?? 0;
                        final passPercentage = quiz['pass_percentage'] ?? 50;
                        final attempt = quiz['attempt'];

                        final isAttempted = attempt != null && attempt is Map;
                        final isPassed = isAttempted && attempt['passed'] == true;
                        final score = isAttempted ? (attempt['score'] ?? 0) : 0;
                        final total = isAttempted ? (attempt['total'] ?? 0) : 0;

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAttempted
                                  ? (isPassed ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5))
                                  : theme.alternate,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: theme.titleMedium.override(
                                        fontFamily: 'SF Pro Display',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+$reward Coins',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: TextStyle(color: theme.secondaryText, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'পাস মার্ক: $passPercentage%',
                                    style: TextStyle(color: theme.secondaryText, fontSize: 12),
                                  ),
                                  if (isAttempted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPassed ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isPassed ? 'পাস ($score/$total)' : 'ফেইল ($score/$total)',
                                        style: TextStyle(
                                          color: isPassed ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => QuizPlayPageWidget(quizId: id, quizTitle: title),
                                          ),
                                        );
                                        _fetchQuizzes();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      ),
                                      child: Text(
                                        isBn ? 'অংশগ্রহণ করুন 🧠' : 'Play Quiz 🧠',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
