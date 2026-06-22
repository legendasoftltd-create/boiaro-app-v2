import 'dart:developer';

import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_theme.dart';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_util.dart';
import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

/// Initiates an SSLCommerz subscription payment and hosts the WebView.
/// On success callback it calls [usersubscriptionApiCall] and pops.
class SubscriptionPaymentScreen extends StatefulWidget {
  final dynamic subscriptionJson;

  const SubscriptionPaymentScreen({
    super.key,
    required this.subscriptionJson,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState
    extends State<SubscriptionPaymentScreen> {
  bool _isLoading = true;
  String? _error;
  String? _gatewayUrl;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      final planId =
          getJsonField(widget.subscriptionJson, r'''$._id''')?.toString() ??
              getJsonField(widget.subscriptionJson, r'''$.id''')?.toString() ??
              '';
      final price =
          getJsonField(widget.subscriptionJson, r'''$.price''')?.toString() ??
              '0';

      log('Initiating subscription payment: planId=$planId price=$price');

      final response = await http.post(
        Uri.parse('${FFAppConstants.baseApiUrl}/subscriptions/subscribe'),
        headers: {
          'Authorization': 'Bearer ${FFAppState().token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'plan_id': planId,
          'payment_method': 'sslcommerz',
        }),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      log('Subscription payment initiation (${response.statusCode}): $decoded');

      final gatewayUrl = decoded['gateway_url']?.toString() ??
          decoded['GatewayPageURL']?.toString() ??
          decoded['url']?.toString();
      final success = decoded['success'] == 1 ||
          decoded['success'] == true ||
          decoded['requires_payment'] == true ||
          (gatewayUrl != null && gatewayUrl.isNotEmpty);

      if (success && gatewayUrl != null && gatewayUrl.isNotEmpty) {
        setState(() {
          _gatewayUrl = gatewayUrl;
          _transactionId = decoded['transaction_id']?.toString() ??
              decoded['tran_id']?.toString() ??
              decoded['session_key']?.toString() ??
              '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              'পেমেন্ট শুরু করতে ব্যর্থ হয়েছে';
          _isLoading = false;
        });
      }
    } catch (e, st) {
      log('Subscription payment initiation error: $e', stackTrace: st);
      setState(() {
        _error = 'সংযোগ সমস্যা হয়েছে। আবার চেষ্টা করুন।';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              CustomCenterAppbarWidget(
                title: 'পেমেন্ট',
                backIcon: true,
                addIcon: false,
                onTapAdd: () async {},
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('পেমেন্ট প্রস্তুত হচ্ছে...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              CustomCenterAppbarWidget(
                title: 'পেমেন্ট',
                backIcon: true,
                addIcon: false,
                onTapAdd: () async {},
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 56,
                          color: FlutterFlowTheme.of(context).error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _initiatePayment();
                        },
                        child: const Text('আবার চেষ্টা করুন'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SubscriptionPaymentWebView(
      url: _gatewayUrl!,
      transactionId: _transactionId ?? '',
      subscriptionJson: widget.subscriptionJson,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionPaymentWebView extends StatefulWidget {
  final String url;
  final String transactionId;
  final dynamic subscriptionJson;

  const _SubscriptionPaymentWebView({
    required this.url,
    required this.transactionId,
    required this.subscriptionJson,
  });

  @override
  State<_SubscriptionPaymentWebView> createState() =>
      _SubscriptionPaymentWebViewState();
}

class _SubscriptionPaymentWebViewState
    extends State<_SubscriptionPaymentWebView> {
  InAppWebViewController? _webController;
  double _progress = 0;
  bool _isProcessing = false;
  bool _paymentDone = false;

  bool _isCallbackUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    
    if (url.startsWith('myapp://payment/')) {
      return true;
    }
    
    final status = uri.queryParameters['status']?.toLowerCase();
    const valid = {'success', 'failed', 'cancelled'};
    
    final isCallback = (path.contains('/payment/callback') && valid.contains(status)) ||
        path.contains('/subscription/success') ||
        path.contains('/subscription/fail') ||
        path.contains('/subscription/cancel') ||
        path.contains('/checkout/success') ||
        path.contains('/checkout/fail') ||
        path.contains('/checkout/cancel');

    final isSslcommerzRedirect = path.contains('/payments/sslcommerz/success') ||
        path.contains('/payments/sslcommerz/fail') ||
        path.contains('/payments/sslcommerz/cancel');

    final redirectParam = uri.queryParameters['redirect']?.toLowerCase() ?? '';
    final hasPaymentRedirect = redirectParam.startsWith('myapp://payment/');

    return isCallback || isSslcommerzRedirect || hasPaymentRedirect;
  }

  Future<void> _handleCallback(String url) async {
    if (_paymentDone) return;
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status']?.toLowerCase();
    final path = uri.path.toLowerCase();
    final redirectParam = uri.queryParameters['redirect']?.toLowerCase() ?? '';
    
    final isSuccess = status == 'success' ||
        path.contains('/success') ||
        redirectParam.contains('payment/success');

    if (!isSuccess) {
      final isCancelled = status == 'cancelled' ||
          path.contains('/cancel') ||
          redirectParam.contains('payment/failed') || // Cancel also redirects to payment/failed on some endpoints
          redirectParam.contains('cancel');
          
      setState(() => _isProcessing = false);
      _showResult(
        success: false,
        message: isCancelled
            ? 'পেমেন্ট বাতিল করা হয়েছে।'
            : 'পেমেন্ট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
      );
      return;
    }

    setState(() => _isProcessing = true);
    _paymentDone = true;

    try {
      final planId =
          getJsonField(widget.subscriptionJson, r'''$._id''')?.toString() ??
              getJsonField(widget.subscriptionJson, r'''$.id''')?.toString() ??
              '';
      final price =
          getJsonField(widget.subscriptionJson, r'''$.price''')?.toString() ??
              '0';
      final txnId = uri.queryParameters['tran_id'] ??
          uri.queryParameters['transaction_id'] ??
          widget.transactionId;

      await EbookGroup.usersubscriptionApiCall.call(
        userId: FFAppState().userId,
        subscriptionplanId: FFAppState().subscriptionId.isNotEmpty
            ? FFAppState().subscriptionId
            : planId,
        paymentmode: 'sslcommerz',
        transactionId: txnId,
        paymentstatus: 'success',
        paymentdate: dateTimeFormat('dd-MM-yyyy', getCurrentTimestamp),
        price: price,
        token: FFAppState().token,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _showResult(
          success: true,
          message: 'সাবস্ক্রিপশন সফলভাবে সক্রিয় হয়েছে!',
        );
      }
    } catch (e) {
      log('Subscription confirmation error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showResult(
          success: false,
          message: 'পেমেন্ট সফল হয়েছে কিন্তু নিশ্চিতকরণে সমস্যা হয়েছে। সাপোর্টে যোগাযোগ করুন।',
        );
      }
    }
  }

  void _showResult({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(success ? 'সফল!' : 'ব্যর্থ'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (success) {
                  context.safePop();
                  context.safePop();
                } else {
                  context.safePop();
                }
              },
              child: Text(success ? 'ঠিক আছে' : 'বন্ধ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _paymentDone) return;
        if (_webController != null) {
          final canGoBack = await _webController!.canGoBack();
          if (canGoBack) {
            _webController!.goBack();
            return;
          }
        }
        if (mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              CustomCenterAppbarWidget(
                title: 'SSLCommerz পেমেন্ট',
                backIcon: !_paymentDone,
                addIcon: false,
                onTapAdd: () async {},
                onBackPressed: () async {
                  if (_webController != null) {
                    final canGoBack = await _webController!.canGoBack();
                    if (canGoBack) {
                      _webController!.goBack();
                    } else {
                      context.safePop();
                    }
                  }
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      initialUrlRequest:
                          URLRequest(url: WebUri(widget.url)),
                      onWebViewCreated: (c) => _webController = c,
                      onProgressChanged: (_, p) =>
                          setState(() => _progress = p / 100),
                      shouldOverrideUrlLoading:
                          (controller, action) async {
                        final url =
                            action.request.url?.toString() ?? '';
                        if (_isCallbackUrl(url)) {
                          await controller.stopLoading();
                          _handleCallback(url);
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStart: (_, uri) async {
                        final url = uri?.toString() ?? '';
                        if (_isCallbackUrl(url)) {
                          _handleCallback(url);
                        }
                      },
                    ),
                    if (_progress < 1.0)
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.transparent,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: Colors.white),
                              SizedBox(height: 16),
                              Text('সাবস্ক্রিপশন নিশ্চিত হচ্ছে...',
                                  style:
                                      TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
