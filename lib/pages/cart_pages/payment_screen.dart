import 'dart:developer';
import 'package:a_i_ebook_app/pages/cart_pages/make_payment.dart';
import 'package:a_i_ebook_app/pages/components/custom_center_appbar/custom_center_appbar_widget.dart';
import 'package:a_i_ebook_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:a_i_ebook_app/index.dart';
import 'package:a_i_ebook_app/flutter_flow/nav/nav.dart';
import 'package:a_i_ebook_app/flutter_flow/internationalization.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  /// BoiAro v2 order UUID (replaces legacy SSL `tran_id` for verification).
  final String? orderId;
  final List<String> bookIds;
  final List<String> purchasedFormats;
  final CheckoutController checkoutController;
  final bool isChapterUnlock;

  const PaymentWebView({
    super.key,
    required this.url,
    required this.orderId,
    required this.bookIds,
    required this.purchasedFormats,
    required this.checkoutController,
    this.isChapterUnlock = false,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = false;
  bool isPaymentSuccess = false; // ✅ track payment success
  String _currentUrl = '';

  String get _postSuccessActionLabel {
    final formats =
        widget.purchasedFormats.map((e) => e.toLowerCase().trim()).toSet();
    if (formats.contains('hardcopy') ||
        formats.contains('hard') ||
        formats.contains('print')) {
      return FFLocalizations.of(context).getVariableText(enText: 'View Orders', bnText: 'অর্ডার দেখুন');
    }
    if (formats.contains('audiobook') || formats.contains('audio')) {
      return FFLocalizations.of(context).getVariableText(enText: 'Start Listening', bnText: 'শোনা শুরু করুন');
    }
    return FFLocalizations.of(context).getVariableText(enText: 'Start Reading', bnText: 'পড়া শুরু করুন');
  }

  bool _isPaymentCallbackUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    
    if (url.startsWith('myapp://payment/')) {
      return true;
    }
    
    final status = uri.queryParameters['status']?.toLowerCase();
    final validStatus = <String>{'success', 'failed', 'cancelled'};
    final isV2Callback =
        path.contains('/payment/callback') && validStatus.contains(status);
    final isCheckoutRedirect = path.contains('/checkout/success') ||
        path.contains('/checkout/fail') ||
        path.contains('/checkout/cancel');
        
    final isSslcommerzRedirect = path.contains('/payments/sslcommerz/success') ||
        path.contains('/payments/sslcommerz/fail') ||
        path.contains('/payments/sslcommerz/cancel');

    final redirectParam = uri.queryParameters['redirect']?.toLowerCase() ?? '';
    final hasPaymentRedirect = redirectParam.startsWith('myapp://payment/');

    return isV2Callback || isCheckoutRedirect || isSslcommerzRedirect || hasPaymentRedirect;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 🚫 Prevent back navigation when payment successful
      onWillPop: () async {
        if (isPaymentSuccess) return false;
        
        // First try to go back in webview
        if (webViewController != null) {
          final canGoBack = await webViewController!.canGoBack();
          if (canGoBack) {
            webViewController!.goBack();
            return false; // Prevent screen from popping, webview handled it
          }
        }
        
        // If webview can't go back, allow screen to pop
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(116.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomCenterAppbarWidget(
                  title: FFLocalizations.of(context).getVariableText(enText: 'Payment', bnText: 'পেমেন্ট'),
                  backIcon: false,
                  addIcon: false,
                  onTapAdd: () async {},
                  onBackPressed: () async {
                    if (webViewController != null) {
                      final canGoBack = await webViewController!.canGoBack();
                      if (canGoBack) {
                        webViewController!.goBack();
                      } else {
                        context.safePop();
                      }
                    }
                  },
                ),
                // Container(
                //   width: double.infinity,
                //   padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                //   color: Theme.of(context).scaffoldBackgroundColor,
                //   child: Text(
                //     _currentUrl.isEmpty ? widget.url : _currentUrl,
                //     maxLines: 2,
                //     overflow: TextOverflow.ellipsis,
                //     style: Theme.of(context).textTheme.bodySmall,
                //   ),
                // ),
              ],
            ),
          ),
          body: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  setState(() {
                    _currentUrl = widget.url;
                  });
                },
                  
                shouldOverrideUrlLoading: (controller, action) async {
                  final uri = action.request.url;
                  if (uri != null) {
                    final url = uri.toString();
                    log('Intercepted URL: $url');

                    if (_isPaymentCallbackUrl(url)) {
                      setState(() => isLoading = true);
                      _handleUrlChange(url);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStart: (controller, uri) async{
                  final url = uri?.toString() ?? '';
                  if (url.isNotEmpty) {
                    setState(() {
                      _currentUrl = url;
                    });
                  }
                  if (_isPaymentCallbackUrl(url)) {
                    await controller.stopLoading();
                    _handleUrlChange(url.toString());
                  }
                },
                onLoadStop: (controller, uri) async {
                  final url = uri?.toString() ?? '';
                  if (url.isNotEmpty) {
                    setState(() {
                      _currentUrl = url;
                    });
                  }
                },
                onProgressChanged: (controller, progressValue) {
                  setState(() {
                    progress = progressValue / 100;
                  });
                },
              ),
                  
              // 🔄 Progress bar
              if (progress < 1.0)
                LinearProgressIndicator(value: progress),
                  
              // 🕑 Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUrlChange(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();
    final orderId = uri.queryParameters['order_id'] ??
        uri.queryParameters['tran_id'] ??
        widget.orderId;
    final status = uri.queryParameters['status']?.toLowerCase();

    final redirectParam = uri.queryParameters['redirect']?.toLowerCase() ?? '';

    final isSuccess = path.contains('/checkout/success') ||
        path.contains('/payments/sslcommerz/success') ||
        url.startsWith('myapp://payment/success') ||
        (redirectParam.contains('payment/success') && !path.contains('cancel') && !path.contains('fail')) ||
        status == 'success';

    final isCancel = path.contains('/checkout/cancel') ||
        path.contains('/payments/sslcommerz/cancel') ||
        url.startsWith('myapp://payment/cancelled') ||
        status == 'cancelled';

    final isFail = !isCancel && (path.contains('/checkout/fail') ||
        path.contains('/payments/sslcommerz/fail') ||
        url.startsWith('myapp://payment/failed') ||
        redirectParam.contains('payment/failed') ||
        status == 'failed');

    // ✅ Success
    if (isSuccess) {
      if (orderId != null && orderId.isNotEmpty) {
        widget.checkoutController.verifyPayment(orderId: orderId);
      }
      setState(() {
        isPaymentSuccess = true; // 🚫 disable back
        isLoading = false;
      });
      _showSuccessDialog(FFLocalizations.of(context).getVariableText(enText: "Payment successful", bnText: "পেমেন্ট সফল হয়েছে"));
      log('✅ Success URL: $url');
      return;
    }

    // ❌ Failure
    if (isFail) {
      if (orderId != null && orderId.isNotEmpty) {
        widget.checkoutController.handlePaymentFailure(
          orderId: orderId,
          bookIds: widget.bookIds,
        );
      }
      setState(() => isLoading = false);
      _showErrorDialog(FFLocalizations.of(context).getVariableText(enText: 'Payment failed', bnText: 'পেমেন্ট ব্যর্থ হয়েছে'));
      return;
    }

    // 🚫 Cancelled
    if (isCancel) {
      if (orderId != null && orderId.isNotEmpty) {
        widget.checkoutController.handlePaymentCancellation(
          orderId: orderId,
          bookIds: widget.bookIds,
        );
      }
      setState(() => isLoading = false);
      _showCancellationDialog(FFLocalizations.of(context).getVariableText(enText: 'Payment cancelled', bnText: 'পেমেন্ট বাতিল হয়েছে'));
      log('❎ Cancel URL: $url');
      return;
    }
  }
void _showSuccessDialog(String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // 🚫 prevent tap outside
    builder: (context) {
      return PopScope(
        canPop: false, // 🚫 prevent back press
        child: OrderPlaceDialogWidget(
          icon: Icons.check_circle_rounded,
          title: FFLocalizations.of(context).getVariableText(enText: "Payment Successful", bnText: "পেমেন্ট সফল হয়েছে"),
          description: message,
          isSuccess: true,
          successButtonText: _postSuccessActionLabel,
          onOkPressed: () {
            Navigator.of(context).pop(); // ✅ close dialog
            if (widget.isChapterUnlock) {
              Navigator.of(context).pop(true);
              return;
            }
            context.read<CartProvider>().clear();
            final formats =
                widget.purchasedFormats.map((e) => e.toLowerCase().trim()).toSet();
            // Pop ALL MaterialPageRoute screens (PaymentWebView, MakeCheckOutScreen,
            // CheckoutPage, etc.) back to GoRouter's root shell first.
            Navigator.of(context).popUntil((route) => route.isFirst);
            if (formats.contains('hardcopy') ||
                formats.contains('hard') ||
                formats.contains('print')) {
              context.pushNamed(OrdersPageWidget.routeName);
              return;
            }
             if (formats.contains('audiobook') || formats.contains('audio')) {
               context.pushNamed(
                 PurchaseHistoryPageWidget.routeName,
                 queryParameters: {'tab': '1', 'chip': '3'},
               );
             } else {
               context.pushNamed(
                 PurchaseHistoryPageWidget.routeName,
                 queryParameters: {'tab': '0', 'chip': '3'},
               );
             }
          },
        ),
      );
    },
  );
}


  void _showErrorDialog(String message) {
    showAnimatedDialog(
      context,
      OrderPlaceDialogWidget(
        icon: Icons.cancel,
        title: FFLocalizations.of(context).getVariableText(enText: "Payment Failed", bnText: "পেমেন্ট ব্যর্থ হয়েছে"),
        description: message,
        isFailed: true,
      ),
      dismissible: false,
      willFlip: true,
    ).then((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }

  void _showCancellationDialog(String message) {
    showAnimatedDialog(
      context,
      OrderPlaceDialogWidget(
        icon: Icons.cancel,
        title: FFLocalizations.of(context).getVariableText(enText: "Payment Cancelled", bnText: "পেমেন্ট বাতিল হয়েছে"),
        description: message,
        isFailed: true,
      ),
      dismissible: false,
      willFlip: true,
    ).then((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }
}
