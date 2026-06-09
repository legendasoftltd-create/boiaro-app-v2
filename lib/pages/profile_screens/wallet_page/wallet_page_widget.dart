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
      },
      onAdFailed: () async {
        await actions.showCustomToastBottom('Failed to show ad. Please try again.');
      },
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
                title: 'Wallet',
                backIcon: false,
                addIcon: false,
                onTapAdd: () async {},
              ),
              Expanded(
                child: FutureBuilder<ApiCallResponse>(
                  future: EbookGroup.walletApiCall.call(
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
                    final balance = EbookGroup.walletApiCall.balance(walletResp.jsonBody) ?? 0;
                    final totalEarned =
                        EbookGroup.walletApiCall.totalEarned(walletResp.jsonBody) ?? 0;
                    final totalSpent =
                        EbookGroup.walletApiCall.totalSpent(walletResp.jsonBody) ?? 0;
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
                        return RefreshIndicator(
                          color: FlutterFlowTheme.of(context).primary,
                          onRefresh: () async {
                            if (mounted) safeSetState(() {});
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                                    child: InkWell(
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
                                            Icon(Icons.play_circle_fill_rounded, color: Colors.orangeAccent, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Watch Ad',
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
                                ],
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
