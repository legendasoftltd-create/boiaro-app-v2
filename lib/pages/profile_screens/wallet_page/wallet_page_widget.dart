import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                            safeSetState(() {});
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 12,
                                      color: FlutterFlowTheme.of(context).shadowColor,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Coins: $balance',
                                      style: FlutterFlowTheme.of(context).titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Total earned: $totalEarned'),
                                    Text('Total spent: $totalSpent'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _claimDaily,
                                      child: const Text('Claim Daily'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _claimAd,
                                      child: const Text('Claim Ad Reward'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Transactions',
                                style: FlutterFlowTheme.of(context).titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (tx.isEmpty)
                                Text(
                                  'No transactions yet',
                                  style: FlutterFlowTheme.of(context).bodyMedium,
                                ),
                              ...tx.map((row) {
                                final amount = getJsonField(row, r'''$.amount''').toString();
                                final desc = getJsonField(row, r'''$.description''').toString();
                                final createdAt = getJsonField(row, r'''$.created_at''').toString();
                                final positive = (int.tryParse(amount) ?? 0) >= 0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        positive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                        color: positive ? Colors.green : Colors.redAccent,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(desc.isEmpty ? 'Wallet transaction' : desc),
                                            Text(
                                              createdAt.split('T').first,
                                              style: FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .override(fontFamily: 'SF Pro Display'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        amount,
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'SF Pro Display',
                                              color: positive ? Colors.green : Colors.redAccent,
                                              fontWeight: FontWeight.w700,
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
