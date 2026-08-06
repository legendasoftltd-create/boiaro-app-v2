import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/backend/api_requests/api_calls.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/custom_code/actions/index.dart' as actions;

class QuizPlayPageWidget extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizPlayPageWidget({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizPlayPageWidget> createState() => _QuizPlayPageWidgetState();
}

class _QuizPlayPageWidgetState extends State<QuizPlayPageWidget> {
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;

  List<dynamic> _questions = [];
  Map<int, int> _userAnswers = {}; // questionIndex -> chosenOptionIndex
  Map<String, dynamic>? _submitResult;
  List<int> _correctIndexes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizDetails();
  }

  Future<void> _fetchQuizDetails() async {
    setState(() => _loading = true);
    try {
      final token = FFAppState().token;
      final res = await EbookGroup.getQuizDetailsCall.call(
        quizId: widget.quizId,
        token: token,
      );
      if (res.statusCode == 200 && res.jsonBody is Map<String, dynamic>) {
        final qList = res.jsonBody['questions'];
        if (qList is List) {
          setState(() {
            _questions = qList;
          });
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submitQuiz() async {
    if (_submitting || _submitted) return;
    if (_userAnswers.length < _questions.length) {
      await actions.showCustomToastBottom('অনুগ্রহ করে সকল প্রশ্নের উত্তর দিন');
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = FFAppState().token;
      final answersList = List.generate(
        _questions.length,
        (index) => _userAnswers[index] ?? 0,
      );

      final res = await EbookGroup.submitQuizCall.call(
        quizId: widget.quizId,
        answers: answersList,
        token: token,
      );
      final body = res.jsonBody;

      if (res.statusCode == 200 && body is Map<String, dynamic>) {
        if (body['success'] == true) {
          final corr = body['correctIndexes'];
          List<int> correctList = [];
          if (corr is List) {
            correctList = corr.map((e) => (e is num) ? e.toInt() : 0).toList();
          }

          setState(() {
            _submitted = true;
            _submitResult = body;
            _correctIndexes = correctList;
          });

          final score = body['score'] ?? 0;
          final total = body['total'] ?? _questions.length;
          final reward = body['reward'] ?? 0;
          final passed = body['passed'] == true;

          await actions.showCustomToastBottom(
            passed
                ? '🎉 অভিনন্দন! আপনি পাস করেছেন ($score/$total)। +$reward কয়েন বোনাস!'
                : 'ফেইল করেছেন ($score/$total)। আবার চেষ্টা করার জন্য শুভকামনা!',
          );
        } else {
          final reason = body['reason'];
          if (reason == 'already_attempted') {
            await actions.showCustomToastBottom('আপনি এই কুইজে ইতিমধ্যেই অংশ নিয়েছেন');
          } else {
            await actions.showCustomToastBottom('কুইজ জমা দিতে সমস্যা হয়েছে');
          }
        }
      } else {
        await actions.showCustomToastBottom('কুইজ জমা দিতে ব্যর্থ হয়েছে');
      }
    } catch (e) {
      await actions.showCustomToastBottom('Error: $e');
    }
    setState(() => _submitting = false);
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
            title: widget.quizTitle,
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_submitted && _submitResult != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _submitResult!['passed'] == true
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _submitResult!['passed'] == true ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _submitResult!['passed'] == true ? '🎉 কুইজ পাস!' : '❌ কুইজ ফেইল',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _submitResult!['passed'] == true ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'স্কোর: ${_submitResult!['score']} / ${_submitResult!['total']}',
                            style: theme.titleMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_submitResult!['reward'] != null && (_submitResult!['reward'] as num) > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '+${_submitResult!['reward']} কয়েন যোগ করা হয়েছে!',
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],

                  // Questions List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, qIndex) {
                      final q = _questions[qIndex];
                      final qText = q['question']?.toString() ?? '';
                      final options = (q['options'] is List) ? (q['options'] as List) : [];
                      final selectedOption = _userAnswers[qIndex];

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.alternate),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'প্রশ্ন ${qIndex + 1}: $qText',
                              style: theme.titleMedium.override(
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Options List
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: options.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, optIndex) {
                                final optText = options[optIndex]?.toString() ?? '';
                                final isSelected = selectedOption == optIndex;

                                Color borderColor = theme.alternate;
                                Color bgColor = theme.primaryBackground;

                                if (_submitted && _correctIndexes.length > qIndex) {
                                  final correctOptIndex = _correctIndexes[qIndex];
                                  if (optIndex == correctOptIndex) {
                                    borderColor = Colors.green;
                                    bgColor = Colors.green.withOpacity(0.15);
                                  } else if (isSelected && isSelected != (optIndex == correctOptIndex)) {
                                    borderColor = Colors.red;
                                    bgColor = Colors.red.withOpacity(0.15);
                                  }
                                } else if (isSelected) {
                                  borderColor = theme.primary;
                                  bgColor = theme.primary.withOpacity(0.1);
                                }

                                return InkWell(
                                  onTap: _submitted
                                      ? null
                                      : () {
                                          setState(() {
                                            _userAnswers[qIndex] = optIndex;
                                          });
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: isSelected ? theme.primary : theme.secondaryText,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            optText,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: theme.primaryText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  if (!_submitted)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isBn ? 'কুইজ উত্তর জমা দিন 📩' : 'Submit Quiz 📩',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
